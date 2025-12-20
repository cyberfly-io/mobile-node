//! Cyberfly Mobile Node - Rust Library
//! 
//! P2P networking using Iroh with gossip protocol and sled storage.
//! Implements peer discovery, sync, and latency measurement matching cyberfly-rust-node.

mod api;
mod crypto;
mod discovery;
mod network_resilience;
mod node;
mod storage;
mod sync;
mod frb_generated;

pub use api::*;

// Re-export for external use
pub use crypto::{sign_message, verify_signature, generate_keypair};
pub use discovery::{PeerRegistry, PeerAnnouncement, DiscoveredPeer, NodeCapabilities};
pub use sync::{SyncManager, SyncMessage, SignedOperation, SyncStats};
pub use node::{CyberflyNode, NodeStatus, NodeEvent, GossipMessage};
pub use storage::Storage;
pub use network_resilience::NetworkResilience;
