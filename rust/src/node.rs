//! Cyberfly Node - P2P networking with Iroh
//! 
//! This module contains the main node implementation using Iroh for P2P networking,
//! gossip protocol for messaging, and sled for local storage.
//! 
//! Implements the same logic as cyberfly-rust-node for peer connect, gossip,
//! storage, sync, discovery, and latency measurement.

use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::Arc;
use std::time::{Duration, Instant};

use anyhow::{anyhow, Result};
use bytes::Bytes;
use dashmap::DashMap;
use ed25519_dalek::SigningKey;
use futures::StreamExt;
use iroh::{Endpoint, EndpointId, SecretKey, protocol::Router};
use iroh::discovery::pkarr::dht::DhtDiscovery;
use iroh_blobs::BlobsProtocol;
use iroh_gossip::net::Gossip;
use iroh_gossip::proto::TopicId;
use iroh_gossip::api::{Event as GossipEvent, GossipSender};
use parking_lot::RwLock;
use serde::{Deserialize, Serialize};
use tokio::sync::{mpsc, oneshot, Mutex};
use tracing::{error, info, warn, debug};

// Also use log macros for Android logcat output
#[allow(unused_imports)]
use log::{info as log_info, error as log_error, warn as log_warn};

use crate::storage::Storage;
use crate::sync::{SyncManager, SyncMessage, SignedOperation};
use crate::discovery::{
    PeerRegistry, PeerAnnouncement, PeerListAnnouncement, PeerDiscoveryAnnouncement,
    DiscoveryMessage, LatencyRequest, LatencyResponse,
    NodeCapabilities, DiscoveredPeer, ANNOUNCE_INTERVAL_SECS,
};

/// Bootstrap peer for the Cyberfly network
const DEFAULT_BOOTSTRAP: &str = "04b754ba2a3da0970d72d08b8740fb2ad96e63cf8f8bef6b7f1ab84e5b09a7f8@67.211.219.34:31001";

/// Gossip topics (must be exactly 32 bytes)
const DATA_TOPIC: &[u8; 32] = b"decentralized-db-data-v1-iroh!!!";
const DISCOVERY_TOPIC: &[u8; 32] = b"decentralized-db-discovery-iroh!";
const SYNC_TOPIC: &[u8; 32] = b"decentralized-db-sync-v1-iroh!!!";
const PEER_DISCOVERY_TOPIC: &[u8; 32] = b"decentralized-peer-list-v1-iroh!";
/// Improved discovery topic (postcard + ed25519) - matches cyberfly-rust-node v2
const IMPROVED_DISCOVERY_TOPIC: &[u8; 32] = b"cyberfly-discovery-v2-postcard!!";

/// Node version
const NODE_VERSION: &str = "cyberfly-mobile-0.1.0";

/// Gossip message types (for data topic)
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "msg_type")]
pub enum GossipMessage {
    /// Custom message
    Custom {
        from: String,
        content: String,
        timestamp: u64,
    },
    /// Latency request
    LatencyRequest {
        request_id: String,
        from_node_id: String,
        public_key: String,
        sent_at: i64,
        signature: String,
    },
    /// Latency response
    LatencyResponse {
        request_id: String,
        from_node_id: String,
        public_key: String,
        region: Option<String>,
        responded_at: i64,
        signature: String,
    },
}

/// Node status
#[derive(Debug, Clone)]
pub struct NodeStatus {
    pub is_running: bool,
    pub node_id: Option<String>,
    pub connected_peers: usize,
    pub discovered_peers: usize,
    pub uptime_seconds: u64,
    pub gossip_messages_received: u64,
    pub storage_size_bytes: u64,
    pub total_keys: u64,
    pub total_operations: u64,
    pub sync_operations: usize,
    pub latency_requests_sent: u64,
    pub latency_responses_received: u64,
}

/// Node events sent to Flutter
#[derive(Debug, Clone)]
pub enum NodeEvent {
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

/// Pending latency requests
struct PendingLatencyRequest {
    sent_at: i64,
    callback: Option<oneshot::Sender<u64>>,
}

/// Commands sent to the node
enum NodeCommand {
    Stop(oneshot::Sender<()>),
    GetStatus(oneshot::Sender<NodeStatus>),
    GetPeers(oneshot::Sender<Vec<DiscoveredPeer>>),
    SendGossip { topic: String, message: String },
    SendLatencyRequest { peer_id: String, response: oneshot::Sender<Result<u64, String>> },
    StoreData { db_name: String, key: String, value: Vec<u8>, public_key: String, signature: String },
    GetData { db_name: String, key: String, response: oneshot::Sender<Option<Vec<u8>>> },
    RequestSync { since_timestamp: Option<i64> },
}

/// Shared node state - updated by run_node, read by API
#[derive(Debug, Clone)]
pub struct SharedNodeState {
    pub is_running: bool,
    pub connected_peers: usize,
    pub discovered_peers: usize,
    pub gossip_messages_received: u64,
    pub latency_requests_sent: u64,
    pub latency_responses_received: u64,
    pub sync_operations: usize,
}

impl Default for SharedNodeState {
    fn default() -> Self {
        Self {
            is_running: true,
            connected_peers: 0,
            discovered_peers: 0,
            gossip_messages_received: 0,
            latency_requests_sent: 0,
            latency_responses_received: 0,
            sync_operations: 0,
        }
    }
}

/// Main Cyberfly node
pub struct CyberflyNode {
    command_tx: mpsc::Sender<NodeCommand>,
    event_rx: Arc<RwLock<Option<mpsc::Receiver<NodeEvent>>>>,
    node_id: String,
    public_key: String,
    start_time: Instant,
    // Shared state for sync access
    shared_state: Arc<RwLock<SharedNodeState>>,
    peer_registry: Arc<RwLock<PeerRegistry>>,
    storage: Arc<Storage>,
}

impl CyberflyNode {
    /// Create and start a new node
    pub async fn start(
        data_dir: String,
        wallet_secret_key: Option<String>,
        bootstrap_peers: Vec<String>,
        region: Option<String>,
    ) -> Result<Self> {
        let data_path = PathBuf::from(&data_dir);
        std::fs::create_dir_all(&data_path)?;

        // Generate or restore secret key
        let secret_key = if let Some(sk_hex) = wallet_secret_key {
            let sk_bytes = hex::decode(&sk_hex)?;
            let sk_array: [u8; 32] = sk_bytes.try_into()
                .map_err(|_| anyhow!("Invalid secret key length"))?;
            SecretKey::try_from(&sk_array[..])?
        } else {
            // Load or generate key
            let key_path = data_path.join("secret_key");
            if key_path.exists() {
                let key_bytes = std::fs::read(&key_path)?;
                SecretKey::try_from(&key_bytes[0..32])?
            } else {
                #[allow(deprecated)]
                let key = SecretKey::generate(&mut rand::thread_rng());
                std::fs::write(&key_path, key.to_bytes())?;
                key
            }
        };

        let public_key_hex = hex::encode(secret_key.public().as_bytes());
        
        // Create ed25519 signing key from the same secret
        let signing_key = SigningKey::from_bytes(&secret_key.to_bytes());
        
        info!("Starting Cyberfly node...");

        // Initialize storage
        let storage = Storage::new(data_path.join("sled_db"))?;
        
        // Log existing data on startup
        let db_count = storage.list_databases().unwrap_or_default().len();
        let key_count = storage.key_count().unwrap_or(0);
        let size_bytes = storage.size_bytes().unwrap_or(0);
        info!("📦 Storage loaded: {} databases, {} keys, {} bytes", db_count, key_count, size_bytes);
        if db_count > 0 {
            for db_name in storage.list_databases().unwrap_or_default() {
                let keys = storage.list_keys(&db_name).unwrap_or_default();
                info!("  📁 Database '{}': {} keys", db_name, keys.len());
            }
        }

        // Create channels
        let (command_tx, command_rx) = mpsc::channel(100);
        let (event_tx, event_rx) = mpsc::channel(100);

        // Build discovery - DHT + mDNS for local network peers (matching desktop)
        let dht_discovery = DhtDiscovery::builder();
        // mDNS discovery for local network peer discovery (like desktop node)
        let mdns_discovery = iroh::discovery::mdns::MdnsDiscovery::builder();

        // Create endpoint with both DHT and mDNS discovery
        let endpoint = Endpoint::builder()
            .secret_key(secret_key.clone())
            .discovery(dht_discovery)
            .discovery(mdns_discovery)
            .relay_mode(iroh::RelayMode::Default)
            .bind()
            .await?;

        let node_id = endpoint.id();
        let node_id_str = node_id.to_string();

        info!("Node ID: {}", node_id_str);
        log_info!("Node ID: {}", node_id_str);
        
        // Wait for endpoint to be online (have relay connection)
        // This is important for NAT traversal
        log_info!(">>> Waiting for endpoint to be online (relay connection)...");
        endpoint.online().await;
        log_info!(">>> Endpoint is online!");
        
        // Log endpoint addresses
        let my_addr = endpoint.addr();
        log_info!(">>> Our endpoint relay URLs: {:?}", 
            my_addr.relay_urls().collect::<Vec<_>>());

        // Create blob store
        let store = iroh_blobs::store::fs::FsStore::load(&data_path.join("blobs")).await?;
        let blobs = BlobsProtocol::new(&store, None);

        // Create gossip
        let gossip = Gossip::builder().spawn(endpoint.clone());

        // Build router
        let router = Router::builder(endpoint.clone())
            .accept(iroh_blobs::ALPN, blobs.clone())
            .accept(iroh_gossip::ALPN, gossip.clone())
            .spawn();

        // Parse bootstrap peers and connect to them with retry logic
        let mut bootstrap_node_ids: Vec<EndpointId> = Vec::new();
        let mut all_bootstrap_strings: Vec<String> = vec![DEFAULT_BOOTSTRAP.to_string()];
        all_bootstrap_strings.extend(bootstrap_peers.iter().cloned());
        
        // Connect to each bootstrap peer before subscribing to gossip
        for peer_str in &all_bootstrap_strings {
            if let Some((node_id_str, addr_str)) = peer_str.split_once('@') {
                if let Ok(peer_node_id) = node_id_str.parse::<EndpointId>() {
                    // Skip our own ID
                    if peer_node_id == node_id {
                        continue;
                    }
                    
                    bootstrap_node_ids.push(peer_node_id);
                    
                    // Parse socket address and connect with retry
                    if let Ok(socket_addr) = addr_str.parse::<std::net::SocketAddr>() {
                        info!("Connecting to bootstrap peer {} at {}", peer_node_id.fmt_short(), socket_addr);
                        log_info!(">>> Connecting to bootstrap peer {} at {}", peer_node_id.fmt_short(), socket_addr);
                        
                        // Retry connection with exponential backoff
                        const MAX_RETRIES: u32 = 5;
                        const INITIAL_DELAY_MS: u64 = 1000;
                        const MAX_DELAY_MS: u64 = 30000;
                        
                        let mut connected = false;
                        let mut delay_ms = INITIAL_DELAY_MS;
                        
                        for attempt in 1..=MAX_RETRIES {
                            log_info!(">>> Bootstrap connect attempt {}/{} to {}", attempt, MAX_RETRIES, peer_node_id.fmt_short());
                            
                            // First try direct IP connection
                            let endpoint_addr = iroh::EndpointAddr::from_parts(
                                peer_node_id,
                                vec![iroh::TransportAddr::Ip(socket_addr)],
                            );
                            
                            // Try direct connection with timeout
                            let connect_result = tokio::time::timeout(
                                Duration::from_secs(10),
                                endpoint.connect(endpoint_addr.clone(), iroh_gossip::ALPN)
                            ).await;
                            
                            match connect_result {
                                Ok(Ok(conn)) => {
                                    info!("✓ Connected to bootstrap peer {} via direct IP", peer_node_id.fmt_short());
                                    log_info!("✓ BOOTSTRAP_CONNECTED (direct): {} (remote_id: {:?})", 
                                        peer_node_id.fmt_short(), 
                                        conn.remote_id());
                                    connected = true;
                                    break;
                                }
                                Ok(Err(e)) => {
                                    log_warn!(">>> Direct connect attempt {} failed: {}", attempt, e);
                                    
                                    // After first failure, try via relay
                                    if attempt >= 1 {
                                        if let Some(relay_url) = endpoint.addr().relay_urls().next() {
                                            log_info!(">>> Trying relay-assisted connection via {}", relay_url);
                                            
                                            // Add relay to the endpoint address
                                            let relay_addr = iroh::EndpointAddr::from_parts(
                                                peer_node_id,
                                                vec![
                                                    iroh::TransportAddr::Ip(socket_addr),
                                                    iroh::TransportAddr::Relay(relay_url.clone()),
                                                ],
                                            );
                                            
                                            let relay_connect_result = tokio::time::timeout(
                                                Duration::from_secs(15),
                                                endpoint.connect(relay_addr, iroh_gossip::ALPN)
                                            ).await;
                                            
                                            match relay_connect_result {
                                                Ok(Ok(conn)) => {
                                                    info!("✓ Connected to bootstrap peer {} via relay", peer_node_id.fmt_short());
                                                    log_info!("✓ BOOTSTRAP_CONNECTED (relay): {} (remote_id: {:?})", 
                                                        peer_node_id.fmt_short(), 
                                                        conn.remote_id());
                                                    connected = true;
                                                    break;
                                                }
                                                Ok(Err(relay_e)) => {
                                                    log_warn!(">>> Relay connect attempt {} failed: {}", attempt, relay_e);
                                                }
                                                Err(_) => {
                                                    log_warn!(">>> Relay connect attempt {} timed out", attempt);
                                                }
                                            }
                                        } else {
                                            log_warn!(">>> No relay URL available for fallback");
                                        }
                                    }
                                }
                                Err(_) => {
                                    log_warn!(">>> Direct connect attempt {} timed out", attempt);
                                }
                            }
                            
                            // Wait before retry with exponential backoff
                            if attempt < MAX_RETRIES {
                                log_info!(">>> Waiting {}ms before retry...", delay_ms);
                                tokio::time::sleep(Duration::from_millis(delay_ms)).await;
                                delay_ms = (delay_ms * 2).min(MAX_DELAY_MS);
                            }
                        }
                        
                        if !connected {
                            log_warn!(">>> Failed to connect to bootstrap peer {} after {} attempts", 
                                peer_node_id.fmt_short(), MAX_RETRIES);
                        }
                    } else {
                        log::warn!("BOOTSTRAP_PARSE_FAILED: could not parse address '{}'", addr_str);
                    }
                }
            }
        }

        // Clone for the task
        let node_id_clone = node_id_str.clone();
        let public_key_clone = public_key_hex.clone();
        let start_time = Instant::now();

        // Create shared state
        let shared_state = Arc::new(RwLock::new(SharedNodeState::default()));
        let shared_state_clone = shared_state.clone();
        
        // Create shared peer registry
        let peer_registry = Arc::new(RwLock::new(PeerRegistry::new(node_id_str.clone())));
        let peer_registry_clone = peer_registry.clone();
        
        // Mark connected bootstrap peers in the shared state
        // This ensures stats show connected peers even if HyParView NeighborUp hasn't fired yet
        {
            let connected_count = bootstrap_node_ids.len();
            let mut state = shared_state.write();
            state.connected_peers = connected_count;
            state.discovered_peers = connected_count;
            state.is_running = true;
            log::info!("Initial shared state: connected={}, discovered={}, is_running=true", 
                connected_count, connected_count);
        }
        
        // Also register bootstrap peers in peer registry
        for peer_id in &bootstrap_node_ids {
            peer_registry.write().register_connected_peer(peer_id.to_string());
            log::info!("Registered bootstrap peer in registry: {}", peer_id.fmt_short());
        }
        
        // Create shared storage
        let storage_arc = Arc::new(storage);
        let storage_clone = storage_arc.clone();

        // Get the current runtime handle to spawn run_node on
        // This ensures run_node runs on the same runtime as the caller
        let runtime_handle = tokio::runtime::Handle::current();
        
        // Spawn the main node task using the runtime handle
        runtime_handle.spawn(async move {
            Self::run_node(
                endpoint,
                router,
                gossip,
                storage_clone,
                command_rx,
                event_tx,
                node_id_clone,
                public_key_clone,
                bootstrap_node_ids,
                signing_key,
                region,
                shared_state_clone,
                peer_registry_clone,
            ).await;
        });

        Ok(Self {
            command_tx,
            event_rx: Arc::new(RwLock::new(Some(event_rx))),
            node_id: node_id_str,
            public_key: public_key_hex,
            start_time,
            shared_state,
            peer_registry,
            storage: storage_arc,
        })
    }

    /// Main node event loop
    async fn run_node(
        endpoint: Endpoint,
        router: Router,
        gossip: Gossip,
        storage: Arc<Storage>,
        mut command_rx: mpsc::Receiver<NodeCommand>,
        event_tx: mpsc::Sender<NodeEvent>,
        node_id: String,
        public_key: String,
        bootstrap_peers: Vec<EndpointId>,
        signing_key: SigningKey,
        region: Option<String>,
        shared_state: Arc<RwLock<SharedNodeState>>,
        peer_registry: Arc<RwLock<PeerRegistry>>,
    ) {
        eprintln!(">>> RUST: run_node starting for node_id: {}", node_id);
        info!(">>> run_node starting for node_id: {}", node_id);
        
        // Gossip message counter - use shared state
        // (we'll update shared_state directly instead)
        
        // Connected peers (from NeighborUp events)
        let connected_peers: Arc<DashMap<String, Instant>> = Arc::new(DashMap::new());
        
        // Sync manager
        let sync_manager = Arc::new(SyncManager::new(storage.clone(), node_id.clone()));
        
        // Load persisted operations from storage
        match sync_manager.sync_store().load_from_storage().await {
            Ok(loaded) => {
                log_info!("✓ Loaded {} operations from persistent storage", loaded);
            }
            Err(e) => {
                log_error!("Failed to load operations from storage: {}", e);
            }
        }
        
        // Pending latency requests
        let pending_latency: Arc<RwLock<HashMap<String, PendingLatencyRequest>>> = 
            Arc::new(RwLock::new(HashMap::new()));

        // Send started event
        log_info!(">>> About to send Started event");
        let send_result = event_tx.send(NodeEvent::Started {
            node_id: node_id.clone(),
            public_key: public_key.clone(),
        }).await;
        log_info!(">>> Started event sent, result: {:?}", send_result.is_ok());

        // Create topic IDs
        log_info!(">>> Creating topic IDs");
        let data_topic_id = TopicId::from_bytes(*DATA_TOPIC);
        let discovery_topic_id = TopicId::from_bytes(*DISCOVERY_TOPIC);
        let sync_topic_id = TopicId::from_bytes(*SYNC_TOPIC);
        let peer_discovery_topic_id = TopicId::from_bytes(*PEER_DISCOVERY_TOPIC);
        let improved_discovery_topic_id = TopicId::from_bytes(*IMPROVED_DISCOVERY_TOPIC);
        log_info!(">>> Topic IDs created successfully (including v2 improved discovery)");

        // Gossip senders for each topic
        log_info!(">>> Creating gossip senders");
        let data_sender: Arc<Mutex<Option<GossipSender>>> = Arc::new(Mutex::new(None));
        let discovery_sender: Arc<Mutex<Option<GossipSender>>> = Arc::new(Mutex::new(None));
        let sync_sender: Arc<Mutex<Option<GossipSender>>> = Arc::new(Mutex::new(None));
        let peer_discovery_sender: Arc<Mutex<Option<GossipSender>>> = Arc::new(Mutex::new(None));
        let improved_discovery_sender: Arc<Mutex<Option<GossipSender>>> = Arc::new(Mutex::new(None));
        log_info!(">>> Gossip senders created");

        let peer_ids_str: Vec<String> = bootstrap_peers.iter().map(|p| p.fmt_short().to_string()).collect();
        log_info!("About to subscribe to data topic with {} bootstrap peers: {:?}", 
            bootstrap_peers.len(), peer_ids_str);
        info!("About to subscribe to data topic with {} bootstrap peers", bootstrap_peers.len());
        
        // Subscribe to data topic - use subscribe() like desktop (non-blocking)
        // Desktop uses subscribe() which returns immediately, not subscribe_and_join()
        log_info!(">>> Calling gossip.subscribe for data topic (non-blocking like desktop)...");
        
        let data_subscribe_result = gossip.subscribe(data_topic_id, bootstrap_peers.clone()).await;
        log_info!("Data topic subscribe result: success={}", data_subscribe_result.is_ok());
        
        match data_subscribe_result {
            Ok(topic_handle) => {
            log_info!("Successfully subscribed to data topic");
            info!("Successfully subscribed to data topic");
            let (sender, mut receiver) = topic_handle.split();
            *data_sender.lock().await = Some(sender);
            
            let event_tx_clone = event_tx.clone();
            let shared_state_clone = shared_state.clone();
            let connected_peers_clone = connected_peers.clone();
            let peer_registry_clone = peer_registry.clone();
            let pending_latency_clone = pending_latency.clone();
            let signing_key_clone = signing_key.clone();
            let node_id_clone = node_id.clone();
            let public_key_clone = public_key.clone();
            let region_clone = region.clone();
            let data_sender_clone = data_sender.clone();

            tokio::spawn(async move {
                log_info!("📡 DATA_TOPIC LISTENER TASK STARTED");
                log_info!("Data topic listener started, waiting for gossip events...");
                info!("Data topic listener started, waiting for gossip events...");
                
                let mut event_count = 0u64;
                while let Some(event) = receiver.next().await {
                    event_count += 1;
                    log_info!("📡 DATA_TOPIC EVENT #{}: {:?}", event_count,
                        match &event {
                            Ok(GossipEvent::Received(m)) => format!("Received {} bytes from {}", m.content.len(), m.delivered_from.fmt_short()),
                            Ok(GossipEvent::NeighborUp(p)) => format!("NeighborUp {}", p.fmt_short()),
                            Ok(GossipEvent::NeighborDown(p)) => format!("NeighborDown {}", p.fmt_short()),
                            Ok(GossipEvent::Lagged) => "Lagged".to_string(),
                            Err(e) => format!("Error: {:?}", e),
                        });
                    log_info!("Received gossip event on data topic: {:?}", event.as_ref().map(|e| match e {
                        GossipEvent::Received(_) => "Received",
                        GossipEvent::NeighborUp(_) => "NeighborUp",
                        GossipEvent::NeighborDown(_) => "NeighborDown",
                        GossipEvent::Lagged => "Lagged",
                    }).unwrap_or("Err"));
                    match event {
                        Ok(GossipEvent::Received(msg)) => {
                            log_info!("Received gossip message from {}", msg.delivered_from);
                            shared_state_clone.write().gossip_messages_received += 1;
                            let from = msg.delivered_from.to_string();
                            
                            if let Ok(gossip_msg) = serde_json::from_slice::<GossipMessage>(&msg.content) {
                                match gossip_msg {
                                    GossipMessage::Custom { from: sender, content, .. } => {
                                        let _ = event_tx_clone.send(NodeEvent::GossipReceived {
                                            topic: "data".to_string(),
                                            from: sender,
                                            content,
                                        }).await;
                                    }
                                    GossipMessage::LatencyRequest { request_id, from_node_id, public_key, sent_at, signature } => {
                                        // Verify and respond
                                        let req = LatencyRequest {
                                            request_id: request_id.clone(),
                                            from_node_id: from_node_id.clone(),
                                            public_key,
                                            sent_at,
                                            signature,
                                        };
                                        
                                        if req.verify().unwrap_or(false) {
                                            let mut response = LatencyResponse::new(
                                                request_id,
                                                node_id_clone.clone(),
                                                public_key_clone.clone(),
                                                region_clone.clone(),
                                            );
                                            response.sign(&signing_key_clone);
                                            
                                            let resp_msg = GossipMessage::LatencyResponse {
                                                request_id: response.request_id,
                                                from_node_id: response.from_node_id,
                                                public_key: response.public_key,
                                                region: response.region,
                                                responded_at: response.responded_at,
                                                signature: response.signature,
                                            };
                                            
                                            if let Some(sender) = data_sender_clone.lock().await.as_ref() {
                                                let _ = sender.broadcast(Bytes::from(serde_json::to_vec(&resp_msg).unwrap())).await;
                                            }
                                        }
                                    }
                                    GossipMessage::LatencyResponse { request_id, from_node_id, responded_at, .. } => {
                                        // Check if we have a pending request - scope lock to avoid Send issue
                                        let pending_and_latency = {
                                            let pending = pending_latency_clone.write().remove(&request_id);
                                            pending.map(|p| {
                                                let latency = if responded_at > p.sent_at {
                                                    ((responded_at - p.sent_at) / 2) as u64
                                                } else {
                                                    0
                                                };
                                                (latency, p.callback)
                                            })
                                        };
                                        
                                        if let Some((latency, callback)) = pending_and_latency {
                                            // Increment latency responses received counter
                                            shared_state_clone.write().latency_responses_received += 1;
                                            
                                            // Update peer registry
                                            peer_registry_clone.write().update_latency(&from_node_id, latency);
                                            
                                            // Send event
                                            let _ = event_tx_clone.send(NodeEvent::LatencyMeasured {
                                                peer_id: from_node_id.clone(),
                                                latency_ms: latency,
                                            }).await;
                                            
                                            // Respond to callback if present
                                            if let Some(callback) = callback {
                                                let _ = callback.send(latency);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        Ok(GossipEvent::NeighborUp(peer_id)) => {
                            let peer_str = peer_id.to_string();
                            log_info!("NeighborUp! peer={}", peer_str);
                            info!("NeighborUp! peer={}", peer_str);
                            connected_peers_clone.insert(peer_str.clone(), Instant::now());
                            
                            // Register in peer_registry to match desktop node behavior
                            peer_registry_clone.write().register_connected_peer(peer_str.clone());
                            
                            // Update both counts from peer_registry (source of truth)
                            let peer_count = peer_registry_clone.read().peer_count();
                            log_info!("Peer registry count after NeighborUp: {}", peer_count);
                            {
                                let mut state = shared_state_clone.write();
                                state.connected_peers = peer_count;
                                state.discovered_peers = peer_count;
                                log_info!("SharedState updated: connected={}, discovered={}", state.connected_peers, state.discovered_peers);
                            }
                            let _ = event_tx_clone.send(NodeEvent::PeerConnected { peer_id: peer_str }).await;
                        }
                        Ok(GossipEvent::NeighborDown(peer_id)) => {
                            let peer_str = peer_id.to_string();
                            log_info!("NeighborDown! peer={}", peer_str);
                            info!("NeighborDown! peer={}", peer_str);
                            connected_peers_clone.remove(&peer_str);
                            
                            // Unregister from peer_registry
                            peer_registry_clone.write().unregister_peer(&peer_str);
                            
                            // Update counts from peer_registry
                            let peer_count = peer_registry_clone.read().peer_count();
                            {
                                let mut state = shared_state_clone.write();
                                state.connected_peers = peer_count;
                                state.discovered_peers = peer_count;
                            }
                            let _ = event_tx_clone.send(NodeEvent::PeerDisconnected { peer_id: peer_str }).await;
                        }
                        Ok(GossipEvent::Lagged) => {
                            log_warn!("Data topic gossip lagged");
                            warn!("Data topic gossip lagged");
                        }
                        Err(e) => {
                            log_error!("Data topic gossip error: {}", e);
                            warn!("Data topic gossip error: {}", e);
                        }
                    }
                }
                log_info!(">>> RUST: Data topic listener ended");
            });
            } // end Ok(topic_handle)
            Err(e) => {
                log_error!(">>> RUST: Failed to subscribe to data topic: {:?}", e);
            }
        }

        // Subscribe to discovery topic
        if let Ok(topic_handle) = gossip.subscribe(discovery_topic_id, bootstrap_peers.clone()).await {
            let (sender, mut receiver) = topic_handle.split();
            *discovery_sender.lock().await = Some(sender);
            
            let event_tx_clone = event_tx.clone();
            let peer_registry_clone = peer_registry.clone();
            let shared_state_clone = shared_state.clone();
            let endpoint_clone = endpoint.clone();

            tokio::spawn(async move {
                while let Some(event) = receiver.next().await {
                    if let Ok(GossipEvent::Received(msg)) = event {
                        if let Ok(disc_msg) = serde_json::from_slice::<DiscoveryMessage>(&msg.content) {
                            match disc_msg {
                                DiscoveryMessage::Announce(announcement) => {
                                    // Scope the lock to avoid Send issue
                                    let (is_new, node_id, address) = {
                                        let result = peer_registry_clone.write().process_announcement(&announcement);
                                        match result {
                                            Ok(is_new) => (is_new, announcement.node_id.clone(), announcement.address.clone()),
                                            Err(_) => continue,
                                        }
                                    };
                                    
                                    // Update peer counts in shared state to mirror desktop node behavior
                                    let peer_count = peer_registry_clone.read().peer_count();
                                    {
                                        let mut state = shared_state_clone.write();
                                        state.discovered_peers = peer_count;
                                        state.connected_peers = peer_count;
                                    }
                                    
                                    if is_new {
                                        let _ = event_tx_clone.send(NodeEvent::PeerDiscovered {
                                            peer_id: node_id.clone(),
                                            address: address.clone(),
                                        }).await;
                                        
                                        // ACTIVELY CONNECT to new peer (like desktop node does)
                                        if let Ok(peer_endpoint_id) = node_id.parse::<EndpointId>() {
                                            // Try to connect with address if available
                                            let connect_result = if let Some(ref addr_str) = address {
                                                if let Ok(socket_addr) = addr_str.parse::<std::net::SocketAddr>() {
                                                    let endpoint_addr = iroh::EndpointAddr::from_parts(
                                                        peer_endpoint_id,
                                                        vec![iroh::TransportAddr::Ip(socket_addr)],
                                                    );
                                                    endpoint_clone.connect(endpoint_addr, iroh_gossip::ALPN).await
                                                } else {
                                                    // No valid address, try DHT/relay
                                                    endpoint_clone.connect(peer_endpoint_id, iroh_gossip::ALPN).await
                                                }
                                            } else {
                                                // No address, try DHT/relay discovery
                                                endpoint_clone.connect(peer_endpoint_id, iroh_gossip::ALPN).await
                                            };
                                            
                                            match connect_result {
                                                Ok(_conn) => {
                                                    log_info!("✓ Connected to discovered peer {} via announcement", node_id);
                                                }
                                                Err(e) => {
                                                    log_warn!("Failed to connect to peer {}: {}", node_id, e);
                                                }
                                            }
                                        }
                                    }
                                }
                                _ => {}
                            }
                        }
                    }
                }
            });
        }

        // Subscribe to sync topic
        if let Ok(topic_handle) = gossip.subscribe(sync_topic_id, bootstrap_peers.clone()).await {
            let (sender, mut receiver) = topic_handle.split();
            *sync_sender.lock().await = Some(sender);
            
            let sync_manager_clone = sync_manager.clone();
            let event_tx_clone = event_tx.clone();
            let sync_sender_clone = sync_sender.clone();
            let shared_state_clone = shared_state.clone();

            tokio::spawn(async move {
                log_info!("Sync topic listener started, waiting for sync messages...");
                while let Some(event) = receiver.next().await {
                    match event {
                        Ok(GossipEvent::Received(msg)) => {
                            let from_peer = msg.delivered_from.to_string();
                            log_info!("📨 Received sync message from {} ({} bytes)", from_peer, msg.content.len());
                            
                            match serde_json::from_slice::<SyncMessage>(&msg.content) {
                                Ok(sync_msg) => {
                                    // Log what type of message we received
                                    match &sync_msg {
                                        SyncMessage::Operation { operation } => {
                                            log_info!("📥 Received Operation: {} db={} key={}", 
                                                operation.op_id, operation.db_name, operation.key);
                                        }
                                        SyncMessage::SyncRequest { requester, since_timestamp } => {
                                            log_info!("📥 Received SyncRequest from {} since={:?}", 
                                                requester, since_timestamp);
                                        }
                                        SyncMessage::SyncResponse { requester, operations, .. } => {
                                            log_info!("📥 Received SyncResponse for {} with {} ops", 
                                                requester, operations.len());
                                        }
                                    }
                                    
                                    // Update sync operations counter
                                    shared_state_clone.write().sync_operations += 1;
                                    
                                    match sync_manager_clone.handle_sync_message(sync_msg, &from_peer).await {
                                        Ok(Some(response)) => {
                                            log_info!("📤 Sending sync response");
                                            // Send response back
                                            if let Some(sender) = sync_sender_clone.lock().await.as_ref() {
                                                if let Ok(payload) = serde_json::to_vec(&response) {
                                                    let _ = sender.broadcast(Bytes::from(payload)).await;
                                                }
                                            }
                                        }
                                        Ok(None) => {
                                            log_info!("✓ Sync message handled (no response needed)");
                                        }
                                        Err(e) => {
                                            log_error!("❌ Failed to handle sync message: {}", e);
                                            error!("Failed to handle sync message: {}", e);
                                        }
                                    }
                                    
                                    // Send event for Operation messages
                                    if let Ok(SyncMessage::Operation { operation }) = serde_json::from_slice::<SyncMessage>(&msg.content) {
                                        let _ = event_tx_clone.send(NodeEvent::SyncReceived {
                                            db_name: operation.db_name,
                                            key: operation.key,
                                        }).await;
                                    }
                                }
                                Err(e) => {
                                    log_error!("❌ Failed to deserialize sync message: {}", e);
                                    // Log first 200 bytes for debugging
                                    let preview = String::from_utf8_lossy(&msg.content[..msg.content.len().min(200)]);
                                    log_error!("Message preview: {}", preview);
                                }
                            }
                        }
                        Ok(GossipEvent::NeighborUp(peer_id)) => {
                            log_info!("Sync topic: NeighborUp {}", peer_id);
                        }
                        Ok(GossipEvent::NeighborDown(peer_id)) => {
                            log_info!("Sync topic: NeighborDown {}", peer_id);
                        }
                        Ok(GossipEvent::Lagged) => {
                            log_warn!("Sync topic gossip lagged");
                        }
                        Err(e) => {
                            log_error!("Sync topic gossip error: {}", e);
                        }
                    }
                }
                log_info!("Sync topic listener ended");
            });
        } else {
            log_error!("Failed to subscribe to sync topic!");
        }

        // Subscribe to peer discovery topic - use subscribe() like desktop (non-blocking)
        log_info!(">>> Subscribing to peer_discovery topic with subscribe() (non-blocking like desktop)...");
        let peer_discovery_result = gossip.subscribe(peer_discovery_topic_id, bootstrap_peers.clone()).await;
        
        match peer_discovery_result {
            Ok(topic_handle) => {
            log_info!(">>> PEER_DISCOVERY_TOPIC subscription SUCCESS!");
            let (sender, mut receiver) = topic_handle.split();
            *peer_discovery_sender.lock().await = Some(sender);
            
            let peer_registry_clone = peer_registry.clone();
            let endpoint_clone = endpoint.clone();
            let event_tx_clone = event_tx.clone();
            let shared_state_clone = shared_state.clone();
            let node_id_clone = node_id.clone();

            tokio::spawn(async move {
                log_info!("📡 PEER_DISCOVERY LISTENER TASK STARTED");
                log_info!("📡 Peer discovery listener started (topic: decentralized-peer-list-v1-iroh!)");
                
                // Log every 10 seconds to confirm task is alive
                let mut event_count = 0u64;
                let mut last_log = std::time::Instant::now();
                
                while let Some(event) = receiver.next().await {
                    event_count += 1;
                    // Log every event type
                    log_info!("📡 PEER_DISCOVERY EVENT #{}: {:?}", event_count, 
                        match &event {
                            Ok(GossipEvent::Received(m)) => format!("Received {} bytes from {}", m.content.len(), m.delivered_from.fmt_short()),
                            Ok(GossipEvent::NeighborUp(p)) => format!("NeighborUp {}", p.fmt_short()),
                            Ok(GossipEvent::NeighborDown(p)) => format!("NeighborDown {}", p.fmt_short()),
                            Ok(GossipEvent::Lagged) => "Lagged".to_string(),
                            Err(e) => format!("Error: {:?}", e),
                        });
                    // Log alive status periodically
                    if last_log.elapsed().as_secs() >= 10 {
                        log_info!("📡 PEER_DISCOVERY ALIVE: {} events processed so far", event_count);
                        last_log = std::time::Instant::now();
                    }
                    
                    match event {
                        Ok(GossipEvent::Received(msg)) => {
                            let from_peer = msg.delivered_from;
                            
                            // Skip our own messages
                            if from_peer.to_string() == node_id_clone.to_string() {
                                continue;
                            }
                            
                            log_info!("📥 Received peer discovery message from {} ({} bytes)", 
                                from_peer.fmt_short(), msg.content.len());
                            
                            // Try to parse as desktop's PeerDiscoveryAnnouncement format first
                            if let Ok(announcement) = serde_json::from_slice::<PeerDiscoveryAnnouncement>(&msg.content) {
                                log_info!("📋 Parsed PeerDiscoveryAnnouncement from {} (region: {}): {} peers",
                                    announcement.node_id, announcement.region, announcement.connected_peers.len());
                                
                                // Process each peer in the announcement
                                for peer_str in &announcement.connected_peers {
                                    let node_id_str = peer_str.split('@').next().unwrap_or(peer_str);
                                    let address_str = peer_str.split('@').nth(1).map(|s| s.to_string());
                                    
                                    // Skip our own ID
                                    if node_id_str == node_id_clone.to_string() {
                                        continue;
                                    }
                                    
                                    // Check if already known
                                    let is_new = !peer_registry_clone.read().has_peer(node_id_str);
                                    
                                    if is_new {
                                        // Register the peer
                                        peer_registry_clone.write().register_peer_from_list(
                                            node_id_str.to_string(),
                                            address_str.clone(),
                                            Some(announcement.region.clone()),
                                        );
                                        
                                        log_info!("🔗 Connecting to new peer {} from announcement", node_id_str);
                                        
                                        // Try to connect
                                        if let Ok(peer_endpoint_id) = node_id_str.parse::<EndpointId>() {
                                            let connect_result = if let Some(ref addr_str) = address_str {
                                                if let Ok(socket_addr) = addr_str.parse::<std::net::SocketAddr>() {
                                                    let endpoint_addr = iroh::EndpointAddr::from_parts(
                                                        peer_endpoint_id,
                                                        vec![iroh::TransportAddr::Ip(socket_addr)],
                                                    );
                                                    endpoint_clone.connect(endpoint_addr, iroh_gossip::ALPN).await
                                                } else {
                                                    endpoint_clone.connect(peer_endpoint_id, iroh_gossip::ALPN).await
                                                }
                                            } else {
                                                endpoint_clone.connect(peer_endpoint_id, iroh_gossip::ALPN).await
                                            };
                                            
                                            match connect_result {
                                                Ok(_conn) => {
                                                    log_info!("✓ Connected to peer {} from discovery", node_id_str);
                                                }
                                                Err(e) => {
                                                    log_warn!("Failed to connect to peer {}: {}", node_id_str, e);
                                                }
                                            }
                                        }
                                        
                                        let _ = event_tx_clone.send(NodeEvent::PeerDiscovered {
                                            peer_id: node_id_str.to_string(),
                                            address: address_str,
                                        }).await;
                                    }
                                }
                                
                                // Update counts
                                let peer_count = peer_registry_clone.read().peer_count();
                                {
                                    let mut state = shared_state_clone.write();
                                    state.discovered_peers = peer_count;
                                    state.connected_peers = peer_count;
                                }
                            }
                            // Also try our mobile format
                            else if let Ok(disc_msg) = serde_json::from_slice::<DiscoveryMessage>(&msg.content) {
                                if let DiscoveryMessage::PeerList(list) = disc_msg {
                                    log_info!("📋 Parsed PeerList from {}: {} peers", 
                                        list.from_node_id, list.peers.len());
                                    
                                    let unknown_peers = peer_registry_clone.write().process_peer_list(&list);
                                    let peer_count = peer_registry_clone.read().peer_count();
                                    {
                                        let mut state = shared_state_clone.write();
                                        state.discovered_peers = peer_count;
                                        state.connected_peers = peer_count;
                                    }
                                    
                                    for peer_str in unknown_peers {
                                        let node_id_str = peer_str.split('@').next().unwrap_or(&peer_str);
                                        let address_str = peer_str.split('@').nth(1).map(|s| s.to_string());
                                        
                                        if let Ok(peer_endpoint_id) = node_id_str.parse::<EndpointId>() {
                                            let connect_result = if let Some(ref addr_str) = address_str {
                                                if let Ok(socket_addr) = addr_str.parse::<std::net::SocketAddr>() {
                                                    let endpoint_addr = iroh::EndpointAddr::from_parts(
                                                        peer_endpoint_id,
                                                        vec![iroh::TransportAddr::Ip(socket_addr)],
                                                    );
                                                    endpoint_clone.connect(endpoint_addr, iroh_gossip::ALPN).await
                                                } else {
                                                    endpoint_clone.connect(peer_endpoint_id, iroh_gossip::ALPN).await
                                                }
                                            } else {
                                                endpoint_clone.connect(peer_endpoint_id, iroh_gossip::ALPN).await
                                            };
                                            
                                            match connect_result {
                                                Ok(_conn) => {
                                                    log_info!("✓ Connected to peer {} from peer list", node_id_str);
                                                }
                                                Err(e) => {
                                                    log_warn!("Failed to connect to peer {}: {}", node_id_str, e);
                                                }
                                            }
                                            
                                            let _ = event_tx_clone.send(NodeEvent::PeerDiscovered {
                                                peer_id: node_id_str.to_string(),
                                                address: address_str,
                                            }).await;
                                        }
                                    }
                                }
                            }
                        }
                        Ok(GossipEvent::NeighborUp(peer_id)) => {
                            log_info!("📡 Peer discovery NeighborUp: {}", peer_id.fmt_short());
                            peer_registry_clone.write().register_connected_peer(peer_id.to_string());
                            let peer_count = peer_registry_clone.read().peer_count();
                            {
                                let mut state = shared_state_clone.write();
                                state.discovered_peers = peer_count;
                                state.connected_peers = peer_count;
                            }
                        }
                        Ok(GossipEvent::NeighborDown(peer_id)) => {
                            log_info!("📡 Peer discovery NeighborDown: {}", peer_id.fmt_short());
                        }
                        Ok(GossipEvent::Lagged) => {
                            log_warn!("📡 Peer discovery gossip lagged");
                        }
                        Err(e) => {
                            log_error!("📡 Peer discovery error: {}", e);
                        }
                    }
                }
            });
            }
            Err(e) => {
                log_error!(">>> PEER_DISCOVERY_TOPIC subscription FAILED: {:?}", e);
            }
        }

        // Subscribe to improved discovery topic (v2 postcard format) - matches cyberfly-rust-node
        // This allows mobile nodes to participate in the newer discovery protocol
        if let Ok(topic_handle) = gossip.subscribe(improved_discovery_topic_id, bootstrap_peers.clone()).await {
            let (sender, mut receiver) = topic_handle.split();
            *improved_discovery_sender.lock().await = Some(sender);
            
            let peer_registry_clone = peer_registry.clone();
            let shared_state_clone = shared_state.clone();
            let event_tx_clone = event_tx.clone();
            let endpoint_clone = endpoint.clone();
            let node_id_clone = node_id.clone();

            tokio::spawn(async move {
                log_info!("✓ Improved discovery (v2 postcard) listener started");
                while let Some(event) = receiver.next().await {
                    match event {
                        Ok(GossipEvent::Received(msg)) => {
                            // Try to decode postcard-serialized discovery message
                            // The upstream format is: SignedDiscoveryMessage { from: [u8;32], data: Vec<u8>, signature: [u8;64] }
                            // For now, we just track that we received something from this peer
                            let from_peer = msg.delivered_from.to_string();
                            
                            // Skip our own messages
                            if from_peer == node_id_clone {
                                continue;
                            }
                            
                            // Register peer from improved discovery
                            let is_new = peer_registry_clone.write().register_connected_peer(from_peer.clone());
                            
                            // Update peer counts
                            let peer_count = peer_registry_clone.read().peer_count();
                            {
                                let mut state = shared_state_clone.write();
                                state.discovered_peers = peer_count;
                                state.connected_peers = peer_count;
                            }
                            
                            if is_new {
                                log_info!("📡 Discovered peer via improved discovery (v2): {}", from_peer);
                                let _ = event_tx_clone.send(NodeEvent::PeerDiscovered {
                                    peer_id: from_peer.clone(),
                                    address: None,
                                }).await;
                                
                                // ACTIVELY CONNECT to this peer (like desktop node does)
                                if let Ok(peer_endpoint_id) = from_peer.parse::<EndpointId>() {
                                    // No address available from improved discovery, try DHT/relay
                                    match endpoint_clone.connect(peer_endpoint_id, iroh_gossip::ALPN).await {
                                        Ok(_conn) => {
                                            log_info!("✓ Connected to peer {} via improved discovery", from_peer);
                                        }
                                        Err(e) => {
                                            log_warn!("Failed to connect to peer {}: {}", from_peer, e);
                                        }
                                    }
                                }
                            }
                        }
                        Ok(GossipEvent::NeighborUp(peer_id)) => {
                            let peer_str = peer_id.to_string();
                            log_info!("Improved discovery: NeighborUp {}", peer_str);
                            peer_registry_clone.write().register_connected_peer(peer_str);
                            let peer_count = peer_registry_clone.read().peer_count();
                            {
                                let mut state = shared_state_clone.write();
                                state.discovered_peers = peer_count;
                                state.connected_peers = peer_count;
                            }
                        }
                        Ok(GossipEvent::NeighborDown(peer_id)) => {
                            log_info!("Improved discovery: NeighborDown {}", peer_id);
                        }
                        Ok(GossipEvent::Lagged) => {
                            log_warn!("Improved discovery gossip lagged");
                        }
                        Err(e) => {
                            log_warn!("Improved discovery gossip error: {}", e);
                        }
                    }
                }
            });
        }

        // Periodic announcement task
        let discovery_sender_announce = discovery_sender.clone();
        let peer_discovery_sender_announce = peer_discovery_sender.clone();
        let improved_discovery_sender_announce = improved_discovery_sender.clone();
        let node_id_announce = node_id.clone();
        let public_key_announce = public_key.clone();
        let signing_key_announce = signing_key.clone();
        let region_announce = region.clone();
        let peer_registry_announce = peer_registry.clone();

        tokio::spawn(async move {
            let mut interval = tokio::time::interval(Duration::from_secs(ANNOUNCE_INTERVAL_SECS));
            loop {
                interval.tick().await;
                
                // Send peer announcement
                let mut announcement = PeerAnnouncement::new(
                    node_id_announce.clone(),
                    public_key_announce.clone(),
                    None, // Mobile nodes typically don't have direct addresses
                    NodeCapabilities::mobile_node(),
                    region_announce.clone(),
                    Some(NODE_VERSION.to_string()),
                );
                announcement.sign(&signing_key_announce);
                
                let disc_msg = DiscoveryMessage::Announce(announcement);
                if let Some(sender) = discovery_sender_announce.lock().await.as_ref() {
                    let _ = sender.broadcast(Bytes::from(serde_json::to_vec(&disc_msg).unwrap())).await;
                }
                
                // Send peer list
                let peer_list = peer_registry_announce.read().get_peer_list_for_broadcast();
                if !peer_list.is_empty() {
                    let mut list_msg = PeerListAnnouncement::new(
                        node_id_announce.clone(),
                        public_key_announce.clone(),
                        peer_list,
                    );
                    list_msg.sign(&signing_key_announce);
                    
                    let disc_msg = DiscoveryMessage::PeerList(list_msg);
                    if let Some(sender) = peer_discovery_sender_announce.lock().await.as_ref() {
                        let _ = sender.broadcast(Bytes::from(serde_json::to_vec(&disc_msg).unwrap())).await;
                    }
                }
                
                // Also broadcast on improved discovery topic (v2 postcard format)
                // This uses postcard binary serialization matching cyberfly-rust-node EXACTLY
                // Desktop format from gossip_discovery.rs:
                //   DiscoveryNode { name, node_id: NodeId, count, region, capabilities }
                //   SignedDiscoveryMessage { from: [u8;32], data: Vec<u8>, signature: [u8;64] }
                if let Some(sender) = improved_discovery_sender_announce.lock().await.as_ref() {
                    // Match desktop's DiscoveryNode format EXACTLY
                    // Desktop uses EndpointId (NodeId) directly, not String
                    #[derive(serde::Serialize, serde::Deserialize)]
                    struct DiscoveryNodeV2 {
                        name: String,
                        node_id: iroh::EndpointId,  // Must be EndpointId, not String!
                        count: u32,
                        region: String,
                        capabilities: CapabilitiesV2,
                    }
                    
                    // Desktop's NodeCapabilities format
                    #[derive(serde::Serialize, serde::Deserialize)]
                    struct CapabilitiesV2 {
                        mqtt: bool,
                        streams: bool,
                        timeseries: bool,
                        geo: bool,
                        blobs: bool,
                    }
                    
                    // Desktop's SignedDiscoveryMessage format - uses Vec<u8> for serde compatibility
                    #[derive(serde::Serialize, serde::Deserialize)]
                    struct SignedDiscoveryMessageV2 {
                        from: Vec<u8>,       // ed25519 public key (32 bytes)
                        data: Vec<u8>,       // postcard-serialized DiscoveryNode
                        signature: Vec<u8>,  // ed25519 signature (64 bytes)
                    }
                    
                    // Parse our node_id string back to EndpointId
                    if let Ok(our_endpoint_id) = node_id_announce.parse::<iroh::EndpointId>() {
                        // We use a simple counter that increments each announcement
                        static ANNOUNCE_COUNT: std::sync::atomic::AtomicU32 = std::sync::atomic::AtomicU32::new(0);
                        let count = ANNOUNCE_COUNT.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
                        
                        let node = DiscoveryNodeV2 {
                            name: format!("cyberfly-mobile-{}", &node_id_announce[..8]),
                            node_id: our_endpoint_id,
                            count,
                            region: region_announce.clone().unwrap_or_else(|| "unknown".to_string()),
                            capabilities: CapabilitiesV2 {
                                mqtt: false,
                                streams: false,
                                timeseries: false,
                                geo: false,
                                blobs: true,
                            },
                        };
                        
                        // Serialize inner data with postcard
                        if let Ok(data) = postcard::to_stdvec(&node) {
                            // Sign the data with ed25519
                            use ed25519_dalek::Signer;
                            let signature = signing_key_announce.sign(&data);
                            
                            // Create signed message with Vec<u8> types (serde compatible)
                            let signed_msg = SignedDiscoveryMessageV2 {
                                from: signing_key_announce.verifying_key().to_bytes().to_vec(),
                                data,
                                signature: signature.to_bytes().to_vec(),
                            };
                            
                            // Serialize the signed message with postcard
                            if let Ok(encoded) = postcard::to_stdvec(&signed_msg) {
                                match sender.broadcast(Bytes::from(encoded)).await {
                                    Ok(_) => log_info!("📡 Broadcast v2 discovery (postcard+ed25519)"),
                                    Err(e) => log_warn!("Failed to broadcast v2 discovery: {}", e),
                                }
                            }
                        }
                    }
                }
                
                // Cleanup expired peers
                peer_registry_announce.write().cleanup_expired();
            }
        });

        // Initial sync request - request full sync from bootstrap peers after a short delay
        let sync_sender_initial = sync_sender.clone();
        let node_id_sync = node_id.clone();
        tokio::spawn(async move {
            // Wait a bit for connections to establish
            tokio::time::sleep(Duration::from_secs(5)).await;
            
            log_info!("📤 Sending initial sync request to bootstrap peers...");
            let sync_request = SyncMessage::SyncRequest {
                requester: node_id_sync,
                since_timestamp: None, // Full sync
            };
            
            if let Some(sender) = sync_sender_initial.lock().await.as_ref() {
                if let Ok(payload) = serde_json::to_vec(&sync_request) {
                    match sender.broadcast(Bytes::from(payload)).await {
                        Ok(_) => log_info!("✓ Initial sync request sent"),
                        Err(e) => log_error!("Failed to send initial sync request: {}", e),
                    }
                }
            }
        });

        // Bootstrap connection monitor - check and reconnect if isolated
        let endpoint_monitor = endpoint.clone();
        let gossip_monitor = gossip.clone();
        let bootstrap_peers_monitor = bootstrap_peers.clone();
        let shared_state_monitor = shared_state.clone();
        let node_id_monitor = node_id.clone();
        tokio::spawn(async move {
            log_info!("🔍 Bootstrap connection monitor started");
            let mut check_interval = tokio::time::interval(Duration::from_secs(30));
            let mut consecutive_isolation_count = 0u32;
            
            loop {
                check_interval.tick().await;
                
                let state = shared_state_monitor.read().clone();
                let connected = state.connected_peers;
                let msgs = state.gossip_messages_received;
                
                // Check relay status - need to hold addr to prevent temporary drop
                let my_addr = endpoint_monitor.addr();
                let relay_urls: Vec<_> = my_addr.relay_urls().cloned().collect();
                let relay_status = relay_urls.first().map(|r| r.to_string()).unwrap_or_else(|| "None".to_string());
                log_info!("🔍 Connection check: connected={}, gossip_msgs={}, relay={}", connected, msgs, relay_status);
                
                // Get connection count from endpoint - use direct addresses as proxy
                let direct_addrs_count = my_addr.ip_addrs().count();
                log_info!("🔍 Endpoint has {} direct addresses, {} relay URLs", direct_addrs_count, relay_urls.len());
                
                // Check if we're isolated (no gossip neighbors)
                // In HyParView, we need NeighborUp events to be "connected" to the overlay
                let is_isolated = connected == 0 || (msgs == 0 && relay_urls.is_empty());
                
                if is_isolated {
                    consecutive_isolation_count += 1;
                    log_warn!("🔍 Node appears ISOLATED ({}/3 checks)", consecutive_isolation_count);
                    
                    // After 3 consecutive isolated checks, try to reconnect
                    if consecutive_isolation_count >= 3 {
                        log_warn!("🔍 Attempting bootstrap reconnection...");
                        
                        for peer_id in &bootstrap_peers_monitor {
                            // Get default bootstrap address
                            let socket_addr: std::net::SocketAddr = "67.211.219.34:31001".parse().unwrap();
                            
                            // Try relay-assisted connection
                            if let Some(relay_url) = relay_urls.first() {
                                log_info!("🔍 Reconnecting to {} via relay {}", peer_id.fmt_short(), relay_url);
                                
                                let relay_addr = iroh::EndpointAddr::from_parts(
                                    *peer_id,
                                    vec![
                                        iroh::TransportAddr::Ip(socket_addr),
                                        iroh::TransportAddr::Relay((*relay_url).clone()),
                                    ],
                                );
                                
                                match tokio::time::timeout(
                                    Duration::from_secs(15),
                                    endpoint_monitor.connect(relay_addr, iroh_gossip::ALPN)
                                ).await {
                                    Ok(Ok(conn)) => {
                                        log_info!("🔍 ✓ Reconnected to bootstrap {} (remote: {:?})", 
                                            peer_id.fmt_short(), conn.remote_id());
                                        
                                        // Re-subscribe to data topic to rejoin HyParView
                                        log_info!("🔍 Re-joining gossip topics...");
                                        let data_topic_id = TopicId::from_bytes(*DATA_TOPIC);
                                        let _ = gossip_monitor.subscribe(data_topic_id, vec![*peer_id]).await;
                                    }
                                    Ok(Err(e)) => {
                                        log_warn!("🔍 Reconnect failed: {}", e);
                                    }
                                    Err(_) => {
                                        log_warn!("🔍 Reconnect timed out");
                                    }
                                }
                            } else {
                                log_warn!("🔍 No relay URL available for reconnection");
                            }
                        }
                        
                        consecutive_isolation_count = 0; // Reset after reconnect attempt
                    }
                } else {
                    consecutive_isolation_count = 0;
                    log_info!("🔍 Node is connected (not isolated)");
                }
            }
        });

        // Handle commands
        info!(">>> run_node: entering command loop");
        while let Some(cmd) = command_rx.recv().await {
            info!(">>> run_node: received command");
            match cmd {
                NodeCommand::Stop(response) => {
                    info!("Stopping node");
                    // Flush storage to disk before stopping
                    if let Err(e) = storage.flush() {
                        error!("Failed to flush storage on stop: {}", e);
                    } else {
                        info!("Storage flushed to disk successfully");
                    }
                    let _ = event_tx.send(NodeEvent::Stopped).await;
                    let _ = router.shutdown().await;
                    let _ = response.send(());
                    break;
                }
                NodeCommand::GetStatus(response) => {
                    let sync_stats = sync_manager.get_stats().await;
                    let state = shared_state.read().clone();
                    let status = NodeStatus {
                        is_running: true,
                        node_id: Some(node_id.clone()),
                        connected_peers: state.connected_peers,
                        discovered_peers: state.discovered_peers,
                        uptime_seconds: 0,
                        gossip_messages_received: state.gossip_messages_received,
                        storage_size_bytes: storage.size_bytes().unwrap_or(0),
                        total_keys: storage.key_count().unwrap_or(0) as u64,
                        total_operations: sync_stats.total_operations as u64,
                        sync_operations: sync_stats.total_operations,
                        latency_requests_sent: state.latency_requests_sent,
                        latency_responses_received: state.latency_responses_received,
                    };
                    let _ = response.send(status);
                }
                NodeCommand::GetPeers(response) => {
                    let peers: Vec<DiscoveredPeer> = peer_registry
                        .read()
                        .get_all_peers()
                        .into_iter()
                        .cloned()
                        .collect();
                    let _ = response.send(peers);
                }
                NodeCommand::SendGossip { topic: _, message } => {
                    let msg = GossipMessage::Custom {
                        from: node_id.clone(),
                        content: message,
                        timestamp: std::time::SystemTime::now()
                            .duration_since(std::time::UNIX_EPOCH)
                            .unwrap()
                            .as_secs(),
                    };
                    if let Some(sender) = data_sender.lock().await.as_ref() {
                        let _ = sender.broadcast(Bytes::from(serde_json::to_vec(&msg).unwrap())).await;
                    }
                }
                NodeCommand::SendLatencyRequest { peer_id: _, response } => {
                    // Increment latency requests sent counter
                    shared_state.write().latency_requests_sent += 1;
                    
                    // Create and send latency request
                    let mut request = LatencyRequest::new(node_id.clone(), public_key.clone());
                    request.sign(&signing_key);
                    
                    let request_id = request.request_id.clone();
                    let sent_at = request.sent_at;
                    
                    // Store pending request
                    pending_latency.write().insert(request_id.clone(), PendingLatencyRequest {
                        sent_at,
                        callback: None,
                    });
                    
                    let msg = GossipMessage::LatencyRequest {
                        request_id,
                        from_node_id: request.from_node_id,
                        public_key: request.public_key,
                        sent_at: request.sent_at,
                        signature: request.signature,
                    };
                    
                    if let Some(sender) = data_sender.lock().await.as_ref() {
                        let _ = sender.broadcast(Bytes::from(serde_json::to_vec(&msg).unwrap())).await;
                    }
                    
                    // For simplicity, we return immediately and rely on events
                    let _ = response.send(Err("Latency request sent, check events for response".to_string()));
                }
                NodeCommand::StoreData { db_name, key, value, public_key: pk, signature } => {
                    // Store locally
                    if let Err(e) = storage.put(&db_name, &key, &value) {
                        error!("Failed to store data: {}", e);
                        continue;
                    }
                    // Flush immediately to ensure persistence
                    let _ = storage.flush();
                    
                    // Create sync operation and broadcast
                    let value_str = String::from_utf8_lossy(&value).to_string();
                    let op = SignedOperation::new(
                        db_name.clone(),
                        key.clone(),
                        value_str,
                        "String".to_string(),
                        pk,
                        signature,
                    );
                    
                    // Add to sync store
                    let _ = sync_manager.sync_store().add_operation_unverified(op.clone()).await;
                    
                    // Broadcast to sync topic
                    let sync_msg = sync_manager.create_operation_message(op);
                    if let Some(sender) = sync_sender.lock().await.as_ref() {
                        if let Ok(payload) = serde_json::to_vec(&sync_msg) {
                            let _ = sender.broadcast(Bytes::from(payload)).await;
                        }
                    }
                }
                NodeCommand::GetData { db_name, key, response } => {
                    let data = storage.get(&db_name, &key).ok().flatten();
                    let _ = response.send(data);
                }
                NodeCommand::RequestSync { since_timestamp } => {
                    let sync_request = sync_manager.create_sync_request(since_timestamp);
                    if let Some(sender) = sync_sender.lock().await.as_ref() {
                        if let Ok(payload) = serde_json::to_vec(&sync_request) {
                            let _ = sender.broadcast(Bytes::from(payload)).await;
                        }
                    }
                }
            }
        }
    }

    /// Get node ID
    pub fn node_id(&self) -> &str {
        &self.node_id
    }

    /// Get public key
    pub fn public_key(&self) -> &str {
        &self.public_key
    }

    /// Get node status - reads from shared state, no async needed
    pub fn get_status_sync(&self) -> NodeStatus {
        let state = self.shared_state.read().clone();
        let uptime = self.start_time.elapsed().as_secs();
        
        // Get peer count directly from peer_registry for consistency with get_peers_sync
        let peer_count = self.peer_registry.read().peer_count();
        
        log_info!(">>> get_status_sync: uptime={}, connected={}, discovered={}, gossip_msgs={}", 
            uptime, peer_count, peer_count, state.gossip_messages_received);
        NodeStatus {
            is_running: state.is_running,
            node_id: Some(self.node_id.clone()),
            connected_peers: peer_count,
            discovered_peers: peer_count,
            uptime_seconds: uptime,
            gossip_messages_received: state.gossip_messages_received,
            storage_size_bytes: self.storage.size_bytes().unwrap_or(0),
            total_keys: self.storage.key_count().unwrap_or(0) as u64,
            total_operations: 0, // sync_stats not tracked in shared state
            sync_operations: state.sync_operations,
            latency_requests_sent: state.latency_requests_sent,
            latency_responses_received: state.latency_responses_received,
        }
    }

    /// Get node status (async - kept for compatibility, now uses sync version)
    pub async fn get_status(&self) -> Result<NodeStatus> {
        Ok(self.get_status_sync())
    }

    /// Get discovered peers - reads from shared state
    pub fn get_peers_sync(&self) -> Vec<DiscoveredPeer> {
        self.peer_registry
            .read()
            .get_all_peers()
            .into_iter()
            .cloned()
            .collect()
    }

    /// Get discovered peers (async - kept for compatibility)
    pub async fn get_peers(&self) -> Result<Vec<DiscoveredPeer>> {
        Ok(self.get_peers_sync())
    }

    /// Send gossip message
    pub async fn send_gossip(&self, topic: String, message: String) -> Result<()> {
        self.command_tx.send(NodeCommand::SendGossip { topic, message }).await?;
        Ok(())
    }

    /// Send latency request
    pub async fn send_latency_request(&self, peer_id: String) -> Result<u64, String> {
        let (tx, rx) = oneshot::channel();
        self.command_tx.send(NodeCommand::SendLatencyRequest { peer_id, response: tx }).await
            .map_err(|e| e.to_string())?;
        rx.await.map_err(|e| e.to_string())?
    }

    /// Store data with signature
    pub async fn store_data(
        &self,
        db_name: String,
        key: String,
        value: Vec<u8>,
        public_key: String,
        signature: String,
    ) -> Result<()> {
        self.command_tx.send(NodeCommand::StoreData { 
            db_name, key, value, public_key, signature 
        }).await?;
        Ok(())
    }

    /// Get data
    pub async fn get_data(&self, db_name: String, key: String) -> Result<Option<Vec<u8>>> {
        let (tx, rx) = oneshot::channel();
        self.command_tx.send(NodeCommand::GetData { db_name, key, response: tx }).await?;
        Ok(rx.await?)
    }

    /// Request sync from peers
    pub async fn request_sync(&self, since_timestamp: Option<i64>) -> Result<()> {
        self.command_tx.send(NodeCommand::RequestSync { since_timestamp }).await?;
        Ok(())
    }

    /// Take event receiver (can only be called once)
    pub fn take_event_receiver(&self) -> Option<mpsc::Receiver<NodeEvent>> {
        self.event_rx.write().take()
    }

    /// Stop the node
    pub async fn stop(&self) -> Result<()> {
        let (tx, rx) = oneshot::channel();
        self.command_tx.send(NodeCommand::Stop(tx)).await?;
        rx.await?;
        Ok(())
    }

    /// List all databases
    pub fn list_databases(&self) -> Result<Vec<String>> {
        self.storage.list_databases()
    }

    /// List all keys in a database
    pub fn list_keys(&self, db_name: &str) -> Result<Vec<String>> {
        self.storage.list_keys(db_name)
    }

    /// Get all entries from a database
    pub async fn get_all_entries(&self, db_name: &str) -> Result<Vec<crate::api::DbEntryDto>> {
        let keys = self.storage.list_keys(db_name)?;
        let mut entries = Vec::new();
        
        for key in keys {
            if let Some(value_bytes) = self.storage.get(db_name, &key)? {
                let value = String::from_utf8_lossy(&value_bytes).to_string();
                entries.push(crate::api::DbEntryDto {
                    db_name: db_name.to_string(),
                    key,
                    value,
                    value_bytes,
                });
            }
        }
        
        Ok(entries)
    }

    /// Get all entries from all databases
    pub async fn get_all_data(&self) -> Result<Vec<crate::api::DbEntryDto>> {
        let db_names = self.storage.list_databases()?;
        let mut all_entries = Vec::new();
        
        for db_name in db_names {
            let entries = self.get_all_entries(&db_name).await?;
            all_entries.extend(entries);
        }
        
        Ok(all_entries)
    }

    /// Delete a key from a database
    pub async fn delete_data(&self, db_name: &str, key: &str) -> Result<()> {
        self.storage.delete(db_name, key)
    }
}
