import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/node_service.dart';
import '../services/wallet_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoStart = true;
  bool _runInBackground = true;
  bool _showNotifications = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoStart = prefs.getBool('autoStart') ?? true;
      _runInBackground = prefs.getBool('runInBackground') ?? true;
      _showNotifications = prefs.getBool('showNotifications') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final walletService = context.watch<WalletService>();
    final nodeService = context.watch<NodeService>();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text('Settings'),
              floating: true,
              backgroundColor: const Color(0xFF0A0E21).withOpacity(0.9),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Node settings
                  _buildSectionHeader('Node Settings'),
                  _buildSettingsCard([
                    _buildNodeStatusTile(nodeService),
                    _buildDivider(),
                    _buildSwitchTile(
                      'Auto-start Node',
                      'Start node automatically on app launch',
                      Icons.play_circle_outline,
                      _autoStart,
                      (value) {
                        setState(() => _autoStart = value);
                        _savePreference('autoStart', value);
                      },
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      'Run in Background',
                      'Keep node running when app is minimized',
                      Icons.sync,
                      _runInBackground,
                      (value) {
                        setState(() => _runInBackground = value);
                        _savePreference('runInBackground', value);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Restart app to apply background service change'),
                          ),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      'Notifications',
                      'Show notifications for peer connections',
                      Icons.notifications_outlined,
                      _showNotifications,
                      (value) {
                        setState(() => _showNotifications = value);
                        _savePreference('showNotifications', value);
                      },
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Wallet settings
                  _buildSectionHeader('Wallet'),
                  _buildSettingsCard([
                    _buildActionTile(
                      'View Recovery Phrase',
                      'Backup your wallet recovery phrase',
                      Icons.key,
                      Colors.orange,
                      () => _showRecoveryPhrase(context, walletService),
                    ),
                    _buildDivider(),
                    _buildInfoTile(
                      'Public Key',
                      walletService.publicKey ?? 'Not available',
                      Icons.vpn_key,
                    ),
                    _buildDivider(),
                    _buildInfoTile(
                      'Account',
                      walletService.account ?? 'Not available',
                      Icons.account_circle,
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Network info
                  _buildSectionHeader('Network'),
                  _buildSettingsCard([
                    _buildInfoTile(
                      'Node ID',
                      nodeService.nodeInfo?.nodeId ?? 'Not running',
                      Icons.fingerprint,
                    ),
                    _buildDivider(),
                    _buildInfoTile(
                      'Relay URL',
                      nodeService.nodeInfo?.relayUrl ?? 'None',
                      Icons.router,
                    ),
                    _buildDivider(),
                    _buildInfoTile(
                      'Local Addresses',
                      nodeService.nodeInfo?.localAddrs.join(', ') ?? 'None',
                      Icons.lan,
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // About
                  _buildSectionHeader('About'),
                  _buildSettingsCard([
                    _buildInfoTile(
                      'Version',
                      '1.0.0',
                      Icons.info_outline,
                    ),
                    _buildDivider(),
                    _buildActionTile(
                      'GitHub Repository',
                      'View source code',
                      Icons.code,
                      const Color(0xFF00D9FF),
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opening GitHub...')),
                        );
                      },
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Danger zone
                  _buildSectionHeader('Danger Zone', color: Colors.red),
                  _buildSettingsCard([
                    _buildActionTile(
                      'Reset Wallet',
                      'Delete wallet and all local data',
                      Icons.delete_forever,
                      Colors.red,
                      () => _showResetConfirmation(context, walletService),
                    ),
                  ], borderColor: Colors.red.withOpacity(0.3)),

                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.white.withOpacity(0.7),
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children, {Color? borderColor}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.white.withOpacity(0.1),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF00D9FF).withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF00D9FF), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF00FF88),
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(color: color, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.white.withOpacity(0.3),
      ),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white.withOpacity(0.7), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 12,
          fontFamily: 'monospace',
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: Icon(
          Icons.copy,
          size: 16,
          color: Colors.white.withOpacity(0.3),
        ),
        onPressed: () {
          Clipboard.setData(ClipboardData(text: value));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Copied to clipboard')),
          );
        },
      ),
    );
  }

  Widget _buildNodeStatusTile(NodeService nodeService) {
    final isRunning = nodeService.isRunning;
    final isStarting = nodeService.isStarting;
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isRunning 
            ? const Color(0xFF00FF88).withOpacity(0.2)
            : isStarting
              ? Colors.orange.withOpacity(0.2)
              : Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isRunning ? Icons.check_circle : isStarting ? Icons.sync : Icons.cancel,
          color: isRunning 
            ? const Color(0xFF00FF88)
            : isStarting
              ? Colors.orange
              : Colors.red,
          size: 20,
        ),
      ),
      title: Text(
        'Node Status',
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      subtitle: Text(
        isRunning ? 'Running' : isStarting ? 'Starting...' : 'Stopped',
        style: TextStyle(
          color: isRunning 
            ? const Color(0xFF00FF88)
            : isStarting
              ? Colors.orange
              : Colors.red.withOpacity(0.7),
          fontSize: 12,
        ),
      ),
      trailing: isStarting
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.orange,
            ),
          )
            : ElevatedButton(
            onPressed: isRunning 
              ? () => _confirmStopNode(context, nodeService)
              : () => nodeService.startNode(),
            style: ElevatedButton.styleFrom(
              backgroundColor: isRunning 
                ? const Color(0xFFFF6B6B)
                : const Color(0xFF00FF88),
              foregroundColor: isRunning ? Colors.white : Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
            ),
            child: Text(
              isRunning ? 'Stop' : 'Start',
              style: const TextStyle(fontSize: 12),
            ),
          ),
    );
  }

  void _confirmStopNode(BuildContext context, NodeService nodeService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text('Stop Node?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Stopping the node will disconnect you from the P2P network. '
          'You will not receive any data updates while the node is stopped.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              nodeService.stopNode();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
            ),
            child: const Text('Stop Node'),
          ),
        ],
      ),
    );
  }

  void _showRecoveryPhrase(BuildContext context, WalletService walletService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text('⚠️ Warning', style: TextStyle(color: Colors.orange)),
        content: const Text(
          'Your recovery phrase gives full access to your wallet. Never share it with anyone.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _displayRecoveryPhrase(context, walletService);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Show'),
          ),
        ],
      ),
    );
  }

  void _displayRecoveryPhrase(BuildContext context, WalletService walletService) {
    final mnemonic = walletService.getMnemonic();
    if (mnemonic == null) return;

    final words = mnemonic.split(' ');

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1D1E33),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          24, 24, 24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recovery Phrase',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0E21),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(words.length, (index) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D1E33),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${index + 1}. ${words[index]}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: mnemonic));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Recovery phrase copied')),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy to Clipboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D9FF),
                  foregroundColor: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, WalletService walletService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text('🚨 Reset Wallet', style: TextStyle(color: Colors.red)),
        content: const Text(
          'This will permanently delete your wallet and all local data. '
          'Make sure you have backed up your recovery phrase. This action cannot be undone.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await walletService.deleteWallet();
              if (context.mounted) {
                // Navigate to wallet setup
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/setup',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
  }
}
