# Cyberfly Flutter Mobile Node

A Flutter mobile application with Rust native library for P2P networking using Iroh, Gossip protocol, and Sled storage.

## Project Structure

- `lib/` - Flutter Dart code
- `rust/` - Rust native library with flutter_rust_bridge
- `android/` - Android platform code
- `ios/` - iOS platform code

## Features

- Iroh P2P networking with QUIC transport
- Gossip protocol for peer discovery and messaging
- Sled embedded database with sync/replication
- Latency check and publish via gossip
- Ed25519 cryptographic signatures

## Development

### Prerequisites
- Flutter SDK 3.x
- Rust toolchain (rustup)
- flutter_rust_bridge_codegen

### Build Commands
```bash
# Generate FFI bindings
flutter_rust_bridge_codegen generate

# Build for Android
flutter build apk

# Build for iOS
flutter build ios
```
