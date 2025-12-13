import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../src/rust/api.dart' as rust_api;
import '../theme/theme.dart';

class ConsoleScreen extends StatefulWidget {
  const ConsoleScreen({super.key});

  @override
  State<ConsoleScreen> createState() => _ConsoleScreenState();
}

class _ConsoleScreenState extends State<ConsoleScreen> {
  List<rust_api.LogEntry> _logs = [];
  Timer? _refreshTimer;
  bool _autoScroll = true;
  final ScrollController _scrollController = ScrollController();
  String _filterLevel = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLogs();
    // Refresh logs every 2 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) => _loadLogs());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadLogs() {
    try {
      final logs = rust_api.getLogs(limit: 500);
      if (mounted) {
        setState(() {
          _logs = logs;
        });
        if (_autoScroll && _scrollController.hasClients) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to load logs: $e');
    }
  }

  void _clearLogs() {
    rust_api.clearLogs();
    setState(() {
      _logs = [];
    });
  }

  List<rust_api.LogEntry> get _filteredLogs {
    return _logs.where((log) {
      // Level filter
      if (_filterLevel != 'ALL' && log.level != _filterLevel) {
        return false;
      }
      // Search filter
      if (_searchQuery.isNotEmpty) {
        return log.message.toLowerCase().contains(_searchQuery.toLowerCase());
      }
      return true;
    }).toList();
  }

  Color _getLevelColor(String level) {
    switch (level.toUpperCase()) {
      case 'ERROR':
        return Colors.red;
      case 'WARN':
        return Colors.orange;
      case 'INFO':
        return Colors.cyan;
      case 'DEBUG':
        return Colors.grey;
      default:
        return Colors.white70;
    }
  }

  String _formatTimestamp(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}.${(dt.millisecond ~/ 10).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _filteredLogs;

    return Scaffold(
      backgroundColor: CyberTheme.background(context),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.terminal, color: CyberTheme.primary(context), size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Console',
                style: TextStyle(
                  color: CyberTheme.textPrimary(context),
                  fontFamily: 'monospace',
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: CyberTheme.primary(context).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${filteredLogs.length}',
                style: TextStyle(
                  color: CyberTheme.primary(context),
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        backgroundColor: CyberTheme.card(context),
        actions: [
          // Auto-scroll toggle
          IconButton(
            icon: Icon(
              _autoScroll ? Icons.vertical_align_bottom : Icons.vertical_align_center,
              color: _autoScroll ? CyberTheme.primary(context) : CyberTheme.textSecondary(context),
            ),
            tooltip: _autoScroll ? 'Auto-scroll ON' : 'Auto-scroll OFF',
            onPressed: () => setState(() => _autoScroll = !_autoScroll),
          ),
          // Clear logs
          IconButton(
            icon: Icon(Icons.delete_outline, color: CyberTheme.textSecondary(context)),
            tooltip: 'Clear logs',
            onPressed: _clearLogs,
          ),
          // Copy all logs
          IconButton(
            icon: Icon(Icons.copy, color: CyberTheme.textSecondary(context)),
            tooltip: 'Copy logs',
            onPressed: () {
              final text = filteredLogs.map((l) => '[${_formatTimestamp(l.timestamp)}] ${l.level}: ${l.message}').join('\n');
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${filteredLogs.length} logs copied'),
                  backgroundColor: CyberTheme.card(context),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          Container(
            padding: const EdgeInsets.all(8),
            color: CyberTheme.card(context),
            child: Row(
              children: [
                // Level filter dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: CyberTheme.background(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: CyberTheme.border(context)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filterLevel,
                      dropdownColor: CyberTheme.card(context),
                      style: TextStyle(
                        color: CyberTheme.textPrimary(context),
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                      items: ['ALL', 'ERROR', 'WARN', 'INFO', 'DEBUG'].map((level) {
                        return DropdownMenuItem(
                          value: level,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (level != 'ALL')
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: _getLevelColor(level),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              Text(level),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _filterLevel = value);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Search field
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      color: CyberTheme.textPrimary(context),
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search logs...',
                      hintStyle: TextStyle(
                        color: CyberTheme.textSecondary(context),
                        fontFamily: 'monospace',
                      ),
                      prefixIcon: Icon(Icons.search, color: CyberTheme.textSecondary(context), size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: CyberTheme.textSecondary(context), size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: CyberTheme.background(context),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: CyberTheme.border(context)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: CyberTheme.border(context)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: CyberTheme.primary(context)),
                      ),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
              ],
            ),
          ),
          // Log list
          Expanded(
            child: filteredLogs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.terminal,
                          size: 64,
                          color: CyberTheme.textSecondary(context).withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _logs.isEmpty ? 'No logs yet' : 'No matching logs',
                          style: TextStyle(
                            color: CyberTheme.textSecondary(context),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _logs.isEmpty
                              ? 'Logs will appear here when the node is running'
                              : 'Try adjusting your filter or search',
                          style: TextStyle(
                            color: CyberTheme.textSecondary(context).withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log = filteredLogs[index];
                      final levelColor = _getLevelColor(log.level);
                      
                      return InkWell(
                        onLongPress: () {
                          Clipboard.setData(ClipboardData(text: log.message));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Log copied'),
                              backgroundColor: CyberTheme.card(context),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: CyberTheme.border(context).withOpacity(0.3),
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Timestamp
                              Text(
                                _formatTimestamp(log.timestamp),
                                style: TextStyle(
                                  color: CyberTheme.textSecondary(context),
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Level badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: levelColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  log.level.isNotEmpty ? log.level.substring(0, 1) : '?',
                                  style: TextStyle(
                                    color: levelColor,
                                    fontFamily: 'monospace',
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Message
                              Expanded(
                                child: Text(
                                  log.message,
                                  style: TextStyle(
                                    color: CyberTheme.textPrimary(context),
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Collapsible console log widget for embedding in other screens
class ConsoleLogWidget extends StatefulWidget {
  final double maxHeight;
  final bool initiallyExpanded;

  const ConsoleLogWidget({
    super.key,
    this.maxHeight = 300,
    this.initiallyExpanded = false,
  });

  @override
  State<ConsoleLogWidget> createState() => _ConsoleLogWidgetState();
}

class _ConsoleLogWidgetState extends State<ConsoleLogWidget> {
  List<rust_api.LogEntry> _logs = [];
  Timer? _refreshTimer;
  bool _isExpanded = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _loadLogs();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_isExpanded) _loadLogs();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadLogs() {
    try {
      final logs = rust_api.getLogs(limit: 100);
      if (mounted) {
        setState(() {
          _logs = logs;
        });
        if (_scrollController.hasClients) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to load logs: $e');
    }
  }

  Color _getLevelColor(String level) {
    switch (level.toUpperCase()) {
      case 'ERROR':
        return Colors.red;
      case 'WARN':
        return Colors.orange;
      case 'INFO':
        return Colors.cyan;
      case 'DEBUG':
        return Colors.grey;
      default:
        return Colors.white70;
    }
  }

  String _formatTimestamp(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CyberTheme.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CyberTheme.border(context)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header - always visible
          InkWell(
            onTap: () => setState(() {
              _isExpanded = !_isExpanded;
              if (_isExpanded) _loadLogs();
            }),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.terminal,
                    color: CyberTheme.primary(context),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Console',
                    style: TextStyle(
                      color: CyberTheme.textPrimary(context),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_logs.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: CyberTheme.primary(context).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_logs.length}',
                        style: TextStyle(
                          color: CyberTheme.primary(context),
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  const Spacer(),
                  // Open full screen button
                  if (_isExpanded)
                    IconButton(
                      icon: Icon(
                        Icons.open_in_new,
                        color: CyberTheme.textSecondary(context),
                        size: 18,
                      ),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ConsoleScreen()),
                        );
                      },
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: CyberTheme.textSecondary(context),
                  ),
                ],
              ),
            ),
          ),
          // Log content - collapsible
          ClipRect(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: _isExpanded ? widget.maxHeight : 0,
              curve: Curves.easeInOut,
              child: Container(
                height: widget.maxHeight,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: CyberTheme.border(context)),
                  ),
                ),
                child: _logs.isEmpty
                    ? Center(
                        child: Text(
                          'No logs yet',
                          style: TextStyle(
                            color: CyberTheme.textSecondary(context),
                            fontFamily: 'monospace',
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(8),
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          final levelColor = _getLevelColor(log.level);
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatTimestamp(log.timestamp),
                                  style: TextStyle(
                                    color: CyberTheme.textSecondary(context),
                                    fontFamily: 'monospace',
                                    fontSize: 9,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.only(top: 3),
                                  decoration: BoxDecoration(
                                    color: levelColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    log.message,
                                    style: TextStyle(
                                      color: CyberTheme.textPrimary(context),
                                      fontFamily: 'monospace',
                                      fontSize: 10,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
