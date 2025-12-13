//! Storage module using sled embedded database

use std::path::PathBuf;
use anyhow::Result;
use sled::Db;

/// Special tree name for storing the operations log (for sync)
const OPLOG_TREE: &str = "__oplog__";

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
            .cache_capacity(128 * 1024 * 1024) // 128MB cache for better read perf
            .flush_every_ms(Some(5000))         // Flush every 5s (less I/O, still safe)
            .mode(sled::Mode::HighThroughput)   // Optimize for throughput
            .use_compression(true)              // Must match previous setting
            .open()?;
        
        Ok(Self { db })
    }
    
    /// Store a signed operation to the operations log
    pub fn put_operation(&self, op_id: &str, operation_json: &[u8]) -> Result<()> {
        let tree = self.db.open_tree(OPLOG_TREE)?;
        tree.insert(op_id, operation_json)?;
        Ok(())
    }
    
    /// Get a signed operation from the operations log
    pub fn get_operation(&self, op_id: &str) -> Result<Option<Vec<u8>>> {
        let tree = self.db.open_tree(OPLOG_TREE)?;
        Ok(tree.get(op_id)?.map(|v| v.to_vec()))
    }
    
    /// Check if an operation exists in the log
    pub fn has_operation(&self, op_id: &str) -> Result<bool> {
        let tree = self.db.open_tree(OPLOG_TREE)?;
        Ok(tree.contains_key(op_id)?)
    }
    
    /// Get all operations from the log
    pub fn get_all_operations(&self) -> Result<Vec<Vec<u8>>> {
        let tree = self.db.open_tree(OPLOG_TREE)?;
        let ops: Vec<Vec<u8>> = tree
            .iter()
            .values()
            .filter_map(|v| v.ok())
            .map(|v| v.to_vec())
            .collect();
        Ok(ops)
    }
    
    /// Get count of operations in the log
    pub fn operation_count(&self) -> Result<usize> {
        let tree = self.db.open_tree(OPLOG_TREE)?;
        Ok(tree.len())
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
            .filter(|n| n != "__sled__default" && n != OPLOG_TREE)
            .collect();
        Ok(names)
    }

    /// Get storage size in bytes (actual data size, not file size)
    pub fn size_bytes(&self) -> Result<u64> {
        let mut total_size: u64 = 0;
        for name in self.db.tree_names() {
            if let Ok(tree) = self.db.open_tree(&name) {
                for item in tree.iter() {
                    if let Ok((key, value)) = item {
                        total_size += key.len() as u64;
                        total_size += value.len() as u64;
                    }
                }
            }
        }
        Ok(total_size)
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
