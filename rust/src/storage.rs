//! Storage module using sled embedded database

use std::path::PathBuf;
use anyhow::Result;
use sled::Db;

/// Storage wrapper for sled database
#[derive(Clone)]
pub struct Storage {
    db: Db,
}

impl Storage {
    /// Create a new storage instance
    pub fn new(path: PathBuf) -> Result<Self> {
        let db = sled::Config::new()
            .path(path)
            .cache_capacity(64 * 1024 * 1024) // 64MB cache
            .flush_every_ms(Some(1000))
            .use_compression(true) // Must match previous setting
            .open()?;
        
        Ok(Self { db })
    }

    /// Get a value by database name and key
    pub fn get(&self, db_name: &str, key: &str) -> Result<Option<Vec<u8>>> {
        let tree = self.db.open_tree(db_name)?;
        Ok(tree.get(key)?.map(|v| v.to_vec()))
    }

    /// Put a value
    pub fn put(&self, db_name: &str, key: &str, value: &[u8]) -> Result<()> {
        let tree = self.db.open_tree(db_name)?;
        tree.insert(key, value)?;
        Ok(())
    }

    /// Delete a value
    pub fn delete(&self, db_name: &str, key: &str) -> Result<()> {
        let tree = self.db.open_tree(db_name)?;
        tree.remove(key)?;
        Ok(())
    }

    /// List all keys in a database
    pub fn list_keys(&self, db_name: &str) -> Result<Vec<String>> {
        let tree = self.db.open_tree(db_name)?;
        let keys: Vec<String> = tree
            .iter()
            .keys()
            .filter_map(|k| k.ok())
            .filter_map(|k| String::from_utf8(k.to_vec()).ok())
            .collect();
        Ok(keys)
    }

    /// Get all database names
    pub fn list_databases(&self) -> Result<Vec<String>> {
        let names: Vec<String> = self.db
            .tree_names()
            .iter()
            .filter_map(|n| String::from_utf8(n.to_vec()).ok())
            .filter(|n| n != "__sled__default")
            .collect();
        Ok(names)
    }

    /// Get storage size in bytes
    pub fn size_bytes(&self) -> Result<u64> {
        Ok(self.db.size_on_disk()?)
    }

    /// Get total key count across all databases
    pub fn key_count(&self) -> Result<usize> {
        let mut count = 0;
        for name in self.db.tree_names() {
            if let Ok(tree) = self.db.open_tree(&name) {
                count += tree.len();
            }
        }
        Ok(count)
    }

    /// Flush to disk
    pub fn flush(&self) -> Result<()> {
        self.db.flush()?;
        Ok(())
    }
}
