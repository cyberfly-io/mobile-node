# Google Play Data Safety Declaration Guide

This document helps you fill out the Data Safety section in Google Play Console.

## Data Safety Form Responses

### Overview

When filling out the Data Safety form in Google Play Console, use the following responses:

---

## Does your app collect or share any of the required user data types?

**Answer: Yes**

---

## Data Collection Details

### 1. Device or other IDs

**Collected: Yes**

- **Data type**: Device or other IDs
- **Is this data collected, shared, or both?**: Collected
- **Is this data processed ephemerally?**: No
- **Is this data required or optional?**: Required
- **Why is this data collected?**: App functionality
- **Description**: The app generates a cryptographic node ID (Ed25519 public key) for P2P network identification. This is not linked to device identifiers but is unique to the app installation.

### 2. App activity - App interactions

**Collected: No** - We don't track app interactions

### 3. Financial info

**Collected: Yes** (if wallet feature is used)

- **Data type**: Other financial info
- **Is this data collected, shared, or both?**: Collected only (stored locally)
- **Is this data processed ephemerally?**: No
- **Is this data required or optional?**: Optional (only if user creates wallet)
- **Why is this data collected?**: App functionality
- **Description**: Cryptocurrency wallet addresses and transaction data stored locally for Kadena blockchain interactions.

---

## Data Sharing Details

### Is any user data shared with third parties?

**Answer: Yes** (network data is shared with P2P peers)

**Third parties receiving data:**
- Other Cyberfly network peers (decentralized, no central server)
- Iroh relay servers for NAT traversal

**What data is shared:**
- Node public key (cryptographic identifier)
- Network address information
- Gossip protocol messages

**Purpose:** App functionality (P2P networking)

---

## Security Practices

### Is all user data encrypted in transit?

**Answer: Yes**

All P2P communications use QUIC protocol with TLS encryption.

### Do you provide a way for users to request data deletion?

**Answer: Yes**

Users can delete all data by:
1. Uninstalling the app
2. Clearing app data in device settings

### Is your app compliant with the Children's Online Privacy Protection Act (COPPA)?

**Answer: Yes**

The app does not:
- Target children under 13
- Collect personal information from children
- Include child-directed content

---

## Data Types Summary Table

| Data Type | Collected | Shared | Purpose |
|-----------|-----------|--------|---------|
| Device IDs | No | No | - |
| Crash logs | No | No | - |
| Performance diagnostics | No | No | - |
| Other app activity | No | No | - |
| Location | No | No | - |
| Contacts | No | No | - |
| SMS/Call logs | No | No | - |
| Photos/Videos | No | No | - |
| Audio | No | No | - |
| Files | No | No | - |
| Calendar | No | No | - |
| Email | No | No | - |
| Name | No | No | - |
| Email address | No | No | - |
| Phone number | No | No | - |
| Address | No | No | - |
| Other personal info | No | No | - |
| Financial info | Yes (optional) | No | Wallet functionality |
| Health info | No | No | - |
| Browsing history | No | No | - |
| Search history | No | No | - |
| Other IDs | Yes | Yes (peers) | P2P node identity |

---

## Sensitive Permissions Justification

### FOREGROUND_SERVICE + FOREGROUND_SERVICE_DATA_SYNC

**Justification for Google Play:**

> This app operates as a peer-to-peer network node that must maintain continuous connectivity with other nodes in the Cyberfly decentralized network. The foreground service is essential for:
> 
> 1. Maintaining persistent P2P connections using QUIC protocol
> 2. Participating in gossip protocol for network health
> 3. Synchronizing distributed data with network peers
> 4. Broadcasting node availability for peer discovery
> 
> Without the foreground service, the node would disconnect from the network when the app is backgrounded, breaking the core functionality of participating in the decentralized network.
> 
> The dataSync foreground service type accurately describes this functionality as the app synchronizes distributed data with peers.

### RECEIVE_BOOT_COMPLETED

**Justification:**

> Users can optionally configure the node to auto-start after device reboot to maintain continuous network participation. This is an opt-in feature for users who want their node to always be available on the network.

### POST_NOTIFICATIONS

**Justification:**

> Required to display the foreground service notification showing node status (connected peers, uptime). Android requires a notification for all foreground services.

---

## App Content Rating

Recommended IARC rating: **Everyone**

Content descriptors:
- No violence
- No sexual content
- No profanity
- No controlled substances
- No user interaction that isn't moderated (P2P is technical, not social)

---

## Additional Compliance Notes

1. **No ads**: The app contains no advertising
2. **No in-app purchases**: The app is free with no monetization
3. **Open source**: Full source code is available for review
4. **No account required**: Users don't need to create accounts
5. **Decentralized**: No central servers collecting data
