//! Peer discovery protocol using gossip
//! 
//! This module handles peer discovery through signed announcements over gossip,
//! matching the cyberfly-rust-node gossip_discovery implementation.

use std::collections::HashMap;
use std::time::{Duration, Instant};

use anyhow::{anyhow, Result};
use serde::{Deserialize, Serialize};
use tracing::{debug, info, warn};

use crate::crypto;

/// How long before a peer is considered expired (no announcement)
pub const PEER_EXPIRY_SECS: u64 = 300;

/// How often to announce ourselves
pub const ANNOUNCE_INTERVAL_SECS: u64 = 10;

/// Node capabilities
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct NodeCapabilities {
    /// Whether the node supports MQTT bridging
    pub mqtt: bool,
    /// Whether the node supports streams
    pub streams: bool,
    /// Whether the node supports timeseries data
    pub timeseries: bool,
    /// Whether the node supports geo features
    pub geo: bool,
    /// Whether the node supports blob transfers
    pub blobs: bool,
    /// Whether the node is a mobile node
    #[serde(default)]
    pub mobile: bool,
}

impl NodeCapabilities {
    pub fn mobile_node() -> Self {
        Self {
            mqtt: false,
            streams: false,
            timeseries: false,
            geo: false,
            blobs: true,
            mobile: true,
        }
    }
}

/// Peer information discovered through gossip
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DiscoveredPeer {
    /// Node ID (EndpointId as string)
    pub node_id: String,
    /// Public key for signing (hex)
    pub public_key: String,
    /// Optional direct address (ip:port)
    pub address: Option<String>,
    /// Node capabilities
    pub capabilities: NodeCapabilities,
    /// Region/location identifier
    pub region: Option<String>,
    /// Version string
    pub version: Option<String>,
    /// Last seen timestamp (local)
    #[serde(skip)]
    pub last_seen: Option<Instant>,
    /// Measured latency in milliseconds
    #[serde(skip)]
    pub latency_ms: Option<u64>,
}

impl DiscoveredPeer {
    pub fn is_expired(&self) -> bool {
        self.last_seen
            .map(|t| t.elapsed() > Duration::from_secs(PEER_EXPIRY_SECS))
            .unwrap_or(true)
    }
}

/// Peer discovery announcement (signed)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PeerAnnouncement {
    /// Unique announcement ID
    pub id: String,
    /// Node ID announcing
    pub node_id: String,
    /// Public key (hex) for verification
    pub public_key: String,
    /// Optional direct address
    pub address: Option<String>,
    /// Node capabilities
    pub capabilities: NodeCapabilities,
    /// Region identifier
    pub region: Option<String>,
    /// Version string
    pub version: Option<String>,
    /// Unix timestamp (ms)
    pub timestamp: i64,
    /// Ed25519 signature of the announcement (hex)
    pub signature: String,
}

impl PeerAnnouncement {
    /// Create a new announcement (unsigned)
    pub fn new(
        node_id: String,
        public_key: String,
        address: Option<String>,
        capabilities: NodeCapabilities,
        region: Option<String>,
        version: Option<String>,
    ) -> Self {
        Self {
            id: uuid::Uuid::new_v4().to_string(),
            node_id,
            public_key,
            address,
            capabilities,
            region,
            version,
            timestamp: chrono::Utc::now().timestamp_millis(),
            signature: String::new(),
        }
    }

    /// Get the message to sign
    pub fn signing_message(&self) -> String {
        format!(
            "{}:{}:{}:{}",
            self.id,
            self.node_id,
            self.timestamp,
            self.address.as_deref().unwrap_or("")
        )
    }

    /// Sign this announcement
    pub fn sign(&mut self, signing_key: &ed25519_dalek::SigningKey) {
        let message = self.signing_message();
        self.signature = crypto::sign_message(signing_key, message.as_bytes());
    }

    /// Verify the signature
    pub fn verify(&self) -> Result<bool> {
        if self.signature.is_empty() {
            return Ok(false);
        }
        let message = self.signing_message();
        crypto::verify_signature(&self.public_key, message.as_bytes(), &self.signature)
    }

    /// Convert to DiscoveredPeer
    pub fn to_discovered_peer(&self) -> DiscoveredPeer {
        DiscoveredPeer {
            node_id: self.node_id.clone(),
            public_key: self.public_key.clone(),
            address: self.address.clone(),
            capabilities: self.capabilities.clone(),
            region: self.region.clone(),
            version: self.version.clone(),
            last_seen: Some(Instant::now()),
            latency_ms: None,
        }
    }
}

/// Peer list announcement (broadcast list of known peers)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PeerListAnnouncement {
    /// Announcing node ID
    pub from_node_id: String,
    /// Public key of announcer
    pub public_key: String,
    /// List of known peers (format: "NodeId@ip:port" or just "NodeId")
    pub peers: Vec<String>,
    /// Unix timestamp (ms)
    pub timestamp: i64,
    /// Signature
    pub signature: String,
}

/// Desktop node's peer discovery announcement format (for compatibility)
/// This is used by cyberfly-rust-node on peer_discovery_topic
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PeerDiscoveryAnnouncement {
    /// Node ID of the sender
    pub node_id: String,
    /// List of connected peer addresses in format "peerId@ip:port"
    pub connected_peers: Vec<String>,
    /// Unix timestamp when announcement was created
    pub timestamp: i64,
    /// Region of the announcing node
    pub region: String,
    /// Ed25519 signature of the announcement
    pub signature: String,
}

impl PeerListAnnouncement {
    pub fn new(from_node_id: String, public_key: String, peers: Vec<String>) -> Self {
        Self {
            from_node_id,
            public_key,
            peers,
            timestamp: chrono::Utc::now().timestamp_millis(),
            signature: String::new(),
        }
    }

    pub fn signing_message(&self) -> String {
        format!(
            "{}:{}:{}",
            self.from_node_id,
            self.timestamp,
            self.peers.join(",")
        )
    }

    pub fn sign(&mut self, signing_key: &ed25519_dalek::SigningKey) {
        let message = self.signing_message();
        self.signature = crypto::sign_message(signing_key, message.as_bytes());
    }

    pub fn verify(&self) -> Result<bool> {
        if self.signature.is_empty() {
            return Ok(false);
        }
        let message = self.signing_message();
        crypto::verify_signature(&self.public_key, message.as_bytes(), &self.signature)
    }
}

/// Latency request message
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LatencyRequest {
    /// Request ID for matching response
    pub request_id: String,
    /// Requester node ID
    pub from_node_id: String,
    /// Public key
    pub public_key: String,
    /// Unix timestamp when request was sent (ms)
    pub sent_at: i64,
    /// Signature
    pub signature: String,
}

impl LatencyRequest {
    pub fn new(from_node_id: String, public_key: String) -> Self {
        Self {
            request_id: uuid::Uuid::new_v4().to_string(),
            from_node_id,
            public_key,
            sent_at: chrono::Utc::now().timestamp_millis(),
            signature: String::new(),
        }
    }

    pub fn signing_message(&self) -> String {
        format!("{}:{}:{}", self.request_id, self.from_node_id, self.sent_at)
    }

    pub fn sign(&mut self, signing_key: &ed25519_dalek::SigningKey) {
        let message = self.signing_message();
        self.signature = crypto::sign_message(signing_key, message.as_bytes());
    }

    pub fn verify(&self) -> Result<bool> {
        if self.signature.is_empty() {
            return Ok(false);
        }
        let message = self.signing_message();
        crypto::verify_signature(&self.public_key, message.as_bytes(), &self.signature)
    }
}

/// Latency response message
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LatencyResponse {
    /// Original request ID
    pub request_id: String,
    /// Responder node ID
    pub from_node_id: String,
    /// Public key
    pub public_key: String,
    /// Region of responder
    pub region: Option<String>,
    /// Unix timestamp when response was sent (ms)
    pub responded_at: i64,
    /// Signature
    pub signature: String,
}

impl LatencyResponse {
    pub fn new(request_id: String, from_node_id: String, public_key: String, region: Option<String>) -> Self {
        Self {
            request_id,
            from_node_id,
            public_key,
            region,
            responded_at: chrono::Utc::now().timestamp_millis(),
            signature: String::new(),
        }
    }

    pub fn signing_message(&self) -> String {
        format!(
            "{}:{}:{}",
            self.request_id, self.from_node_id, self.responded_at
        )
    }

    pub fn sign(&mut self, signing_key: &ed25519_dalek::SigningKey) {
        let message = self.signing_message();
        self.signature = crypto::sign_message(signing_key, message.as_bytes());
    }

    pub fn verify(&self) -> Result<bool> {
        if self.signature.is_empty() {
            return Ok(false);
        }
        let message = self.signing_message();
        crypto::verify_signature(&self.public_key, message.as_bytes(), &self.signature)
    }

    /// Calculate latency from original request
    pub fn calculate_latency(&self, request_sent_at: i64) -> u64 {
        let rtt = self.responded_at - request_sent_at;
        if rtt > 0 {
            (rtt / 2) as u64
        } else {
            0
        }
    }
}

/// Discovery message types for gossip
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type")]
pub enum DiscoveryMessage {
    /// Single peer announcement
    Announce(PeerAnnouncement),
    /// Broadcast list of known peers
    PeerList(PeerListAnnouncement),
    /// Latency check request
    LatencyRequest(LatencyRequest),
    /// Latency check response
    LatencyResponse(LatencyResponse),
}

/// Peer registry that tracks discovered peers
pub struct PeerRegistry {
    /// Known peers by node_id
    peers: HashMap<String, DiscoveredPeer>,
    /// Local node ID
    local_node_id: String,
    /// Announcement cache to prevent reconnection loops
    announcement_cache: HashMap<String, i64>,
}

impl PeerRegistry {
    pub fn new(local_node_id: String) -> Self {
        Self {
            peers: HashMap::new(),
            local_node_id,
            announcement_cache: HashMap::new(),
        }
    }

    /// Process a peer announcement
    pub fn process_announcement(&mut self, announcement: &PeerAnnouncement) -> Result<bool> {
        // Don't process our own announcements
        if announcement.node_id == self.local_node_id {
            return Ok(false);
        }

        // Check announcement cache
        if let Some(&cached_ts) = self.announcement_cache.get(&announcement.id) {
            if cached_ts >= announcement.timestamp {
                debug!("Skipping cached announcement {}", announcement.id);
                return Ok(false);
            }
        }

        // Verify signature
        if !announcement.verify().unwrap_or(false) {
            warn!("Invalid signature on announcement from {}", announcement.node_id);
            return Ok(false);
        }

        // Update cache
        self.announcement_cache.insert(announcement.id.clone(), announcement.timestamp);

        // Update or insert peer
        let peer = announcement.to_discovered_peer();
        let is_new = !self.peers.contains_key(&peer.node_id);
        
        self.peers.insert(peer.node_id.clone(), peer);

        if is_new {
            info!("Discovered new peer: {}", announcement.node_id);
        } else {
            debug!("Updated peer: {}", announcement.node_id);
        }

        Ok(is_new)
    }

    /// Process a peer list announcement
    pub fn process_peer_list(&mut self, list: &PeerListAnnouncement) -> Vec<String> {
        if list.from_node_id == self.local_node_id {
            return vec![];
        }

        if !list.verify().unwrap_or(false) {
            warn!("Invalid signature on peer list from {}", list.from_node_id);
            return vec![];
        }

        // Return unknown peer IDs for potential connection
        list.peers
            .iter()
            .filter_map(|peer_str| {
                // Parse "NodeId@ip:port" or just "NodeId"
                let node_id = peer_str.split('@').next()?.to_string();
                if node_id == self.local_node_id || self.peers.contains_key(&node_id) {
                    None
                } else {
                    Some(peer_str.clone())
                }
            })
            .collect()
    }

    /// Update peer latency
    pub fn update_latency(&mut self, node_id: &str, latency_ms: u64) {
        if let Some(peer) = self.peers.get_mut(node_id) {
            peer.latency_ms = Some(latency_ms);
            debug!("Updated latency for {}: {}ms", node_id, latency_ms);
        }
    }

    /// Register a peer directly from a gossip NeighborUp event
    /// This mirrors cyberfly-rust-node behavior where any connection counts as discovered
    pub fn register_connected_peer(&mut self, node_id: String) -> bool {
        if node_id == self.local_node_id {
            return false;
        }
        
        let is_new = !self.peers.contains_key(&node_id);
        
        if is_new {
            let peer = DiscoveredPeer {
                node_id: node_id.clone(),
                public_key: String::new(), // Unknown from NeighborUp
                address: None,
                capabilities: NodeCapabilities::default(),
                region: None,
                version: None,
                last_seen: Some(std::time::Instant::now()),
                latency_ms: None,
            };
            self.peers.insert(node_id.clone(), peer);
            info!("Registered connected peer from NeighborUp: {}", node_id);
        } else {
            // Update last_seen
            if let Some(peer) = self.peers.get_mut(&node_id) {
                peer.last_seen = Some(std::time::Instant::now());
            }
        }
        
        is_new
    }

    /// Unregister a peer (from NeighborDown)
    pub fn unregister_peer(&mut self, node_id: &str) {
        if self.peers.remove(node_id).is_some() {
            info!("Unregistered peer from NeighborDown: {}", node_id);
        }
    }

    /// Get a peer by node ID
    pub fn get_peer(&self, node_id: &str) -> Option<&DiscoveredPeer> {
        self.peers.get(node_id)
    }

    /// Get all peers
    pub fn get_all_peers(&self) -> Vec<&DiscoveredPeer> {
        self.peers.values().collect()
    }

    /// Get active (non-expired) peers
    pub fn get_active_peers(&self) -> Vec<&DiscoveredPeer> {
        self.peers.values().filter(|p| !p.is_expired()).collect()
    }

    /// Get peer count
    pub fn peer_count(&self) -> usize {
        self.peers.len()
    }

    /// Check if a peer exists
    pub fn has_peer(&self, node_id: &str) -> bool {
        self.peers.contains_key(node_id)
    }

    /// Register a peer from a peer list (with optional address and region)
    pub fn register_peer_from_list(&mut self, node_id: String, address: Option<String>, region: Option<String>) -> bool {
        if node_id == self.local_node_id {
            return false;
        }
        
        let is_new = !self.peers.contains_key(&node_id);
        
        if is_new {
            let region_str = region.clone();
            let peer = DiscoveredPeer {
                node_id: node_id.clone(),
                public_key: String::new(),
                address,
                capabilities: NodeCapabilities::default(),
                region,
                version: None,
                last_seen: Some(std::time::Instant::now()),
                latency_ms: None,
            };
            self.peers.insert(node_id.clone(), peer);
            info!("Registered peer from list: {} (region: {:?})", node_id, region_str);
        } else {
            // Update last_seen and optionally address/region
            if let Some(peer) = self.peers.get_mut(&node_id) {
                peer.last_seen = Some(std::time::Instant::now());
                if address.is_some() {
                    peer.address = address;
                }
                if region.is_some() {
                    peer.region = region;
                }
            }
        }
        
        is_new
    }

    /// Get active peer count
    pub fn active_peer_count(&self) -> usize {
        self.peers.values().filter(|p| !p.is_expired()).count()
    }

    /// Remove expired peers
    pub fn cleanup_expired(&mut self) -> usize {
        let before = self.peers.len();
        self.peers.retain(|_, p| !p.is_expired());
        let removed = before - self.peers.len();
        
        // Also cleanup old announcement cache entries
        let cutoff = chrono::Utc::now().timestamp_millis() - (PEER_EXPIRY_SECS as i64 * 1000);
        self.announcement_cache.retain(|_, ts| *ts > cutoff);
        
        if removed > 0 {
            info!("Cleaned up {} expired peers", removed);
        }
        removed
    }

    /// Get list of peer addresses for peer list announcement
    pub fn get_peer_list_for_broadcast(&self) -> Vec<String> {
        self.peers
            .values()
            .filter(|p| !p.is_expired())
            .map(|p| {
                if let Some(ref addr) = p.address {
                    format!("{}@{}", p.node_id, addr)
                } else {
                    p.node_id.clone()
                }
            })
            .collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::crypto::generate_keypair;

    #[test]
    fn test_peer_announcement_signing() {
        let (signing_key, public_key) = generate_keypair();
        
        let mut announcement = PeerAnnouncement::new(
            "node123".to_string(),
            public_key,
            Some("127.0.0.1:8080".to_string()),
            NodeCapabilities::mobile_node(),
            Some("us-west".to_string()),
            Some("1.0.0".to_string()),
        );
        
        announcement.sign(&signing_key);
        assert!(!announcement.signature.is_empty());
        assert!(announcement.verify().unwrap());
    }

    #[test]
    fn test_peer_registry() {
        let (signing_key, public_key) = generate_keypair();
        let mut registry = PeerRegistry::new("local-node".to_string());
        
        let mut announcement = PeerAnnouncement::new(
            "remote-node".to_string(),
            public_key,
            None,
            NodeCapabilities::default(),
            None,
            None,
        );
        announcement.sign(&signing_key);
        
        let is_new = registry.process_announcement(&announcement).unwrap();
        assert!(is_new);
        assert_eq!(registry.peer_count(), 1);
        
        // Same announcement shouldn't be processed again
        let is_new_again = registry.process_announcement(&announcement).unwrap();
        assert!(!is_new_again);
    }

    #[test]
    fn test_latency_calculation() {
        let sent_at = 1000i64;
        let response = LatencyResponse {
            request_id: "req1".to_string(),
            from_node_id: "node1".to_string(),
            public_key: "pub".to_string(),
            region: None,
            responded_at: 1100, // 100ms round trip
            signature: String::new(),
        };
        
        let latency = response.calculate_latency(sent_at);
        assert_eq!(latency, 50); // Half of RTT
    }
}
