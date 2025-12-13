import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/node_service.dart';
import '../services/wallet_service.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../theme/theme.dart';
import '../widgets/pin_input_dialog.dart';
import 'wallet_setup_screen.dart';
import 'main_screen.dart';

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
    final authService = context.watch<AuthService>();
    final themeService = context.watch<ThemeService>();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text('Settings'),
              floating: true,
              backgroundColor: CyberTheme.appBarBackground(context),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: _isLoading
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: CircularProgressIndicator(color: CyberTheme.primary(context)),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildListDelegate([
                  // Node settings
                  _buildSectionHeader(context, 'Node Settings'),
                  _buildSettingsCard(context, [
                    _buildNodeStatusTile(context, nodeService),
                    _buildDivider(context),
                    _buildSwitchTile(
                      context,
                      'Auto-start Node',
                      'Start node automatically on app launch',
                      Icons.play_circle_outline,
                      _autoStart,
                      (value) {
                        setState(() => _autoStart = value);
                        _savePreference('autoStart', value);
                      },
                    ),
                    _buildDivider(context),
                    _buildSwitchTile(
                      context,
                      'Run in Background',
                      'Keep node running when app is minimized',
                      Icons.sync,
                      _runInBackground,
                      (value) {
                        setState(() => _runInBackground = value);
                        _savePreference('runInBackground', value);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Restart app to apply background service change',
                              style: TextStyle(color: CyberTheme.textPrimary(context)),
                            ),
                            backgroundColor: CyberTheme.card(context),
                          ),
                        );
                      },
                    ),
                    _buildDivider(context),
                    _buildSwitchTile(
                      context,
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

                  // Appearance settings
                  _buildSectionHeader(context, 'Appearance'),
                  _buildSettingsCard(context, [
                    _buildThemeSelector(context, themeService),
                  ]),

                  const SizedBox(height: 24),

                  // Security settings
                  _buildSectionHeader(context, 'Security'),
                  _buildSettingsCard(context, [
                    _buildActionTile(
                      context,
                      authService.hasPinSet ? 'Change PIN' : 'Set PIN',
                      authService.hasPinSet 
                        ? 'Change your security PIN'
                        : 'Protect your wallet with a PIN',
                      Icons.pin,
                      CyberTheme.primary(context),
                      () => _setupOrChangePin(context, authService),
                    ),
                    if (authService.hasPinSet) ...[
                      _buildDivider(context),
                      _buildSwitchTile(
                        context,
                        'Biometric Unlock',
                        authService.isBiometricAvailable
                          ? 'Use fingerprint or face to unlock'
                          : 'Biometrics not available on this device',
                        Icons.fingerprint,
                        authService.isBiometricEnabled,
                        authService.isBiometricAvailable 
                          ? (value) async {
                              if (value) {
                                // Verify biometric before enabling
                                final authenticated = await authService.authenticateWithBiometrics(
                                  reason: 'Verify biometric to enable',
                                );
                                if (authenticated) {
                                  await authService.setBiometricEnabled(true);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Biometric authentication enabled'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                }
                              } else {
                                await authService.setBiometricEnabled(false);
                              }
                              setState(() {});
                            }
                          : null,
                      ),
                      _buildDivider(context),
                      _buildActionTile(
                        context,
                        'Remove PIN',
                        'Remove PIN protection',
                        Icons.lock_open,
                        CyberTheme.warning(context),
                        () => _removePin(context, authService),
                      ),
                    ],
                  ]),

                  const SizedBox(height: 24),

                  // Wallet settings
                  _buildSectionHeader(context, 'Wallet'),
                  _buildSettingsCard(context, [
                    _buildActionTile(
                      context,
                      'View Recovery Phrase',
                      'Backup your wallet recovery phrase',
                      Icons.key,
                      CyberTheme.warning(context),
                      () => _showRecoveryPhrase(context, walletService, authService),
                    ),
                    _buildDivider(context),
                    _buildInfoTile(
                      context,
                      'Public Key',
                      walletService.publicKey ?? 'Not available',
                      Icons.vpn_key,
                    ),
                    _buildDivider(context),
                    _buildInfoTile(
                      context,
                      'Account',
                      walletService.account ?? 'Not available',
                      Icons.account_circle,
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Network info
                  _buildSectionHeader(context, 'Network'),
                  _buildSettingsCard(context, [
                    _buildInfoTile(
                      context,
                      'Node ID',
                      nodeService.nodeInfo?.nodeId ?? 'Not running',
                      Icons.fingerprint,
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // About
                  _buildSectionHeader(context, 'About'),
                  _buildSettingsCard(context, [
                    _buildInfoTile(
                      context,
                      'Version',
                      '1.0.0',
                      Icons.info_outline,
                    ),
                    _buildDivider(context),
                    _buildActionTile(
                      context,
                      'GitHub Repository',
                      'View source code',
                      Icons.code,
                      CyberTheme.primary(context),
                      () async {
                        final uri = Uri.parse('https://github.com/cyberfly-io/mobile-node');
                        try {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } catch (e) {
                          debugPrint('Could not launch URL: $e');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not open link')),
                            );
                          }
                        }
                      },
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Danger zone
                  _buildSectionHeader(context, 'Danger Zone', color: CyberTheme.error(context)),
                  _buildSettingsCard(context, [
                    _buildActionTile(
                      context,
                      'Reset Wallet',
                      'Delete wallet and all local data',
                      Icons.delete_forever,
                      CyberTheme.error(context),
                      () => _showResetConfirmation(context, walletService),
                    ),
                  ], borderColor: CyberTheme.error(context).withOpacity(0.3)),

                  const SizedBox(height: 40),
                      ]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: color ?? CyberTheme.textSecondary(context),
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, List<Widget> children, {Color? borderColor}) {
    return Container(
      decoration: CyberTheme.settingsCard(context, borderColor: borderColor),
      child: Column(children: children),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      color: CyberTheme.divider(context),
    );
  }

  Widget _buildThemeSelector(BuildContext context, ThemeService themeService) {
    final primaryColor = CyberTheme.primary(context);
    final textPrimary = CyberTheme.textPrimary(context);
    final textSecondary = CyberTheme.textSecondary(context);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: CyberTheme.iconContainer(context, primaryColor),
                child: Icon(Icons.palette, color: primaryColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme',
                      style: TextStyle(color: textPrimary, fontSize: 14),
                    ),
                    Text(
                      'Choose your preferred appearance',
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildThemeOption(
                context,
                themeService,
                AppThemeMode.system,
                Icons.settings_brightness,
                'System',
              ),
              const SizedBox(width: 8),
              _buildThemeOption(
                context,
                themeService,
                AppThemeMode.light,
                Icons.light_mode,
                'Light',
              ),
              const SizedBox(width: 8),
              _buildThemeOption(
                context,
                themeService,
                AppThemeMode.dark,
                Icons.dark_mode,
                'Dark',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeService themeService,
    AppThemeMode mode,
    IconData icon,
    String label,
  ) {
    final isSelected = themeService.themeMode == mode;
    final primaryColor = CyberTheme.primary(context);
    final textSecondary = CyberTheme.textSecondary(context);
    final isDark = CyberTheme.isDark(context);
    
    return Expanded(
      child: GestureDetector(
        onTap: () => themeService.setThemeMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected 
              ? primaryColor.withOpacity(0.2) 
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                ? primaryColor 
                : CyberTheme.border(context),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? primaryColor : textSecondary,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? primaryColor : textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool>? onChanged,
  ) {
    final isEnabled = onChanged != null;
    final primaryColor = CyberTheme.primary(context);
    final textPrimary = CyberTheme.textPrimary(context);
    final textSecondary = CyberTheme.textSecondary(context);
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isEnabled ? primaryColor : Colors.grey).withOpacity(CyberTheme.isDark(context) ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: isEnabled ? primaryColor : Colors.grey, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(color: isEnabled ? textPrimary : textSecondary, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: textSecondary.withOpacity(isEnabled ? 1.0 : 0.6), fontSize: 12),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: CyberTheme.success(context),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final textSecondary = CyberTheme.textSecondary(context);
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(CyberTheme.isDark(context) ? 0.2 : 0.1),
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
        style: TextStyle(color: textSecondary, fontSize: 12),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: textSecondary.withOpacity(0.5),
      ),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile(BuildContext context, String title, String value, IconData icon) {
    final textPrimary = CyberTheme.textPrimary(context);
    final textSecondary = CyberTheme.textSecondary(context);
    final isDark = CyberTheme.isDark(context);
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: textSecondary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(color: textPrimary, fontSize: 14),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          color: textSecondary,
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
          color: textSecondary.withOpacity(0.5),
        ),
        onPressed: () {
          Clipboard.setData(ClipboardData(text: value));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Copied to clipboard',
                style: TextStyle(color: CyberTheme.textPrimary(context)),
              ),
              backgroundColor: CyberTheme.card(context),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNodeStatusTile(BuildContext context, NodeService nodeService) {
    final isRunning = nodeService.isRunning;
    final isStarting = nodeService.isStarting;
    final textPrimary = CyberTheme.textPrimary(context);
    final successColor = CyberTheme.success(context);
    final errorColor = CyberTheme.error(context);
    final warningColor = CyberTheme.warning(context);
    final isDark = CyberTheme.isDark(context);
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isRunning 
            ? successColor.withOpacity(isDark ? 0.2 : 0.1)
            : isStarting
              ? warningColor.withOpacity(isDark ? 0.2 : 0.1)
              : errorColor.withOpacity(isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isRunning ? Icons.check_circle : isStarting ? Icons.sync : Icons.cancel,
          color: isRunning 
            ? successColor
            : isStarting
              ? warningColor
              : errorColor,
          size: 20,
        ),
      ),
      title: Text(
        'Node Status',
        style: TextStyle(color: textPrimary, fontSize: 14),
      ),
      subtitle: Text(
        isRunning ? 'Running' : isStarting ? 'Starting...' : 'Stopped',
        style: TextStyle(
          color: isRunning 
            ? successColor
            : isStarting
              ? warningColor
              : errorColor.withOpacity(0.7),
          fontSize: 12,
        ),
      ),
      trailing: isStarting
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: CyberColors.neonYellow,
            ),
          )
            : ElevatedButton(
            onPressed: isRunning 
              ? () => _confirmStopNode(context, nodeService)
              : () => nodeService.startNode(),
            style: ElevatedButton.styleFrom(
              backgroundColor: isRunning 
                ? errorColor
                : successColor,
              foregroundColor: isDark ? Colors.black : Colors.white,
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
      builder: (ctx) => AlertDialog(
        backgroundColor: CyberTheme.card(context),
        title: Text('Stop Node?', style: TextStyle(color: CyberTheme.textPrimary(context))),
        content: Text(
          'Stopping the node will disconnect you from the P2P network. '
          'You will not receive any data updates while the node is stopped.',
          style: TextStyle(color: CyberTheme.textSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              nodeService.stopNode();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CyberTheme.error(context),
            ),
            child: const Text('Stop Node'),
          ),
        ],
      ),
    );
  }

  void _showRecoveryPhrase(BuildContext context, WalletService walletService, AuthService authService) async {
    // If authentication is set up, require it first
    if (authService.isAuthSetup) {
      final authenticated = await authenticateUser(
        context, 
        authService: authService,
        reason: 'Authenticate to view recovery phrase',
      );
      if (!authenticated) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Authentication required to view recovery phrase',
                style: TextStyle(color: CyberTheme.textPrimary(context)),
              ),
              backgroundColor: CyberTheme.error(context),
            ),
          );
        }
        return;
      }
    }
    
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CyberTheme.card(context),
        title: Text('Warning', style: TextStyle(color: CyberTheme.warning(context))),
        content: Text(
          'Your recovery phrase gives full access to your wallet. Never share it with anyone.',
          style: TextStyle(color: CyberTheme.textPrimary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _displayRecoveryPhrase(context, walletService);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CyberTheme.warning(context),
              foregroundColor: CyberTheme.isDark(context) ? Colors.black : Colors.white,
            ),
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
      backgroundColor: CyberTheme.card(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24, 24, 24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recovery Phrase',
              style: TextStyle(
                color: CyberTheme.textPrimary(context),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CyberTheme.background(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CyberTheme.warning(context).withOpacity(0.3)),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(words.length, (index) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: CyberTheme.card(context),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: CyberTheme.border(context)),
                    ),
                    child: Text(
                      '${index + 1}. ${words[index]}',
                      style: TextStyle(
                        color: CyberTheme.textPrimary(context),
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
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Recovery phrase copied',
                        style: TextStyle(color: CyberTheme.textPrimary(context)),
                      ),
                      backgroundColor: CyberTheme.card(context),
                    ),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy to Clipboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CyberTheme.primary(context),
                  foregroundColor: CyberTheme.isDark(context) ? Colors.black : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, WalletService walletService) async {
    final authService = context.read<AuthService>();
    
    // Always require authentication before allowing wallet deletion
    if (authService.isAuthSetup) {
      final authenticated = await authenticateUser(
        context,
        authService: authService,
        reason: 'Authenticate to delete wallet',
      );
      if (!authenticated) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Authentication required to delete wallet',
                style: TextStyle(color: CyberTheme.textPrimary(context)),
              ),
              backgroundColor: CyberTheme.error(context),
            ),
          );
        }
        return;
      }
    } else {
      // No auth set up - require user to set up PIN first for security
      if (!context.mounted) return;
      final shouldSetupPin = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: CyberTheme.card(context),
          title: Text('Security Required', style: TextStyle(color: CyberTheme.primary(context))),
          content: Text(
            'For security, you must set up a PIN or biometric authentication before deleting your wallet.',
            style: TextStyle(color: CyberTheme.textPrimary(context)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: CyberTheme.primary(context),
              ),
              child: const Text('Set Up PIN'),
            ),
          ],
        ),
      );
      
      if (shouldSetupPin == true && context.mounted) {
        await _setupOrChangePin(context, authService);
      }
      return;
    }
    
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: CyberTheme.card(context),
        title: Text('Reset Wallet', style: TextStyle(color: CyberTheme.error(context))),
        content: Text(
          'This will permanently delete your wallet and all local data. '
          'Make sure you have backed up your recovery phrase. This action cannot be undone.',
          style: TextStyle(color: CyberTheme.textPrimary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              
              // Stop node if running
              final nodeService = context.read<NodeService>();
              if (nodeService.isRunning) {
                await nodeService.stopNode();
              }
              
              // Delete wallet
              await walletService.deleteWallet();
              
              // Also clear PIN/biometric settings
              if (authService.hasPinSet) {
                await authService.removePin();
              }
              
              if (context.mounted) {
                // Navigate back to AppEntryPoint to show wallet setup
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const _WalletResetRedirect(),
                  ),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CyberTheme.error(context),
              foregroundColor: CyberTheme.isDark(context) ? Colors.black : Colors.white,
            ),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
  }

  Future<void> _setupOrChangePin(BuildContext context, AuthService authService) async {
    // If PIN already set, verify current PIN first
    if (authService.hasPinSet) {
      final verified = await PinInputDialog.show(
        context,
        authService: authService,
        title: 'Enter Current PIN',
        subtitle: 'Verify your current PIN to change it',
      );
      if (!verified || !context.mounted) return;
    }
    
    if (!context.mounted) return;
    
    // Set new PIN
    final success = await PinInputDialog.show(
      context,
      authService: authService,
      title: authService.hasPinSet ? 'Set New PIN' : 'Set PIN',
      subtitle: 'Enter a 4-6 digit PIN to protect your wallet',
      isSetup: true,
    );
    
    if (success && context.mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authService.hasPinSet ? 'PIN changed successfully' : 'PIN set successfully'),
          backgroundColor: CyberTheme.success(context),
        ),
      );
    }
  }

  Future<void> _removePin(BuildContext context, AuthService authService) async {
    // Verify current PIN first
    final verified = await PinInputDialog.show(
      context,
      authService: authService,
      title: 'Enter PIN',
      subtitle: 'Verify your PIN to remove it',
    );
    if (!verified || !context.mounted) return;
    
    // Confirm removal
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CyberTheme.card(context),
        title: const Text('Remove PIN?', style: TextStyle(color: Colors.orange)),
        content: Text(
          'This will remove PIN protection from your wallet. Anyone with access to your device will be able to view your recovery phrase.',
          style: TextStyle(color: CyberTheme.textPrimary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await authService.removePin();
      if (context.mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN removed'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
}

/// Widget to redirect to wallet setup after wallet deletion
class _WalletResetRedirect extends StatelessWidget {
  const _WalletResetRedirect();

  @override
  Widget build(BuildContext context) {
    return WalletSetupScreen(
      onWalletCreated: () async {
        // Set wallet keys for node identity
        final walletService = context.read<WalletService>();
        final nodeService = context.read<NodeService>();
        if (walletService.walletInfo != null) {
          await nodeService.setWalletKeys(
            secretKey: walletService.walletInfo!.secretKey,
            publicKey: walletService.walletInfo!.publicKey,
          );
          
          // Start node
          nodeService.startNode().catchError((e) {
            debugPrint('Failed to start node: $e');
          });
        }
        
        if (context.mounted) {
          // Navigate to main screen
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const _MainScreenRedirect()),
            (route) => false,
          );
        }
      },
    );
  }
}

/// Redirect to main screen after wallet creation
class _MainScreenRedirect extends StatelessWidget {
  const _MainScreenRedirect();

  @override
  Widget build(BuildContext context) {
    // Import main_screen here to avoid circular imports
    return const MainScreen();
  }
}
