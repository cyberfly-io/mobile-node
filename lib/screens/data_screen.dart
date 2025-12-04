import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../src/rust/api.dart' as rust_api;

/// Model class for database operation display
class DbOperation {
  final String opId;
  final String dbName;
  final String key;
  final String value;
  final String storeType;
  final int timestamp;
  final String signer;

  DbOperation({
    required this.opId,
    required this.dbName,
    required this.key,
    required this.value,
    required this.storeType,
    required this.timestamp,
    required this.signer,
  });
}

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  final _dbNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  List<DbOperation> _results = [];
  List<String> _dbNames = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDatabaseNames();
  }

  @override
  void dispose() {
    _dbNameController.dispose();
    super.dispose();
  }

  Future<void> _loadDatabaseNames() async {
    try {
      final dbNames = rust_api.listDatabases();
      if (mounted) {
        setState(() {
          _dbNames = dbNames;
        });
      }
    } catch (e) {
      // Silently fail if node not running
    }
  }

  Future<void> _fetchData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _results = [];
    });

    try {
      final entries = await rust_api.getAllEntries(dbName: _dbNameController.text.trim());
      if (mounted) {
        setState(() {
          _isLoading = false;
          _results = entries.map((e) => DbOperation(
            opId: '${e.dbName}:${e.key}',
            dbName: e.dbName,
            key: e.key,
            value: e.value,
            storeType: _detectStoreType(e.value),
            timestamp: DateTime.now().millisecondsSinceEpoch,
            signer: '',
          )).toList();
          if (_results.isEmpty) {
            _error = 'No data found in database "${_dbNameController.text.trim()}"';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error fetching data: $e';
        });
      }
    }
  }

  String _detectStoreType(String value) {
    final trimmed = value.trim();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      return 'json';
    }
    return 'string';
  }

  Future<void> _fetchAllData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _results = [];
    });

    try {
      final entries = await rust_api.getAllData();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _results = entries.map((e) => DbOperation(
            opId: '${e.dbName}:${e.key}',
            dbName: e.dbName,
            key: e.key,
            value: e.value,
            storeType: _detectStoreType(e.value),
            timestamp: DateTime.now().millisecondsSinceEpoch,
            signer: '',
          )).toList();
          // Update db names list
          _dbNames = entries.map((e) => e.dbName).toSet().toList();
          if (_results.isEmpty) {
            _error = 'No data stored yet';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error fetching data: $e';
        });
      }
    }
  }

  Future<void> _deleteEntry(DbOperation op) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text('Delete Entry', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${op.key}" from "${op.dbName}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await rust_api.deleteData(dbName: op.dbName, key: op.key);
        if (mounted) {
          setState(() {
            _results.removeWhere((r) => r.opId == op.opId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Entry deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text('Data Explorer'),
              floating: true,
              backgroundColor: const Color(0xFF0A0E21).withOpacity(0.9),
              actions: [
                IconButton(
                  onPressed: _isLoading ? null : _fetchAllData,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Load all data',
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Database names chips (if any)
                  if (_dbNames.isNotEmpty) ...[
                    const Text(
                      'Available Databases',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _dbNames
                          .map(
                            (name) => ActionChip(
                              label: Text(
                                name.length > 20
                                    ? '${name.substring(0, 20)}...'
                                    : name,
                                style: const TextStyle(fontSize: 11),
                              ),
                              onPressed: () {
                                _dbNameController.text = name;
                                _fetchData();
                              },
                              backgroundColor: const Color(0xFF1D1E33),
                              side: BorderSide(
                                color: const Color(0xFF00D9FF).withOpacity(0.3),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Search form
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1D1E33),
                          const Color(0xFF1D1E33).withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF00D9FF).withOpacity(0.3),
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF00D9FF,
                                  ).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.search,
                                  color: Color(0xFF00D9FF),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Query Database',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _dbNameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Database Name',
                              labelStyle: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                              ),
                              hintText: 'Enter db name (e.g., mydb-<pubkey>)',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                              ),
                              filled: true,
                              fillColor: const Color(0xFF0A0E21),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF00D9FF),
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a database name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _fetchData,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00D9FF),
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.black,
                                          ),
                                        )
                                      : const Icon(Icons.download),
                                  label: Text(
                                    _isLoading ? 'Fetching...' : 'Fetch',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: _isLoading ? null : _fetchAllData,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1D1E33),
                                  foregroundColor: const Color(0xFF00D9FF),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(
                                    color: const Color(
                                      0xFF00D9FF,
                                    ).withOpacity(0.5),
                                  ),
                                ),
                                child: const Text('All'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Error message
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Results
                  if (_results.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Results (${_results.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._results.map((item) => _buildResultCard(item)),
                  ],

                  // Empty state
                  if (_results.isEmpty && _error == null && !_isLoading)
                    Container(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.storage_outlined,
                            size: 64,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Enter a database name to query data\nor tap "All" to see all stored data',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(DbOperation op) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStoreTypeColor(op.storeType).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  op.storeType,
                  style: TextStyle(
                    color: _getStoreTypeColor(op.storeType),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  op.key,
                  style: const TextStyle(
                    color: Color(0xFF00D9FF),
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: op.value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Value copied to clipboard')),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                color: Colors.white.withOpacity(0.5),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
                tooltip: 'Copy value',
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => _deleteEntry(op),
                icon: const Icon(Icons.delete_outline, size: 16),
                color: Colors.red.withOpacity(0.7),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
                tooltip: 'Delete entry',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            op.value.length > 200
                ? '${op.value.substring(0, 200)}...'
                : op.value,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.storage,
                size: 12,
                color: Colors.white.withOpacity(0.4),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  op.dbName.length > 40
                      ? '${op.dbName.substring(0, 40)}...'
                      : op.dbName,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStoreTypeColor(String storeType) {
    switch (storeType.toLowerCase()) {
      case 'string':
        return Colors.green;
      case 'json':
        return Colors.blue;
      case 'hash':
        return Colors.purple;
      case 'list':
        return Colors.orange;
      case 'set':
        return Colors.pink;
      case 'sortedset':
        return Colors.teal;
      case 'stream':
        return Colors.amber;
      case 'timeseries':
        return Colors.cyan;
      case 'geo':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
