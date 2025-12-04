# Cyberfly Flutter Mobile Node

A Flutter mobile application with Rust native library for P2P networking using Iroh, Gossip protocol, and Sled storage. Compatible with the [cyberfly-rust-node](https://github.com/cyberfly-io/cyberfly-rust-node) network.

## Features

- **Iroh P2P Networking**: QUIC transport with relay support, DHT discovery, mDNS local discovery
- **Gossip Protocol**: Peer discovery and messaging via compatible topic channels
- **Sled Database**: Embedded B-tree storage with replication via gossip
- **Latency Check**: URL latency measurement with gossip publication
- **Ed25519 Cryptography**: Secure signatures for operations
- **Beautiful UI**: Animated cyberpunk-style interface with real-time stats
- **Background Service**: Node runs in foreground service even when app is closed

## Project Structure

```
lib/                  # Flutter Dart code
├── main.dart         # App entry point
├── models/           # Data models
├── screens/          # UI screens
├── services/         # Business logic
└── widgets/          # Reusable UI components

rust/                 # Rust native library (via flutter_rust_bridge)
├── src/
│   ├── lib.rs        # Module declarations
│   ├── api.rs        # FFI API for Flutter
│   ├── node.rs       # Core P2P node implementation
│   ├── storage.rs    # Sled database wrapper
│   ├── sync.rs       # Database replication protocol
│   └── crypto.rs     # Ed25519 cryptography
└── Cargo.toml        # Rust dependencies
```

## Prerequisites

- Flutter SDK 3.x
- Rust toolchain (install via [rustup](https://rustup.rs/))
- flutter_rust_bridge_codegen

## Setup

### 1. Install Dependencies

```bash
# Install Flutter dependencies
flutter pub get

# Install flutter_rust_bridge codegen
cargo install flutter_rust_bridge_codegen
```

### 2. Generate FFI Bindings

```bash
flutter_rust_bridge_codegen generate
```

### 3. Build for Platforms

```bash
# Android
flutter build apk

# iOS
flutter build ios
```

## Development

### Running the App

```bash
flutter run
```

### Building Rust Library

```bash
cd rust
cargo build --release
```

### Regenerating Bindings

After modifying API in `rust/src/api.rs`:

```bash
flutter_rust_bridge_codegen generate
```

## Compatible Network

This app uses the same gossip topics as the reference implementation:

- **Peer List Topic**: `decentralized-peer-list-v1-iroh!`
- **Discovery Topic**: `decentralized-db-discovery-iroh!`

Bootstrap Peer: `04b754ba2a3da0970d72d08b8740fb2ad96e63cf8f8bef6b7f1ab84e5b09a7f8@67.211.219.34:31001`

## Stats Displayed

- **Connected Peers**: Active peer connections
- **Discovered Peers**: Peers found via gossip discovery
- **Storage Usage**: Sled database size on disk
- **Gossip Messages**: Received message count
- **Uptime**: Node running duration

## License

MIT
