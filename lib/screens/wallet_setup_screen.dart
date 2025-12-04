import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/wallet_service.dart';

/// Wallet setup screen - shown when no wallet exists
class WalletSetupScreen extends StatefulWidget {
  final VoidCallback onWalletCreated;

  const WalletSetupScreen({super.key, required this.onWalletCreated});

  @override
  State<WalletSetupScreen> createState() => _WalletSetupScreenState();
}

class _WalletSetupScreenState extends State<WalletSetupScreen> {
  bool _showRestoreOption = false;
  final _mnemonicController = TextEditingController();
  String? _previewMnemonic;
  bool _mnemonicConfirmed = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _mnemonicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _showRestoreOption ? _buildRestoreView() : _buildCreateView(),
        ),
      ),
    );
  }

  Widget _buildCreateView() {
    if (_currentStep == 0) {
      return _buildWelcomeStep();
    } else if (_currentStep == 1) {
      return _buildMnemonicDisplayStep();
    } else {
      return _buildConfirmStep();
    }
  }

  Widget _buildWelcomeStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.account_balance_wallet_outlined,
          size: 100,
          color: Color(0xFF00D9FF),
        ),
        const SizedBox(height: 32),
        const Text(
          'Welcome to Cyberfly',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Create or restore a wallet to start your P2P node',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _generateNewWallet,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D9FF),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Create New Wallet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => setState(() => _showRestoreOption = true),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF00D9FF),
              side: const BorderSide(color: Color(0xFF00D9FF)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Restore Existing Wallet',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
      ],
    );
  }

  void _generateNewWallet() {
    final walletService = context.read<WalletService>();
    setState(() {
      _previewMnemonic = walletService.generateMnemonic();
      _currentStep = 1;
    });
  }

  Widget _buildMnemonicDisplayStep() {
    final words = _previewMnemonic?.split(' ') ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Recovery Phrase',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Write down these 24 words in order. Keep them safe and never share them.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1D1E33),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF00D9FF).withValues(alpha: 0.3),
              ),
            ),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: words.length,
              itemBuilder: (context, index) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0E21),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${index + 1}.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          words[index],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
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
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: _previewMnemonic ?? ''),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF00D9FF),
                  side: const BorderSide(color: Color(0xFF00D9FF)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Never share your recovery phrase. Anyone with these words can access your wallet.',
                  style: TextStyle(color: Colors.orange.shade200, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        CheckboxListTile(
          value: _mnemonicConfirmed,
          onChanged: (value) =>
              setState(() => _mnemonicConfirmed = value ?? false),
          title: const Text(
            'I have safely stored my recovery phrase',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: const Color(0xFF00D9FF),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _mnemonicConfirmed ? _confirmAndCreateWallet : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D9FF),
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.grey.shade800,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() {
            _currentStep = 0;
            _previewMnemonic = null;
            _mnemonicConfirmed = false;
          }),
          child: const Text('Back'),
        ),
      ],
    );
  }

  Future<void> _confirmAndCreateWallet() async {
    if (_previewMnemonic == null) return;

    final walletService = context.read<WalletService>();
    final wallet = await walletService.restoreWallet(_previewMnemonic!);

    if (wallet != null && mounted) {
      widget.onWalletCreated();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(walletService.error ?? 'Failed to create wallet'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildConfirmStep() {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF00D9FF)),
    );
  }

  Widget _buildRestoreView() {
    final walletService = context.watch<WalletService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() {
                _showRestoreOption = false;
                _mnemonicController.clear();
              }),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            const Text(
              'Restore Wallet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Enter your 24-word recovery phrase to restore your wallet',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1D1E33),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: walletService.error != null
                    ? Colors.red.withValues(alpha: 0.5)
                    : const Color(0xFF00D9FF).withValues(alpha: 0.3),
              ),
            ),
            child: TextField(
              controller: _mnemonicController,
              maxLines: null,
              expands: true,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText:
                    'Enter your recovery phrase (24 words separated by spaces)',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                border: InputBorder.none,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
        if (walletService.error != null) ...[
          const SizedBox(height: 8),
          Text(
            walletService.error!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed:
                walletService.isLoading ||
                    _mnemonicController.text.trim().split(' ').length < 12
                ? null
                : _restoreWallet,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D9FF),
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.grey.shade800,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: walletService.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Restore Wallet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _restoreWallet() async {
    final walletService = context.read<WalletService>();
    final wallet = await walletService.restoreWallet(_mnemonicController.text);

    if (wallet != null && mounted) {
      widget.onWalletCreated();
    }
  }
}
