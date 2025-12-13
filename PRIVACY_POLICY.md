# Privacy Policy for Cyberfly Node

**Last Updated: December 13, 2025**

## Introduction

Cyberfly Node ("we", "our", or "the app") is a decentralized peer-to-peer (P2P) mobile node application developed by Cyberfly.io. This Privacy Policy explains how we handle information when you use our application.

## Information We Collect

### Locally Stored Data

The Cyberfly Node app stores the following information **locally on your device only**:

1. **Cryptographic Keys**: Ed25519 key pairs generated for node identity and network authentication. These keys never leave your device.

2. **Wallet Data**: If you create or import a wallet, the mnemonic phrase and derived keys are stored encrypted on your device using secure storage.

3. **Network Data**: P2P discovery information, peer connection data, and sync metadata stored in a local embedded database (Sled).

4. **Preferences**: App settings and preferences stored locally.

### Network Communications

When operating as a P2P node:

- Your device communicates directly with other peers in the Cyberfly network
- Your node's public key and network address are shared with connected peers
- Gossip protocol messages may include your node's public identifier
- Latency check data is published to the network for node health monitoring

### Data We Do NOT Collect

- We do **not** collect personal information
- We do **not** track your location
- We do **not** access your contacts, camera, or microphone
- We do **not** send any data to centralized servers operated by us
- We do **not** use analytics or tracking services

## How We Use Information

All data processing occurs locally on your device for the purpose of:

- Operating a P2P network node
- Maintaining peer connections
- Synchronizing distributed data
- Managing your cryptocurrency wallet (if used)
- Running background services to keep your node online

## Data Storage and Security

- All sensitive data (wallet keys, node identity) is encrypted using platform-secure storage
- The app uses Ed25519 cryptographic signatures for network authentication
- Data stored in the local Sled database is only accessible by the app

## Third-Party Services

The app connects to:

1. **Iroh Relay Servers**: For NAT traversal and peer discovery (operated by n0.computer)
2. **Kadena Blockchain**: For wallet transactions (public blockchain network)

These services may have their own privacy policies.

## Permissions Used

| Permission | Purpose |
|------------|---------|
| Internet | Required for P2P networking and blockchain access |
| Network State | Check connectivity before network operations |
| Foreground Service | Run the P2P node continuously in background |
| Wake Lock | Keep node active during data synchronization |
| Boot Completed | Optionally restart node after device reboot |
| Notifications | Display node status and connection information |

## Data Retention

- Data remains on your device until you uninstall the app or manually clear data
- Deleting the app removes all locally stored data
- Network-published data (like node discovery broadcasts) is transient and not permanently stored

## Children's Privacy

This app is not intended for children under 13. We do not knowingly collect data from children.

## Your Rights

Since all data is stored locally on your device:

- You have full control over your data
- You can delete all data by uninstalling the app
- You can export your wallet backup at any time
- No account or registration is required

## Changes to This Policy

We may update this Privacy Policy. Changes will be posted with an updated "Last Updated" date.

## Contact Us

For questions about this Privacy Policy:

- GitHub: https://github.com/cyberfly-io
- Website: https://cyberfly.io

## Open Source

Cyberfly Node is open source. You can review the code at:
https://github.com/cyberfly-io/mobile-node
