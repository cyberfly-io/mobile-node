use std::sync::Arc;
use std::time::Duration;

use chrono::Utc;
use dashmap::DashMap;
use iroh::EndpointId;
use tokio::sync::Mutex;
use std::sync::atomic::{AtomicU32, Ordering};
use std::sync::Arc as StdArc;
use rand::Rng;
use iroh::{Endpoint, protocol::Router};
use iroh_gossip::net::Gossip;
use std::net::SocketAddr;

/// Minimal NetworkResilience helper for mobile crate.
/// Holds shared backoff state and exposes small helpers used by node.rs.
pub struct NetworkResilience {
    // backoff map: EndpointId -> (failure_count, next_allowed_time)
    peer_backoff: Arc<DashMap<EndpointId, (u32, chrono::DateTime<chrono::Utc>)>>,
    // internal state placeholder for future resilience features
    _state: Mutex<u8>,
    // connection attempts counter for current cycle
    connection_attempts: StdArc<AtomicU32>,
    // maximum allowed connection attempts per cycle
    max_connections_per_cycle: u32,
    // cycle length in seconds
    cycle_secs: u64,
}

impl NetworkResilience {
    pub fn new() -> Self {
        Self {
            peer_backoff: Arc::new(DashMap::new()),
            _state: Mutex::new(0),
            connection_attempts: StdArc::new(AtomicU32::new(0)),
            max_connections_per_cycle: 8,
            cycle_secs: 30,
        }
    }

    /// Return a clone of the shared backoff map.
    pub fn peer_backoff(&self) -> Arc<DashMap<EndpointId, (u32, chrono::DateTime<chrono::Utc>)>> {
        self.peer_backoff.clone()
    }

    /// Start a background maintenance task (stub).
    pub fn start_background(self: Arc<Self>) {
        tokio::spawn(async move {
            loop {
                // reset per-cycle counters
                tokio::time::sleep(Duration::from_secs(self.cycle_secs)).await;
                self.connection_attempts.store(0, Ordering::SeqCst);
            }
        });
    }

    /// Return true if a new connection attempt is allowed in the current cycle.
    /// This increments the internal counter when allowed.
    pub fn allow_connection_attempt(&self) -> bool {
        let prev = self.connection_attempts.fetch_add(1, Ordering::SeqCst);
        if prev < self.max_connections_per_cycle {
            true
        } else {
            // revert increment
            self.connection_attempts.fetch_sub(1, Ordering::SeqCst);
            false
        }
    }

    /// Start bootstrap reconnect tasks: periodically attempt to connect to the
    /// provided bootstrap peers using the shared backoff map and jitter.
    pub fn start_bootstrap_reconnects(self: Arc<Self>, endpoint: Endpoint, bootstrap_strings: Vec<String>) {
        let pb = self.peer_backoff.clone();
        let res_arc = self.clone();
        tokio::spawn(async move {
            loop {
                for peer_str in &bootstrap_strings {
                    if let Some((node_id_str, addr_opt)) = peer_str.split_once('@') {
                        if let Ok(peer_id) = node_id_str.parse::<EndpointId>() {
                            // Check backoff
                            if let Some(back) = pb.get(&peer_id) {
                                let (_fails, next_allowed) = *back.value();
                                if Utc::now() < next_allowed {
                                    continue;
                                }
                            }

                            // Respect per-cycle connection limits
                            if !res_arc.allow_connection_attempt() {
                                // skip this attempt due to cycle limit
                                continue;
                            }

                            // jitter per connect attempt to avoid stampedes
                            let jitter_ms: u64 = {
                                let mut rng = rand::thread_rng();
                                rng.gen_range(0..=1000)
                            };
                            tokio::time::sleep(Duration::from_millis(jitter_ms)).await;

                            // Build endpoint address if parseable
                            let res = if let Some(addr_str) = Some(addr_opt.to_string()) {
                                match addr_str.parse::<SocketAddr>() {
                                    Ok(socket_addr) => {
                                        let endpoint_addr = iroh::EndpointAddr::from_parts(
                                            peer_id,
                                            vec![iroh::TransportAddr::Ip(socket_addr)],
                                        );
                                        tokio::time::timeout(Duration::from_secs(10), endpoint.connect(endpoint_addr, iroh_gossip::ALPN)).await
                                    }
                                    Err(_) => {
                                        tokio::time::timeout(Duration::from_secs(10), endpoint.connect(peer_id, iroh_gossip::ALPN)).await
                                    }
                                }
                            } else {
                                tokio::time::timeout(Duration::from_secs(10), endpoint.connect(peer_id, iroh_gossip::ALPN)).await
                            };

                            match res {
                                Ok(Ok(_conn)) => {
                                    pb.remove(&peer_id);
                                }
                                _ => {
                                    // increase backoff on failure
                                    let mut failures = 1u32;
                                    if let Some(mut entry) = pb.get_mut(&peer_id) {
                                        failures = entry.value_mut().0.saturating_add(1);
                                    }
                                    let base_secs = 2u64;
                                    let max_secs = 300u64;
                                    let backoff_secs = base_secs.checked_shl((failures - 1) as u32).unwrap_or(max_secs).min(max_secs);
                                    let next_allowed = Utc::now() + chrono::Duration::seconds(backoff_secs as i64);
                                    pb.insert(peer_id, (failures, next_allowed));
                                }
                            }
                        }
                    }
                }

                // Wait before next round
                tokio::time::sleep(Duration::from_secs(30)).await;
            }
        });
    }
}
