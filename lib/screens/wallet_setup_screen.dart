import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/wallet_service.dart';
import '../services/auth_service.dart';
import '../widgets/pin_input_dialog.dart';
import '../theme/theme.dart';

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

  // Word verification
  List<int> _verificationIndices = [];
  final List<TextEditingController> _verificationControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  final List<FocusNode> _verificationFocusNodes = [
    FocusNode(),
    FocusNode(),
    FocusNode(),
  ];
  String? _verificationError;

  // Restore wallet state
  int _restoreStep = 0; // 0 = input phrase, 1 = PIN setup
  final List<TextEditingController> _wordControllers = List.generate(
    12,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _wordFocusNodes = List.generate(12, (_) => FocusNode());
  String? _restoreError;
  bool _isRestoring = false;

  @override
  void dispose() {
    _mnemonicController.dispose();
    for (final controller in _verificationControllers) {
      controller.dispose();
    }
    for (final focusNode in _verificationFocusNodes) {
      focusNode.dispose();
    }
    for (final controller in _wordControllers) {
      controller.dispose();
    }
    for (final focusNode in _wordFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = CyberTheme.background(context);

    return Scaffold(
      backgroundColor: backgroundColor,
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
    } else if (_currentStep == 2) {
      return _buildWordVerificationStep();
    } else if (_currentStep == 3) {
      return _buildPinSetupStep();
    } else {
      return _buildConfirmStep();
    }
  }

  Widget _buildWelcomeStep() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primary = CyberTheme.primary(context);
    final onPrimary = isDarkMode ? Colors.black : Colors.white;
    final cardColor = CyberTheme.card(context);
    final textColor = CyberTheme.textPrimary(context);
    final secondaryTextColor = CyberTheme.textSecondary(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.25),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Image.asset('assets/images/logo.png', width: 100, height: 100),
        ),
        const SizedBox(height: 32),
        Text(
          'Welcome to Cyberfly',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Create or restore an account to start your P2P node',
          style: TextStyle(fontSize: 16, color: secondaryTextColor),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _generateNewWallet,
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Create New Account',
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
              foregroundColor: primary,
              side: BorderSide(color: primary),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Restore Existing Account',
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode
        ? const Color(0xFF1D1E33)
        : CyberColorsLight.cardBackground;
    final inputBgColor = isDarkMode
        ? const Color(0xFF0A0E21)
        : CyberColorsLight.inputBackground;
    final textColor = isDarkMode ? Colors.white : CyberColorsLight.textPrimary;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.7)
        : CyberColorsLight.textSecondary;
    final dimTextColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.5)
        : CyberColorsLight.textDim;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Recovery Phrase',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Write down these 24 words in order. Keep them safe and never share them.',
          style: TextStyle(fontSize: 14, color: secondaryTextColor),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
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
                    color: inputBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${index + 1}.',
                        style: TextStyle(color: dimTextColor, fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          words[index],
                          style: TextStyle(
                            color: textColor,
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
                  'Never share your recovery phrase. Anyone with these words can access your account.',
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
          title: Text(
            'I have safely stored my recovery phrase',
            style: TextStyle(color: textColor, fontSize: 14),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: const Color(0xFF00D9FF),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _mnemonicConfirmed ? _goToVerificationStep : null,
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
          content: Text(walletService.error ?? 'Failed to create account'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _goToVerificationStep() {
    // Generate 3 random unique indices for verification
    final words = _previewMnemonic?.split(' ') ?? [];
    final random = Random();
    final indices = <int>{};

    while (indices.length < 3) {
      indices.add(random.nextInt(words.length));
    }

    setState(() {
      _verificationIndices = indices.toList()..sort();
      _verificationError = null;
      for (final controller in _verificationControllers) {
        controller.clear();
      }
      _currentStep = 2;
    });
  }

  Widget _buildWordVerificationStep() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : CyberColorsLight.textPrimary;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.7)
        : CyberColorsLight.textSecondary;
    final cardColor = isDarkMode
        ? const Color(0xFF1D1E33)
        : CyberColorsLight.cardBackground;
    final hintColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.3)
        : CyberColorsLight.textDim;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verify Recovery Phrase',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the following words from your recovery phrase to verify you have saved it correctly.',
          style: TextStyle(fontSize: 14, color: secondaryTextColor),
        ),
        const SizedBox(height: 32),

        // Verification fields with autocomplete
        Expanded(
          child: ListView.separated(
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(height: 24),
            itemBuilder: (context, index) {
              final wordIndex = _verificationIndices[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Word #${wordIndex + 1}',
                    style: const TextStyle(
                      color: Color(0xFF00D9FF),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Autocomplete<String>(
                    optionsBuilder: (textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      final query = textEditingValue.text.toLowerCase();
                      // Suggest from the generated mnemonic words
                      final mnemonicWords = _previewMnemonic?.split(' ') ?? [];
                      return mnemonicWords
                          .where((word) => word.toLowerCase().startsWith(query))
                          .toSet() // Remove duplicates
                          .take(5);
                    },
                    onSelected: (selection) {
                      _verificationControllers[index].text = selection;
                      setState(() => _verificationError = null);
                      // Move to next field
                      if (index < 2) {
                        _verificationFocusNodes[index + 1].requestFocus();
                      }
                    },
                    fieldViewBuilder:
                        (
                          context,
                          textEditingController,
                          focusNode,
                          onFieldSubmitted,
                        ) {
                          // Sync with our controller
                          textEditingController.text =
                              _verificationControllers[index].text;
                          textEditingController.addListener(() {
                            _verificationControllers[index].text =
                                textEditingController.text;
                          });
                          return TextField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            style: TextStyle(color: textColor, fontSize: 18),
                            autocorrect: false,
                            enableSuggestions: false,
                            textInputAction: index < 2
                                ? TextInputAction.next
                                : TextInputAction.done,
                            onSubmitted: (_) {
                              onFieldSubmitted();
                              if (index == 2) _verifyWords();
                            },
                            onChanged: (_) =>
                                setState(() => _verificationError = null),
                            decoration: InputDecoration(
                              hintText: 'Enter word ${wordIndex + 1}',
                              hintStyle: TextStyle(color: hintColor),
                              filled: true,
                              fillColor: cardColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: const Color(
                                    0xFF00D9FF,
                                  ).withValues(alpha: 0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: const Color(
                                    0xFF00D9FF,
                                  ).withValues(alpha: 0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF00D9FF),
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red),
                              ),
                            ),
                          );
                        },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 8,
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxHeight: 200,
                              maxWidth: 280,
                            ),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (context, optionIndex) {
                                final option = options.elementAt(optionIndex);
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    option,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 16,
                                    ),
                                  ),
                                  onTap: () => onSelected(option),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),

        if (_verificationError != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _verificationError!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _verifyWords,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D9FF),
              foregroundColor: Colors.black,
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
            _currentStep = 1;
            _verificationError = null;
          }),
          child: const Text('Back'),
        ),
      ],
    );
  }

  void _verifyWords() {
    final words = _previewMnemonic?.split(' ') ?? [];

    // Check each word
    for (int i = 0; i < 3; i++) {
      final enteredWord = _verificationControllers[i].text.trim().toLowerCase();
      final correctWord = words[_verificationIndices[i]].toLowerCase();

      if (enteredWord.isEmpty) {
        setState(() => _verificationError = 'Please enter all three words');
        return;
      }

      if (enteredWord != correctWord) {
        setState(
          () => _verificationError =
              'Word #${_verificationIndices[i] + 1} is incorrect. Please check your recovery phrase and try again.',
        );
        HapticFeedback.heavyImpact();
        return;
      }
    }

    // All words verified, go to PIN setup
    setState(() => _currentStep = 3);
  }

  Widget _buildPinSetupStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_outline, size: 80, color: Color(0xFF00D9FF)),
        const SizedBox(height: 32),
        const Text(
          'Secure Your Account',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Set up a PIN to protect your Account. You\'ll need this PIN to view your recovery phrase.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _setupPin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D9FF),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Set Up PIN',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() => _currentStep = 2),
          child: const Text('Back'),
        ),
      ],
    );
  }

  Future<void> _setupPin() async {
    final authService = context.read<AuthService>();

    final pinSet = await PinInputDialog.show(
      context,
      authService: authService,
      title: 'Create PIN',
      subtitle: 'Enter a 4-6 digit PIN',
      isSetup: true,
    );

    if (!pinSet) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN is required to create an account'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // PIN set successfully, check if biometric is available
    if (authService.isBiometricAvailable) {
      await _promptBiometricSetup(authService);
    }

    // Create wallet
    await _confirmAndCreateWallet();
  }

  Future<void> _promptBiometricSetup(AuthService authService) async {
    if (!mounted) return;

    final enableBiometric = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.fingerprint, color: Color(0xFF00D9FF), size: 28),
            SizedBox(width: 12),
            Text('Enable Biometrics?', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'Would you like to use fingerprint or face recognition to unlock your account? This is faster and more convenient.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Skip',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D9FF),
              foregroundColor: Colors.black,
            ),
            child: const Text('Enable'),
          ),
        ],
      ),
    );

    if (enableBiometric == true) {
      debugPrint('WalletSetup: User chose to enable biometric');
      // Test biometric before enabling
      final authenticated = await authService.authenticateWithBiometrics(
        reason: 'Verify biometric to enable',
      );
      debugPrint('WalletSetup: Biometric verification result: $authenticated');
      if (authenticated) {
        final result = await authService.setBiometricEnabled(true);
        debugPrint('WalletSetup: setBiometricEnabled result: $result');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric authentication enabled'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        debugPrint('WalletSetup: Biometric verification failed, not enabling');
      }
    } else {
      debugPrint('WalletSetup: User skipped biometric setup');
    }
  }

  Widget _buildConfirmStep() {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF00D9FF)),
    );
  }

  Widget _buildRestoreView() {
    if (_restoreStep == 0) {
      return _buildRestorePhraseInput();
    } else {
      return _buildRestorePinSetup();
    }
  }

  Widget _buildRestorePhraseInput() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primary = CyberTheme.primary(context);
    final textColor = CyberTheme.textPrimary(context);
    final secondaryTextColor = CyberTheme.textSecondary(context);
    final cardColor = CyberTheme.card(context);
    final inputBgColor = isDarkMode
        ? const Color(0xFF0A0E21)
        : CyberColorsLight.inputBackground;
    final hintColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.3)
        : CyberColorsLight.textDim;
    final dimTextColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.5)
        : CyberColorsLight.textDim;

    // Count filled words
    final filledCount = _wordControllers
        .where((c) => c.text.trim().isNotEmpty)
        .length;
    final isValid = filledCount == 12; // Exactly 12 words required

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with back button
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() {
                _showRestoreOption = false;
                _restoreStep = 0;
                _restoreError = null;
                for (final controller in _wordControllers) {
                  controller.clear();
                }
              }),
              icon: Icon(Icons.arrow_back, color: textColor),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Restore Account',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enter your 12-word recovery phrase',
                    style: TextStyle(fontSize: 14, color: secondaryTextColor),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Progress indicator
        Row(
          children: [
            Text(
              '$filledCount/12 words',
              style: TextStyle(
                color: filledCount == 12 ? primary : secondaryTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: filledCount / 12,
                  backgroundColor: cardColor,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    filledCount == 12 ? primary : secondaryTextColor,
                  ),
                  minHeight: 4,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Word grid
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _restoreError != null
                    ? Colors.red.withValues(alpha: 0.5)
                    : primary.withValues(alpha: 0.3),
              ),
            ),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 12,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: inputBgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: _wordFocusNodes[index].hasFocus
                        ? Border.all(color: primary, width: 1.5)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: dimTextColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _wordControllers[index],
                          focusNode: _wordFocusNodes[index],
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'word',
                            hintStyle: TextStyle(
                              color: hintColor,
                              fontSize: 12,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                          ),
                          textInputAction: index < 11
                              ? TextInputAction.next
                              : TextInputAction.done,
                          autocorrect: false,
                          enableSuggestions: false,
                          onChanged: (_) {
                            setState(() {
                              _restoreError = null;
                            });
                          },
                          onSubmitted: (_) {
                            if (index < 11) {
                              _wordFocusNodes[index + 1].requestFocus();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        // Error message
        if (_restoreError != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _restoreError!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pasteRecoveryPhrase,
                icon: const Icon(Icons.paste, size: 18),
                label: const Text('Paste'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: BorderSide(color: primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  for (final controller in _wordControllers) {
                    controller.clear();
                  }
                  setState(() {
                    _restoreError = null;
                  });
                },
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Clear'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: secondaryTextColor,
                  side: BorderSide(
                    color: secondaryTextColor.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Restore button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isRestoring || !isValid ? null : _validateAndRestore,
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: isDarkMode ? Colors.black : Colors.white,
              disabledBackgroundColor: isDarkMode
                  ? Colors.grey.shade800
                  : Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isRestoring
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Restore Account',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  void _pasteRecoveryPhrase() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text == null) return;

    final text = clipboardData!.text!.trim();
    final words = text
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    if (words.isEmpty) return;

    setState(() {
      // Clear all first
      for (final controller in _wordControllers) {
        controller.clear();
      }
      // Fill in the words
      for (int i = 0; i < words.length && i < 12; i++) {
        _wordControllers[i].text = words[i].toLowerCase();
      }
      _restoreError = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pasted ${words.length} words'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _validateAndRestore() async {
    // Collect words
    final words = _wordControllers
        .map((c) => c.text.trim().toLowerCase())
        .where((w) => w.isNotEmpty)
        .toList();

    // Validate word count
    if (words.length != 12) {
      setState(() {
        _restoreError =
            'Please enter exactly 12 words. You entered ${words.length} words.';
      });
      return;
    }

    setState(() {
      _isRestoring = true;
      _restoreError = null;
    });

    // Validate the mnemonic first without restoring
    final walletService = context.read<WalletService>();
    final mnemonic = words.join(' ');
    
    if (!walletService.validateMnemonic(mnemonic)) {
      if (!mounted) return;
      setState(() {
        _isRestoring = false;
        _restoreError = 'Invalid recovery phrase. Please check your words and try again.';
      });
      return;
    }

    setState(() {
      _isRestoring = false;
    });

    // Mnemonic is valid, now set up PIN (same flow as create account)
    await _setupPinForRestore(mnemonic);
  }

  Future<void> _setupPinForRestore(String mnemonic) async {
    final authService = context.read<AuthService>();

    final pinSet = await PinInputDialog.show(
      context,
      authService: authService,
      title: 'Create PIN',
      subtitle: 'Enter a 4-6 digit PIN to protect your account',
      isSetup: true,
    );

    if (!pinSet) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN is required to restore your account'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // PIN set successfully, check if biometric is available
    if (authService.isBiometricAvailable) {
      await _promptBiometricSetup(authService);
    }

    // Now restore the wallet
    await _performRestore(mnemonic);
  }

  Future<void> _performRestore(String mnemonic) async {
    setState(() {
      _isRestoring = true;
    });

    final walletService = context.read<WalletService>();
    final wallet = await walletService.restoreWallet(mnemonic);

    if (!mounted) return;

    setState(() {
      _isRestoring = false;
    });

    if (wallet != null) {
      widget.onWalletCreated();
    } else {
      setState(() {
        _restoreError =
            walletService.error ??
            'Failed to restore wallet. Please try again.';
      });
    }
  }

  Widget _buildRestorePinSetup() {
    // This step is optional, we can directly restore for now
    return Container();
  }
}
