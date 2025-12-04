# Cyberfly Flutter Mobile Node

A Flutter mobile application with Rust native library for P2P networking using Iroh, Gossip protocol, and Sled storage. Compatible with the [cyberfly-rust-node](https://github.com/cyberfly-io/cyberfly-rust-node) network.

## Features

- **Iroh P2P Networking**: QUIC transport with relay support, DHT discovery, mDNS local discovery
- **Gossip Protocol**: Peer discovery and messaging via compatible topic channels
- **Sled Database**: Embedded B-tree storage with replication via gossip
- **Latency Check**: URL latency measurement with gossip publication
- **Ed25519 Cryptography**: Secure signatures for operations
- **Beautiful UI**: Animated cyberpunk-style interface with real-time stats

## Project Structure

```
lib/                  # Flutter Dart code
├── main.dart         # App entry point
├── models/           # Data models
├── screens/          # UI screens
├── services/         # Business logic (node_service_rinf.dart)
├── src/bindings/     # Generated rinf bindings
└── widgets/          # Reusable UI components

native/hub/           # Rust native library (via rinf)
├── src/
│   ├── lib.rs        # Module declarations & rinf entry
│   ├── signals.rs    # Dart<->Rust signal definitions
│   ├── handlers.rs   # Signal handlers
│   ├── node.rs       # Core P2P node implementation
│   ├── storage.rs    # Sled database wrapper
│   ├── sync.rs       # Database replication protocol
│   ├── gossip.rs     # Gossip message types
│   ├── gossip_discovery.rs # Improved peer discovery (postcard + ed25519)
│   ├── crypto.rs     # Ed25519 cryptography
│   └── latency.rs    # URL latency checking
└── Cargo.toml        # Rust dependencies
```

## Prerequisites

- Flutter SDK 3.x
- Rust toolchain (install via [rustup](https://rustup.rs/))
- rinf CLI

## Setup

### 1. Install Dependencies

```bash
# Install Flutter dependencies
flutter pub get

# Install rinf CLI
cargo install rinf_cli
```

### 2. Generate Dart Bindings

```bash
# Generate Dart bindings from Rust signal definitions
rinf gen
```

### 3. Build for Platforms

```bash
# Android
flutter build apk

# iOS
flutter build ios

# macOS (for desktop testing)
flutter build macos
```

## Development

### Running the App

```bash
flutter run
```

### Building Rust Library

```bash
cd native/hub
cargo build --release
```

### Regenerating Bindings

After modifying signal definitions in `native/hub/src/signals.rs`:

```bash
rinf gen
```

## Compatible Network

This app uses the same gossip topics as the reference implementation:

- **Data Topic**: `decentralized-db-data-v1-iroh!!!`
- **Sync Topic**: `decentralized-db-sync-v1-iroh!!!`
- **Discovery Topic**: `decentralized-db-discovery-iroh!`
- **Improved Discovery**: `cyberfly-discovery-v2-postcard!!` (postcard + ed25519 signed)

Bootstrap Peer: `04b754ba2a3da0970d72d08b8740fb2ad96e63cf8f8bef6b7f1ab84e5b09a7f8@67.211.219.34:31001`

## Stats Displayed

- **Connected Peers**: Active peer connections
- **Discovered Peers**: Peers found via gossip discovery
- **Storage Usage**: Sled database size on disk
- **Gossip Messages**: Received message count
- **Uptime**: Node running duration
- **Total Operations**: Synced database operations

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter UI                            │
│  ┌─────────────┐  ┌────────────┐  ┌──────────────────┐  │
│  │ HomeScreen  │  │ StatCard   │  │ AnimatedBackground│  │
│  └──────┬──────┘  └────────────┘  └──────────────────┘  │
│         │                                                │
│  ┌──────▼──────────┐                                    │
│  │ NodeServiceRinf │  ◄── rinf signals ──►              │
│  └──────┬──────────┘                                    │
└─────────┼───────────────────────────────────────────────┘
          │ (DartSignal / RustSignal)
┌─────────▼───────────────────────────────────────────────┐
│                    Rust Native Library                   │
│  ┌──────────┐  ┌─────────┐  ┌────────┐  ┌───────────┐  │
│  │ Handlers │──│  Node   │──│ Gossip │──│   Sync    │  │
│  └──────────┘  └─────────┘  └────────┘  └───────────┘  │
│       │             │            │            │         │
│  ┌────▼────┐   ┌────▼────┐  ┌────▼────┐  ┌────▼────┐  │
│  │ Signals │   │  Iroh   │  │ Topics  │  │  Sled   │  │
│  │(bincode)│   │Endpoint │  │Discovery│  │   DB    │  │
│  └─────────┘   └─────────┘  └─────────┘  └─────────┘  │
└─────────────────────────────────────────────────────────┘
```

## Signal Types

### Dart → Rust (DartSignal)
- `StartNodeRequest` - Start the P2P node
- `StopNodeRequest` - Stop the node
- `GetNodeStatusRequest` - Get current status
- `GetPeersRequest` - Get connected peers
- `GetOperationsRequest` - Get database operations

### Rust → Dart (RustSignal)
- `NodeStartedResponse` - Node started successfully
- `NodeStatusResponse` - Current node status
- `PeersListResponse` - List of peers
- `OperationsListResponse` - Database operations
- `LogMessageEvent` - Log messages from Rust

## License

MIT
