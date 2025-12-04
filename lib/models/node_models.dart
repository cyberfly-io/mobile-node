/// Node configuration for starting the Rust node
class NodeConfig {
  final String dataDir;
  final List<String> bootstrapPeers;

  /// Wallet secret key (hex-encoded, 32 bytes / 64 hex chars)
  /// If provided, the node will use this key instead of generating one
  final String? walletSecretKey;

  NodeConfig({
    required this.dataDir,
    this.bootstrapPeers = const [],
    this.walletSecretKey,
  });
}

// Note: NodeInfo, NodeStatus, and PeerInfo are now defined in node_service.dart
// and imported from the Rust FFI bindings
