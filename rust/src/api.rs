//! Flutter Rust Bridge API
//! 
//! This module exposes Rust functions to Flutter via FFI.

use std::sync::Arc;
use std::io::Write;
use std::collections::VecDeque;
use once_cell::sync::OnceCell;
use parking_lot::RwLock;
use tokio::runtime::Runtime;
use flutter_rust_bridge::frb;
use log::{info, error, warn};

use crate::node::CyberflyNode;
use crate::discovery::DiscoveredPeer;
use crate::crypto;

/// Global node instance
static NODE: OnceCell<Arc<RwLock<Option<Arc<CyberflyNode>>>>> = OnceCell::new();

/// Global tokio runtime
static RUNTIME: OnceCell<Runtime> = OnceCell::new();

/// Global log buffer for Flutter UI - circular buffer of recent logs
const MAX_LOG_ENTRIES: usize = 500;
static LOG_BUFFER: OnceCell<Arc<RwLock<VecDeque<LogEntry>>>> = OnceCell::new();

fn get_log_buffer() -> &'static Arc<RwLock<VecDeque<LogEntry>>> {
    LOG_BUFFER.get_or_init(|| Arc::new(RwLock::new(VecDeque::with_capacity(MAX_LOG_ENTRIES))))
}

/// Add a log entry to the buffer (called from our custom logger)
pub fn add_log_entry(level: &str, message: String) {
    let buffer = get_log_buffer();
    let mut guard = buffer.write();
    if guard.len() >= MAX_LOG_ENTRIES {
        guard.pop_front();
    }
    guard.push_back(LogEntry {
        timestamp: chrono::Utc::now().timestamp_millis(),
        level: level.to_string(),
        message,
    });
}

fn get_runtime() -> &'static Runtime {
    RUNTIME.get_or_init(|| {
        tokio::runtime::Builder::new_multi_thread()
            .enable_all()
            .build()
            .expect("Failed to create runtime")
    })
}

fn get_node_holder() -> &'static Arc<RwLock<Option<Arc<CyberflyNode>>>> {
    NODE.get_or_init(|| Arc::new(RwLock::new(None)))
}

fn get_node() -> Result<Arc<CyberflyNode>, String> {
    let guard = get_node_holder().read();
    guard.clone().ok_or_else(|| "Node not running".to_string())
}

/// Node info returned to Flutter
#[frb(dart_metadata=("freezed"))]
pub struct NodeInfo {
    pub node_id: String,
    pub public_key: String,
    pub is_running: bool,
}

/// Peer info for Flutter
#[frb(dart_metadata=("freezed"))]
pub struct PeerInfoDto {
    pub node_id: String,
    pub public_key: String,
    pub address: Option<String>,
    pub region: Option<String>,
    pub version: Option<String>,
    pub latency_ms: Option<u64>,
    pub is_mobile: bool,
}

impl From<&DiscoveredPeer> for PeerInfoDto {
    fn from(peer: &DiscoveredPeer) -> Self {
        Self {
            node_id: peer.node_id.clone(),
            public_key: peer.public_key.clone(),
            address: peer.address.clone(),
            region: peer.region.clone(),
            version: peer.version.clone(),
            latency_ms: peer.latency_ms,
            is_mobile: peer.capabilities.mobile,
        }
    }
}

/// Node status for Flutter
#[frb(dart_metadata=("freezed"))]
pub struct NodeStatusDto {
    pub is_running: bool,
    pub node_id: Option<String>,
    pub connected_peers: u32,
    pub discovered_peers: u32,
    pub uptime_seconds: u64,
    pub gossip_messages_received: u64,
    pub storage_size_bytes: u64,
    pub total_keys: u64,
    pub sync_operations: u32,
    pub latency_requests_sent: u64,
    pub latency_responses_received: u64,
}

/// Log entry for Flutter console
#[derive(Clone)]
#[frb(dart_metadata=("freezed"))]
pub struct LogEntry {
    pub timestamp: i64,
    pub level: String,
    pub message: String,
}

/// Event types for Flutter
#[frb(dart_metadata=("freezed"))]
pub enum NodeEventDto {
    Started { node_id: String, public_key: String },
    Stopped,
    PeerConnected { peer_id: String },
    PeerDisconnected { peer_id: String },
    PeerDiscovered { peer_id: String, address: Option<String> },
    GossipReceived { topic: String, from: String, content: String },
    SyncReceived { db_name: String, key: String },
    LatencyMeasured { peer_id: String, latency_ms: u64 },
    Error { message: String },
}

/// Keypair for signing
#[frb(dart_metadata=("freezed"))]
pub struct KeyPairDto {
    pub public_key: String,
    pub secret_key: String,
}

/// Initialize logging
#[frb(sync)]
pub fn init_logging() {
    #[cfg(target_os = "android")]
    {
        android_logger::init_once(
            android_logger::Config::default()
                .with_max_level(log::LevelFilter::Info)
                .with_tag("CyberflyRust")
                .format(|buf, record| {
                    // Filter out very verbose iroh internal logs, but keep important ones
                    let target = record.target();
                    if target.starts_with("iroh") && record.level() > log::Level::Warn {
                        return Ok(());
                    }
                    
                    // Also capture to our buffer for Flutter UI
                    let message = format!("{}: {}", target, record.args());
                    add_log_entry(&record.level().to_string(), message.clone());
                    
                    writeln!(buf, "[{}] {}", record.level(), message)
                }),
        );
    }
    
    #[cfg(not(target_os = "android"))]
    {
        let _ = tracing_subscriber::fmt()
            .with_env_filter("warn,cyberfly=info,iroh=error,iroh_gossip=error,iroh_net=error,quinn=error")
            .try_init();
    }
}

/// Start the Cyberfly node
#[frb]
pub async fn start_node(
    data_dir: String,
    wallet_secret_key: Option<String>,
    bootstrap_peers: Vec<String>,
    region: Option<String>,
) -> Result<NodeInfo, String> {
    info!(">>> RUST API: start_node called");
    let runtime = get_runtime();
    info!(">>> RUST API: got runtime, about to spawn");
    
    let result = runtime.spawn(async move {
        info!(">>> RUST API: inside runtime.spawn, calling CyberflyNode::start");
        let result = CyberflyNode::start(data_dir, wallet_secret_key, bootstrap_peers, region).await;
        info!(">>> RUST API: CyberflyNode::start returned: {:?}", result.is_ok());
        result
    }).await;
    
    info!(">>> RUST API: spawn completed, result: {:?}", result.is_ok());
    
    match result {
        Ok(Ok(node)) => {
            let info = NodeInfo {
                node_id: node.node_id().to_string(),
                public_key: node.public_key().to_string(),
                is_running: true,
            };
            *get_node_holder().write() = Some(Arc::new(node));
            Ok(info)
        }
        Ok(Err(e)) => Err(format!("Failed to start node: {}", e)),
        Err(e) => Err(format!("Task error: {}", e)),
    }
}

/// Stop the node
#[frb]
pub async fn stop_node() -> Result<(), String> {
    let node_opt = get_node_holder().write().take();
    if let Some(node) = node_opt {
        let runtime = get_runtime();
        runtime.spawn(async move {
            if let Ok(inner_node) = Arc::try_unwrap(node) {
                let _ = inner_node.stop().await;
            }
        }).await.map_err(|e| format!("Task error: {}", e))?;
    }
    Ok(())
}

/// Check if node is running
#[frb(sync)]
pub fn is_node_running() -> bool {
    get_node_holder().read().is_some()
}

/// Get node status - synchronous version using shared state
#[frb(sync)]
pub fn get_node_status() -> Result<NodeStatusDto, String> {
    let node = get_node()?;
    let status = node.get_status_sync();
    
    Ok(NodeStatusDto {
        is_running: status.is_running,
        node_id: status.node_id,
        connected_peers: status.connected_peers as u32,
        discovered_peers: status.discovered_peers as u32,
        uptime_seconds: status.uptime_seconds,
        gossip_messages_received: status.gossip_messages_received,
        storage_size_bytes: status.storage_size_bytes,
        total_keys: status.total_keys,
        sync_operations: status.sync_operations as u32,
        latency_requests_sent: status.latency_requests_sent,
        latency_responses_received: status.latency_responses_received,
    })
}

/// Get node info
#[frb(sync)]
pub fn get_node_info() -> Option<NodeInfo> {
    let guard = get_node_holder().read();
    guard.as_ref().map(|node| NodeInfo {
        node_id: node.node_id().to_string(),
        public_key: node.public_key().to_string(),
        is_running: true,
    })
}

/// Get discovered peers - synchronous version using shared state
#[frb(sync)]
pub fn get_peers() -> Result<Vec<PeerInfoDto>, String> {
    let node = get_node()?;
    let peers = node.get_peers_sync();
    
    Ok(peers.iter().map(PeerInfoDto::from).collect())
}

/// Send gossip message
#[frb]
pub async fn send_gossip(topic: String, message: String) -> Result<(), String> {
    let node = get_node()?;
    
    node.send_gossip(topic, message).await.map_err(|e| e.to_string())
}

/// Send latency request to measure peer latency
#[frb]
pub async fn send_latency_request(peer_id: String) -> Result<(), String> {
    let node = get_node()?;
    
    // This sends the request, actual latency comes via event
    let _ = node.send_latency_request(peer_id).await;
    Ok(())
}

/// Store data in local database with signature for sync
#[frb]
pub async fn store_data(
    db_name: String,
    key: String,
    value: Vec<u8>,
    public_key: String,
    signature: String,
) -> Result<(), String> {
    let node = get_node()?;
    
    node.store_data(db_name, key, value, public_key, signature)
        .await
        .map_err(|e| e.to_string())
}

/// Store data without signature (local only, not synced)
#[frb]
pub async fn store_data_local(db_name: String, key: String, value: Vec<u8>) -> Result<(), String> {
    let node = get_node()?;
    
    // Use empty signature for local-only storage
    node.store_data(db_name, key, value, String::new(), String::new())
        .await
        .map_err(|e| e.to_string())
}

/// Get data from local database
#[frb]
pub async fn get_data(db_name: String, key: String) -> Result<Option<Vec<u8>>, String> {
    let node = get_node()?;
    
    node.get_data(db_name, key).await.map_err(|e| e.to_string())
}

/// Request sync from peers
#[frb]
pub async fn request_sync(since_timestamp: Option<i64>) -> Result<(), String> {
    let node = get_node()?;
    
    node.request_sync(since_timestamp).await.map_err(|e| e.to_string())
}

/// Sign a message using Ed25519
#[frb(sync)]
pub fn sign_message_with_key(secret_key_hex: String, message: String) -> Result<String, String> {
    let secret_bytes = hex::decode(&secret_key_hex)
        .map_err(|e| format!("Invalid secret key hex: {}", e))?;
    
    let secret_array: [u8; 32] = secret_bytes
        .try_into()
        .map_err(|_| "Invalid secret key length (expected 32 bytes)")?;
    
    let signing_key = ed25519_dalek::SigningKey::from_bytes(&secret_array);
    let signature = crypto::sign_message(&signing_key, message.as_bytes());
    
    Ok(signature)
}

/// Verify an Ed25519 signature
#[frb(sync)]
pub fn verify_message_signature(
    public_key_hex: String,
    message: String,
    signature_hex: String,
) -> Result<bool, String> {
    crypto::verify_signature(&public_key_hex, message.as_bytes(), &signature_hex)
        .map_err(|e| e.to_string())
}

/// Generate a new Ed25519 keypair
#[frb(sync)]
pub fn generate_keypair() -> KeyPairDto {
    let (signing_key, public_key) = crypto::generate_keypair();
    KeyPairDto {
        public_key,
        secret_key: hex::encode(signing_key.to_bytes()),
    }
}

/// Generate database name from name and public key
/// Format: <name>-<public_key_hex> (matching cyberfly-rust-node)
#[frb(sync)]
pub fn generate_db_name(name: String, public_key_hex: String) -> String {
    crypto::generate_db_name(&name, &public_key_hex)
}

/// Verify that the database name matches the public key
#[frb(sync)]
pub fn verify_db_name(db_name: String, public_key_hex: String) -> Result<bool, String> {
    crypto::verify_db_name_secure(&db_name, &public_key_hex)
        .map(|_| true)
        .map_err(|e| e.to_string())
}

/// Extract name part from database name (removes public key suffix)
#[frb(sync)]
pub fn extract_name_from_db(db_name: String) -> Option<String> {
    crypto::extract_name_from_db(&db_name)
}

/// Validate timestamp (check if within acceptable range)
#[frb(sync)]
pub fn validate_timestamp(timestamp: i64) -> Result<bool, String> {
    crypto::validate_timestamp(timestamp, Some(crypto::MAX_TIMESTAMP_TOLERANCE))
        .map(|_| true)
        .map_err(|e| e.to_string())
}

/// Greet function for testing
#[frb(sync)]
pub fn greet(name: String) -> String {
    format!("Hello, {}! From Cyberfly Rust.", name)
}

/// Generate libp2p PeerId from secret key (for Kadena blockchain registration)
/// This matches the desktop cyberfly-rust-node implementation for backward compatibility
#[frb(sync)]
pub fn generate_peer_id_from_secret_key(secret_key_hex: String) -> Result<String, String> {
    // Decode the hex-encoded secret key
    let secret_bytes = hex::decode(&secret_key_hex)
        .map_err(|e| format!("Failed to decode secret key: {}", e))?;
    
    if secret_bytes.len() != 32 {
        return Err(format!("Invalid secret key length: expected 32 bytes, got {}", secret_bytes.len()));
    }

    // Create ed25519 secret key and derive keypair
    let secret = libp2p_identity::ed25519::SecretKey::try_from_bytes(secret_bytes)
        .map_err(|e| format!("Failed to create secret key: {}", e))?;
    
    let keypair = libp2p_identity::ed25519::Keypair::from(secret);
    
    // Generate PeerId from the keypair's public key
    let peer_id = libp2p_identity::PeerId::from_public_key(&keypair.public().into());
    
    Ok(peer_id.to_string())
}

/// Database entry for Flutter
#[frb(dart_metadata=("freezed"))]
pub struct DbEntryDto {
    pub db_name: String,
    pub key: String,
    pub value: String,
    pub value_bytes: Vec<u8>,
}

/// List all databases in storage
#[frb(sync)]
pub fn list_databases() -> Result<Vec<String>, String> {
    let node = get_node()?;
    node.list_databases().map_err(|e| e.to_string())
}

/// List all keys in a specific database
#[frb(sync)]
pub fn list_keys(db_name: String) -> Result<Vec<String>, String> {
    let node = get_node()?;
    node.list_keys(&db_name).map_err(|e| e.to_string())
}

/// Get all entries from a specific database
#[frb]
pub async fn get_all_entries(db_name: String) -> Result<Vec<DbEntryDto>, String> {
    let node = get_node()?;
    node.get_all_entries(&db_name).await.map_err(|e| e.to_string())
}

/// Get all entries from all databases
#[frb]
pub async fn get_all_data() -> Result<Vec<DbEntryDto>, String> {
    let node = get_node()?;
    node.get_all_data().await.map_err(|e| e.to_string())
}

/// Delete a key from a database
#[frb]
pub async fn delete_data(db_name: String, key: String) -> Result<(), String> {
    let node = get_node()?;
    node.delete_data(&db_name, &key).await.map_err(|e| e.to_string())
}

/// Get recent logs from the buffer
#[frb(sync)]
pub fn get_logs(limit: Option<u32>) -> Vec<LogEntry> {
    let buffer = get_log_buffer();
    let guard = buffer.read();
    let limit = limit.unwrap_or(100) as usize;
    guard.iter().rev().take(limit).cloned().collect::<Vec<_>>().into_iter().rev().collect()
}

/// Clear the log buffer
#[frb(sync)]
pub fn clear_logs() {
    let buffer = get_log_buffer();
    buffer.write().clear();
}
