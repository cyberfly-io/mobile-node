//! Cryptographic utilities using Ed25519
//! 
//! This module provides Ed25519 signing and verification for messages,
//! matching the cyberfly-rust-node implementation exactly.
//! 
//! Note: Ed25519 internally uses SHA-512 for hashing as part of the algorithm.
//! We do NOT pre-hash messages before signing - messages are signed directly.

use anyhow::{anyhow, Result};
use ed25519_dalek::{Signature, Signer, SigningKey, Verifier, VerifyingKey};
use std::time::{SystemTime, UNIX_EPOCH};

// Security constants (matching cyberfly-rust-node)
pub const ED25519_PUBLIC_KEY_LENGTH: usize = 32;
pub const ED25519_SIGNATURE_LENGTH: usize = 64;
pub const MAX_MESSAGE_LENGTH: usize = 1024 * 1024; // 1MB max message size
pub const MIN_TIMESTAMP_TOLERANCE: u64 = 300; // 5 minutes in seconds
pub const MAX_TIMESTAMP_TOLERANCE: u64 = 3600; // 1 hour in seconds

// Security error messages
pub const INVALID_PUBLIC_KEY_LENGTH: &str = "Invalid public key length - must be 32 bytes";
pub const INVALID_SIGNATURE_LENGTH: &str = "Invalid signature length - must be 64 bytes";
pub const MESSAGE_TOO_LARGE: &str = "Message exceeds maximum allowed size";
pub const TIMESTAMP_TOO_OLD: &str = "Timestamp is too old";
pub const TIMESTAMP_TOO_FUTURE: &str = "Timestamp is too far in the future";
pub const MALFORMED_HEX_ENCODING: &str = "Malformed hexadecimal encoding";

/// Sign a message with Ed25519
pub fn sign_message(signing_key: &SigningKey, message: &[u8]) -> String {
    let signature = signing_key.sign(message);
    hex::encode(signature.to_bytes())
}

/// Verify an Ed25519 signature (hex inputs)
pub fn verify_signature(public_key_hex: &str, message: &[u8], signature_hex: &str) -> Result<bool> {
    // Decode and validate
    let public_key_bytes = secure_hex_decode(public_key_hex)?;
    let signature_bytes = secure_hex_decode(signature_hex)?;
    
    verify_signature_bytes(&public_key_bytes, message, &signature_bytes)
}

/// Verify an Ed25519 signature with enhanced security checks (byte inputs)
/// Matches cyberfly-rust-node's verify_signature function
pub fn verify_signature_bytes(
    public_key_bytes: &[u8],
    message: &[u8],
    signature_bytes: &[u8],
) -> Result<bool> {
    // Input validation
    if public_key_bytes.len() != ED25519_PUBLIC_KEY_LENGTH {
        return Err(anyhow!(INVALID_PUBLIC_KEY_LENGTH));
    }
    
    if signature_bytes.len() != ED25519_SIGNATURE_LENGTH {
        return Err(anyhow!(INVALID_SIGNATURE_LENGTH));
    }
    
    if message.len() > MAX_MESSAGE_LENGTH {
        return Err(anyhow!(MESSAGE_TOO_LARGE));
    }

    // Parse public key
    let public_key_array: [u8; 32] = public_key_bytes
        .try_into()
        .map_err(|_| anyhow!(INVALID_PUBLIC_KEY_LENGTH))?;
    
    let verifying_key = VerifyingKey::from_bytes(&public_key_array)
        .map_err(|e| anyhow!("Failed to parse public key: {}", e))?;
    
    // Parse signature
    let signature_array: [u8; 64] = signature_bytes
        .try_into()
        .map_err(|_| anyhow!(INVALID_SIGNATURE_LENGTH))?;
    
    let signature = Signature::from_bytes(&signature_array);
    
    // Verify signature
    match verifying_key.verify(message, &signature) {
        Ok(_) => Ok(true),
        Err(_) => Ok(false),
    }
}

/// Securely decode hex string with validation (matching cyberfly-rust-node)
pub fn secure_hex_decode(hex_str: &str) -> Result<Vec<u8>> {
    // Empty string is valid
    if hex_str.is_empty() {
        return Ok(Vec::new());
    }
    
    // Validate hex string format
    if hex_str.len() % 2 != 0 {
        return Err(anyhow!(MALFORMED_HEX_ENCODING));
    }
    
    hex::decode(hex_str)
        .map_err(|_| anyhow!(MALFORMED_HEX_ENCODING))
}

/// Validate timestamp against current time with configurable tolerance
/// Matches cyberfly-rust-node's validate_timestamp function
pub fn validate_timestamp(timestamp: i64, tolerance_seconds: Option<u64>) -> Result<()> {
    let tolerance = tolerance_seconds.unwrap_or(MIN_TIMESTAMP_TOLERANCE);
    
    let now = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map_err(|_| anyhow!("System time error"))?
        .as_millis() as i64;
    
    let tolerance_ms = (tolerance * 1000) as i64;
    
    // Check if timestamp is too old
    if timestamp < now - tolerance_ms {
        return Err(anyhow!(TIMESTAMP_TOO_OLD));
    }
    
    // Check if timestamp is too far in the future
    if timestamp > now + tolerance_ms {
        return Err(anyhow!(TIMESTAMP_TOO_FUTURE));
    }
    
    Ok(())
}

/// Generate database name from name and public key
/// Format: <name>-<public_key_hex> (matching cyberfly-rust-node)
pub fn generate_db_name(name: &str, public_key_hex: &str) -> String {
    format!("{}-{}", name, public_key_hex)
}

/// Verify that the database name matches the public key
pub fn verify_db_name(db_name: &str, public_key_hex: &str) -> Result<()> {
    if !db_name.ends_with(&format!("-{}", public_key_hex)) {
        return Err(anyhow!("Database name does not match public key"));
    }
    Ok(())
}

/// Enhanced database name verification with additional security checks
/// Matches cyberfly-rust-node's verify_db_name_secure function
pub fn verify_db_name_secure(db_name: &str, public_key_hex: &str) -> Result<()> {
    // Basic format validation
    if db_name.is_empty() || public_key_hex.is_empty() {
        return Err(anyhow!("Database name and public key cannot be empty"));
    }
    
    // Validate public key hex format
    if public_key_hex.len() != ED25519_PUBLIC_KEY_LENGTH * 2 {
        return Err(anyhow!("Public key must be {} hex characters", ED25519_PUBLIC_KEY_LENGTH * 2));
    }
    
    // Validate hex encoding
    secure_hex_decode(public_key_hex)?;
    
    // Check database name format
    if !db_name.ends_with(&format!("-{}", public_key_hex)) {
        return Err(anyhow!("Database name does not match public key"));
    }
    
    // Extract and validate the name part
    let name_part = extract_name_from_db(db_name)
        .ok_or_else(|| anyhow!("Invalid database name format"))?;
    
    // Validate name part (no special characters that could cause issues)
    if name_part.is_empty() || name_part.contains(char::is_control) {
        return Err(anyhow!("Invalid database name format"));
    }
    
    Ok(())
}

/// Extract name part from database name (removes public key suffix)
pub fn extract_name_from_db(db_name: &str) -> Option<String> {
    db_name.rfind('-').map(|pos| db_name[..pos].to_string())
}

/// Generate a new Ed25519 keypair
pub fn generate_keypair() -> (SigningKey, String) {
    #[allow(deprecated)]
    let signing_key = SigningKey::generate(&mut rand::thread_rng());
    let public_key_hex = hex::encode(signing_key.verifying_key().as_bytes());
    (signing_key, public_key_hex)
}

/// Convert secret key bytes to SigningKey
pub fn secret_to_signing_key(secret_bytes: &[u8; 32]) -> SigningKey {
    SigningKey::from_bytes(secret_bytes)
}

/// Get public key hex from signing key
pub fn public_key_hex(signing_key: &SigningKey) -> String {
    hex::encode(signing_key.verifying_key().as_bytes())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sign_and_verify() {
        let (signing_key, public_key_hex) = generate_keypair();
        let message = b"test message";
        
        let signature = sign_message(&signing_key, message);
        let is_valid = verify_signature(&public_key_hex, message, &signature).unwrap();
        
        assert!(is_valid, "Signature should be valid");
    }

    #[test]
    fn test_invalid_signature() {
        let (signing_key, public_key_hex) = generate_keypair();
        let message = b"test message";
        let wrong_message = b"wrong message";
        
        let signature = sign_message(&signing_key, message);
        let is_valid = verify_signature(&public_key_hex, wrong_message, &signature).unwrap();
        
        assert!(!is_valid, "Signature should be invalid for wrong message");
    }

    #[test]
    fn test_invalid_key_length() {
        let message = b"test message";
        let invalid_key = vec![0u8; 16]; // Should be 32
        let signature = vec![0u8; 64];
        
        let result = verify_signature_bytes(&invalid_key, message, &signature);
        assert!(result.is_err());
        assert!(result.unwrap_err().to_string().contains("32 bytes"));
    }

    #[test]
    fn test_invalid_signature_length() {
        let (_, public_key_hex) = generate_keypair();
        let public_key_bytes = hex::decode(&public_key_hex).unwrap();
        let message = b"test message";
        let invalid_sig = vec![0u8; 32]; // Should be 64
        
        let result = verify_signature_bytes(&public_key_bytes, message, &invalid_sig);
        assert!(result.is_err());
        assert!(result.unwrap_err().to_string().contains("64 bytes"));
    }

    #[test]
    fn test_secure_hex_decode() {
        // Valid hex
        let result = secure_hex_decode("abcd1234").unwrap();
        assert_eq!(result, vec![0xab, 0xcd, 0x12, 0x34]);
        
        // Empty string is valid
        let result = secure_hex_decode("").unwrap();
        assert!(result.is_empty());
        
        // Invalid hex
        let result = secure_hex_decode("xyz");
        assert!(result.is_err());
    }

    #[test]
    fn test_db_name_generation_and_verification() {
        let (_, public_key) = generate_keypair();
        let name = "testdb";
        
        let db_name = generate_db_name(name, &public_key);
        assert!(db_name.starts_with("testdb-"));
        assert!(db_name.ends_with(&public_key));
        
        // Should pass verification
        assert!(verify_db_name(&db_name, &public_key).is_ok());
        assert!(verify_db_name_secure(&db_name, &public_key).is_ok());
        
        // Should fail with wrong key
        let (_, other_key) = generate_keypair();
        assert!(verify_db_name(&db_name, &other_key).is_err());
    }

    #[test]
    fn test_extract_name_from_db() {
        let db_name = "myapp-abc123";
        assert_eq!(extract_name_from_db(db_name), Some("myapp".to_string()));
        
        let simple = "simple";
        assert_eq!(extract_name_from_db(simple), None);
    }
}