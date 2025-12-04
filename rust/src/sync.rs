//! Data synchronization with LWW (Last-Write-Wins) CRDT
//! 
//! This module handles data synchronization across nodes using signed operations.
//! Matches the cyberfly-rust-node sync protocol exactly.
//! 
//! Signature formats supported:
//! 1. Full format: op_id:timestamp:db_name:key:value (for sync operations)
//! 2. Short format: db_name:key:value (for client submissions)

use std::collections::{HashMap, HashSet};
use std::sync::Arc;

use anyhow::{anyhow, Result};
use serde::{Deserialize, Serialize};
use tokio::sync::RwLock;
use tracing::{debug, error, info, warn};

use crate::crypto;
use crate::storage::Storage;

/// Maximum operations per sync response (to avoid oversized payloads)
const MAX_OPS_PER_RESPONSE: usize = 128;

/// Sync message types for gossip
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type")]
pub enum SyncMessage {
    /// Request all data from a peer (bootstrap sync)
    SyncRequest {
        requester: String,            // Node ID as string
        since_timestamp: Option<i64>, // Unix timestamp ms, None = full sync
    },
    /// Response with data operations
    SyncResponse {
        requester: String,
        operations: Vec<SignedOperation>,
        has_more: bool,
        continuation_token: Option<String>,
    },
    /// New operation to be replicated
    Operation {
        operation: SignedOperation,
    },
}

/// A signed data operation that can be verified and merged
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SignedOperation {
    /// Unique operation ID (UUID)
    pub op_id: String,
    /// Unix timestamp (milliseconds)
    pub timestamp: i64,
    /// Database name (format: <name>-<public_key_hex>)
    pub db_name: String,
    /// The data key
    pub key: String,
    /// The data value (JSON string or raw value)
    pub value: String,
    /// Store type: String, Hash, List, Set, SortedSet, JSON, Stream
    pub store_type: String,
    /// Optional field for Hash store type
    pub field: Option<String>,
    /// Optional score for SortedSet
    pub score: Option<f64>,
    /// Optional JSON path
    pub json_path: Option<String>,
    /// Optional stream fields (JSON) - for Stream store type
    pub stream_fields: Option<String>,
    /// Optional timestamp for TimeSeries
    pub ts_timestamp: Option<String>,
    /// Optional longitude for Geo
    pub longitude: Option<f64>,
    /// Optional latitude for Geo
    pub latitude: Option<f64>,
    /// Public key of the signer (hex)
    pub public_key: String,
    /// Ed25519 signature (hex)
    pub signature: String,
}

impl SignedOperation {
    /// Verify the signature of this operation with enhanced security checks
    /// Supports two formats:
    /// 1. Full format: op_id:timestamp:db_name:key:value (for sync operations)
    /// 2. Short format: db_name:key:value (for GraphQL/client submissions)
    /// Matches cyberfly-rust-node's verify method
    pub fn verify(&self) -> Result<bool> {
        // Enhanced database name verification (if public key is provided)
        if !self.public_key.is_empty() {
            if let Err(e) = crypto::verify_db_name_secure(&self.db_name, &self.public_key) {
                debug!(op_id = %self.op_id, "Database name verification failed: {}", e);
                // Don't fail immediately - some legacy operations may not follow this format
            }
        }
        
        // Validate timestamp (allow some tolerance for network delays)
        if let Err(e) = crypto::validate_timestamp(self.timestamp, Some(crypto::MAX_TIMESTAMP_TOLERANCE)) {
            debug!(op_id = %self.op_id, "Timestamp validation warning: {}", e);
            // Don't fail - just log for now, as some synced data may be older
        }

        // Try full format first (op_id:timestamp:db_name:key:value)
        let full_message = format!(
            "{}:{}:{}:{}:{}",
            self.op_id, self.timestamp, self.db_name, self.key, self.value
        );
        
        if crypto::verify_signature(&self.public_key, full_message.as_bytes(), &self.signature)
            .unwrap_or(false)
        {
            debug!(op_id = %self.op_id, "Signature verified with full format");
            return Ok(true);
        }

        // Try short format (db_name:key:value) - used by GraphQL client
        let short_message = format!("{}:{}:{}", self.db_name, self.key, self.value);
        
        match crypto::verify_signature(&self.public_key, short_message.as_bytes(), &self.signature) {
            Ok(true) => {
                debug!(op_id = %self.op_id, "Signature verified with short format");
                Ok(true)
            }
            Ok(false) => {
                warn!(op_id = %self.op_id, "Signature verification failed for both formats");
                Ok(false)
            }
            Err(e) => {
                warn!(op_id = %self.op_id, "Signature verification error: {}", e);
                Err(e)
            }
        }
    }
    
    /// Verify with full format only (for operations we created locally)
    pub fn verify_full(&self) -> Result<bool> {
        let message = format!(
            "{}:{}:{}:{}:{}",
            self.op_id, self.timestamp, self.db_name, self.key, self.value
        );
        crypto::verify_signature(&self.public_key, message.as_bytes(), &self.signature)
    }

    /// Get a comparable key for CRDT ordering (db_name:key:field)
    pub fn crdt_key(&self) -> String {
        if let Some(ref field) = self.field {
            format!("{}:{}:{}", self.db_name, self.key, field)
        } else {
            format!("{}:{}", self.db_name, self.key)
        }
    }
    
    /// Create a new signed operation
    pub fn new(
        db_name: String,
        key: String,
        value: String,
        store_type: String,
        public_key: String,
        signature: String,
    ) -> Self {
        Self {
            op_id: uuid::Uuid::new_v4().to_string(),
            timestamp: chrono::Utc::now().timestamp_millis(),
            db_name,
            key,
            value,
            store_type,
            field: None,
            score: None,
            json_path: None,
            stream_fields: None,
            ts_timestamp: None,
            longitude: None,
            latitude: None,
            public_key,
            signature,
        }
    }
    
    /// Create and sign a new operation (with full format signature)
    pub fn create_and_sign(
        db_name: String,
        key: String,
        value: String,
        store_type: String,
        signing_key: &ed25519_dalek::SigningKey,
    ) -> Self {
        let op_id = uuid::Uuid::new_v4().to_string();
        let timestamp = chrono::Utc::now().timestamp_millis();
        let public_key = crypto::public_key_hex(signing_key);
        
        // Sign with full format
        let message = format!("{}:{}:{}:{}:{}", op_id, timestamp, db_name, key, value);
        let signature = crypto::sign_message(signing_key, message.as_bytes());
        
        Self {
            op_id,
            timestamp,
            db_name,
            key,
            value,
            store_type,
            field: None,
            score: None,
            json_path: None,
            stream_fields: None,
            ts_timestamp: None,
            longitude: None,
            latitude: None,
            public_key,
            signature,
        }
    }
}

/// CRDT-based sync store that tracks operations and applies LWW (Last-Write-Wins)
pub struct SyncStore {
    /// Map of crdt_key -> (timestamp, operation)
    /// Last-Write-Wins: Keep only the operation with the latest timestamp
    operations: Arc<RwLock<HashMap<String, (i64, SignedOperation)>>>,
    /// Set of operation IDs that have been applied to storage
    applied_ops: Arc<RwLock<HashSet<String>>>,
    /// Local storage reference
    storage: Arc<Storage>,
}

impl SyncStore {
    pub fn new(storage: Arc<Storage>) -> Self {
        Self {
            operations: Arc::new(RwLock::new(HashMap::new())),
            applied_ops: Arc::new(RwLock::new(HashSet::new())),
            storage,
        }
    }

    /// Check whether an operation has already been applied to storage
    pub async fn is_applied(&self, op_id: &str) -> bool {
        self.applied_ops.read().await.contains(op_id)
    }

    /// Mark an operation as applied to storage
    pub async fn mark_applied(&self, op_id: &str) {
        self.applied_ops.write().await.insert(op_id.to_string());
    }

    /// Add operation to memory with signature verification
    pub async fn add_operation(&self, op: SignedOperation) -> Result<bool> {
        // Verify signature first
        if !op.verify().unwrap_or(false) {
            warn!(op_id = %op.op_id, "Signature verification failed, rejecting operation");
            return Ok(false);
        }

        let crdt_key = op.crdt_key();
        let mut ops = self.operations.write().await;

        // Check if we already have this operation
        if let Some((existing_ts, existing_op)) = ops.get(&crdt_key) {
            // LWW: Only update if new timestamp is newer
            if op.timestamp < *existing_ts {
                debug!(op_id = %op.op_id, "Rejecting older operation (LWW)");
                return Ok(false);
            }
            // If same timestamp, use op_id as tiebreaker (lexicographic order)
            if op.timestamp == *existing_ts && op.op_id <= existing_op.op_id {
                debug!(op_id = %op.op_id, "Rejecting operation with same timestamp (tiebreaker)");
                return Ok(false);
            }
        }

        info!(
            op_id = %op.op_id,
            crdt_key = %crdt_key,
            timestamp = op.timestamp,
            "Adding operation to SyncStore"
        );

        // Store operation
        ops.insert(crdt_key, (op.timestamp, op));

        Ok(true)
    }

    /// Add operation without signature verification (use when already verified)
    pub async fn add_operation_unverified(&self, op: SignedOperation) -> Result<bool> {
        let crdt_key = op.crdt_key();
        let mut ops = self.operations.write().await;

        if let Some((existing_ts, existing_op)) = ops.get(&crdt_key) {
            if op.timestamp < *existing_ts {
                return Ok(false);
            }
            if op.timestamp == *existing_ts && op.op_id <= existing_op.op_id {
                return Ok(false);
            }
        }

        ops.insert(crdt_key, (op.timestamp, op));
        Ok(true)
    }

    /// Get all operations
    pub async fn get_all_operations(&self) -> Vec<SignedOperation> {
        self.operations
            .read()
            .await
            .values()
            .map(|(_, op)| op.clone())
            .collect()
    }

    /// Get operations since a timestamp
    pub async fn get_operations_since(&self, timestamp: i64) -> Vec<SignedOperation> {
        self.operations
            .read()
            .await
            .values()
            .filter(|(ts, _)| *ts >= timestamp)
            .map(|(_, op)| op.clone())
            .collect()
    }

    /// Get operations count
    pub async fn operation_count(&self) -> usize {
        self.operations.read().await.len()
    }

    /// Merge operations from another node
    pub async fn merge_operations(&self, operations: Vec<SignedOperation>) -> Result<usize> {
        let mut merged_count = 0;

        for op in operations {
            if self.add_operation(op).await? {
                merged_count += 1;
            }
        }

        Ok(merged_count)
    }

    /// Apply a single operation to local storage
    pub async fn apply_to_storage(&self, op: &SignedOperation) -> Result<()> {
        // Avoid re-applying the same operation
        if self.is_applied(&op.op_id).await {
            debug!(op_id = %op.op_id, "Skipping already-applied operation");
            return Ok(());
        }

        let full_key = format!("{}:{}", op.db_name, op.key);

        match op.store_type.to_lowercase().as_str() {
            "string" => {
                self.storage.put(&op.db_name, &op.key, op.value.as_bytes())?;
            }
            "hash" => {
                let field = op.field.as_ref().ok_or_else(|| anyhow!("Field required for Hash type"))?;
                let hash_key = format!("{}:{}", op.key, field);
                self.storage.put(&op.db_name, &hash_key, op.value.as_bytes())?;
            }
            "json" => {
                // Store JSON as-is
                self.storage.put(&op.db_name, &op.key, op.value.as_bytes())?;
            }
            _ => {
                // Default to string storage
                self.storage.put(&op.db_name, &op.key, op.value.as_bytes())?;
            }
        }

        // Mark as applied
        self.mark_applied(&op.op_id).await;
        info!(op_id = %op.op_id, key = %full_key, "Applied operation to storage");
        
        Ok(())
    }

    /// Apply all pending operations to storage
    pub async fn apply_all_to_storage(&self) -> Result<usize> {
        let operations = self.get_all_operations().await;
        let mut applied = 0;

        for op in operations {
            if !self.is_applied(&op.op_id).await {
                if let Err(e) = self.apply_to_storage(&op).await {
                    error!(op_id = %op.op_id, error = %e, "Failed to apply operation");
                } else {
                    applied += 1;
                }
            }
        }

        Ok(applied)
    }
}

/// Sync manager handles data synchronization across nodes
pub struct SyncManager {
    sync_store: Arc<SyncStore>,
    local_node_id: String,
}

impl SyncManager {
    pub fn new(storage: Arc<Storage>, local_node_id: String) -> Self {
        Self {
            sync_store: Arc::new(SyncStore::new(storage)),
            local_node_id,
        }
    }

    /// Get sync store reference
    pub fn sync_store(&self) -> Arc<SyncStore> {
        self.sync_store.clone()
    }

    /// Handle incoming sync message
    pub async fn handle_sync_message(
        &self,
        msg: SyncMessage,
        from_peer: &str,
    ) -> Result<Option<SyncMessage>> {
        match msg {
            SyncMessage::SyncRequest { requester, since_timestamp } => {
                info!(
                    "Received sync request from {} (since: {:?})",
                    requester, since_timestamp
                );

                let mut operations = if let Some(ts) = since_timestamp {
                    self.sync_store.get_operations_since(ts).await
                } else {
                    self.sync_store.get_all_operations().await
                };
                
                // Sort by timestamp, then op_id for determinism
                operations.sort_by(|a, b| {
                    a.timestamp.cmp(&b.timestamp).then(a.op_id.cmp(&b.op_id))
                });

                // Chunk to avoid large payloads
                let total = operations.len();
                let chunk: Vec<SignedOperation> = operations
                    .into_iter()
                    .take(MAX_OPS_PER_RESPONSE)
                    .collect();
                    
                let has_more = total > chunk.len();
                let continuation_token = if has_more {
                    let next_ts = chunk.last().map(|op| op.timestamp).unwrap_or(0);
                    Some(format!("ts:{}", next_ts))
                } else {
                    None
                };

                info!("Sending {} ops (has_more: {}) to {}", chunk.len(), has_more, requester);

                Ok(Some(SyncMessage::SyncResponse {
                    requester,
                    operations: chunk,
                    has_more,
                    continuation_token,
                }))
            }
            
            SyncMessage::SyncResponse { requester, operations, has_more, continuation_token } => {
                // Only process responses intended for this node
                if requester != self.local_node_id {
                    debug!("Ignoring SyncResponse intended for {}", requester);
                    return Ok(None);
                }

                info!(
                    "Received sync response with {} operations from {}",
                    operations.len(), from_peer
                );

                // Merge and apply
                let merged = self.sync_store.merge_operations(operations).await?;
                info!("Merged {} new operations", merged);
                
                let _ = self.sync_store.apply_all_to_storage().await?;

                // If more data is available, request next chunk
                if has_more {
                    if let Some(token) = continuation_token {
                        if let Some(ts_str) = token.strip_prefix("ts:") {
                            if let Ok(ts) = ts_str.parse::<i64>() {
                                return Ok(Some(SyncMessage::SyncRequest {
                                    requester: self.local_node_id.clone(),
                                    since_timestamp: Some(ts),
                                }));
                            }
                        }
                    }
                }

                Ok(None)
            }
            
            SyncMessage::Operation { operation } => {
                info!(
                    "📥 Received operation {} from {} (db: {}, key: {})",
                    operation.op_id, from_peer, operation.db_name, operation.key
                );

                // Add to store (will verify signature)
                match self.sync_store.add_operation(operation.clone()).await {
                    Ok(true) => {
                        info!(op_id = %operation.op_id, "✓ Operation accepted");
                        // Apply to storage
                        if let Err(e) = self.sync_store.apply_to_storage(&operation).await {
                            error!(op_id = %operation.op_id, error = %e, "Failed to apply to storage");
                        }
                    }
                    Ok(false) => {
                        debug!(op_id = %operation.op_id, "⏭️ Operation rejected (duplicate or older)");
                    }
                    Err(e) => {
                        error!(op_id = %operation.op_id, error = %e, "Failed to add operation");
                    }
                }

                Ok(None)
            }
        }
    }

    /// Request full sync from a peer
    pub fn create_sync_request(&self, since_timestamp: Option<i64>) -> SyncMessage {
        SyncMessage::SyncRequest {
            requester: self.local_node_id.clone(),
            since_timestamp,
        }
    }

    /// Create operation message for broadcast
    pub fn create_operation_message(&self, op: SignedOperation) -> SyncMessage {
        SyncMessage::Operation { operation: op }
    }

    /// Get sync statistics
    pub async fn get_stats(&self) -> SyncStats {
        SyncStats {
            total_operations: self.sync_store.operation_count().await,
            local_node_id: self.local_node_id.clone(),
        }
    }
}

impl Clone for SyncManager {
    fn clone(&self) -> Self {
        Self {
            sync_store: self.sync_store.clone(),
            local_node_id: self.local_node_id.clone(),
        }
    }
}

/// Sync statistics
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncStats {
    pub total_operations: usize,
    pub local_node_id: String,
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::tempdir;

    fn create_test_storage() -> Storage {
        let dir = tempdir().unwrap();
        Storage::new(dir.path().to_path_buf()).unwrap()
    }

    #[tokio::test]
    async fn test_sync_store_lww() {
        let storage = create_test_storage();
        let store = SyncStore::new(storage);

        let op1 = SignedOperation {
            op_id: "op1".to_string(),
            timestamp: 1000,
            db_name: "testdb".to_string(),
            key: "key1".to_string(),
            value: "value1".to_string(),
            store_type: "String".to_string(),
            field: None,
            score: None,
            json_path: None,
            public_key: "a".repeat(64),
            signature: "sig1".to_string(),
        };

        let op2 = SignedOperation {
            op_id: "op2".to_string(),
            timestamp: 2000, // Newer
            db_name: "testdb".to_string(),
            key: "key1".to_string(),
            value: "value2".to_string(),
            store_type: "String".to_string(),
            field: None,
            score: None,
            json_path: None,
            public_key: "a".repeat(64),
            signature: "sig2".to_string(),
        };

        // Add older operation first (unverified for test)
        store.add_operation_unverified(op1.clone()).await.unwrap();
        
        // Add newer operation
        store.add_operation_unverified(op2.clone()).await.unwrap();

        let ops = store.get_all_operations().await;
        assert_eq!(ops.len(), 1);
        assert_eq!(ops[0].value, "value2"); // Newer value wins
    }

    #[tokio::test]
    async fn test_sync_message_serialization() {
        let op = SignedOperation {
            op_id: "test-op".to_string(),
            timestamp: 12345,
            db_name: "testdb".to_string(),
            key: "key".to_string(),
            value: "value".to_string(),
            store_type: "String".to_string(),
            field: None,
            score: None,
            json_path: None,
            public_key: "pub".to_string(),
            signature: "sig".to_string(),
        };

        let msg = SyncMessage::Operation { operation: op };
        let json = serde_json::to_string(&msg).unwrap();
        let decoded: SyncMessage = serde_json::from_str(&json).unwrap();

        if let SyncMessage::Operation { operation } = decoded {
            assert_eq!(operation.op_id, "test-op");
        } else {
            panic!("Wrong message type");
        }
    }
}
