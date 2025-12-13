import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/auth_service.dart';
import '../services/wallet_service.dart';
import '../services/kadena_service.dart';
import '../widgets/pin_input_dialog.dart';
import '../theme/theme.dart';

/// Send screen for transferring CFLY tokens
class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSending = false;
  double? _cflyBalance;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadBalance() async {
    final walletService = context.read<WalletService>();
    final kadenaService = context.read<KadenaService>();
    
    if (!walletService.hasWallet) return;
    
    setState(() => _isLoading = true);
    
    try {
      final balance = await kadenaService.getCFLYBalance(walletService.account ?? '');
      if (mounted) {
        setState(() {
          _cflyBalance = balance;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load balance';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openQRScanner() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const _QRScannerScreen(),
      ),
    );
    
    if (result != null && mounted) {
      setState(() {
        _recipientController.text = result;
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && mounted) {
      final text = data!.text!.trim();
      // Validate if it's a k: address
      if (text.startsWith('k:') && text.length >= 66) {
        setState(() {
          _recipientController.text = text;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invalid Kadena address in clipboard'),
            backgroundColor: CyberTheme.error(context),
          ),
        );
      }
    }
  }

  Future<void> _sendTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    
    final walletService = context.read<WalletService>();
    final kadenaService = context.read<KadenaService>();
    final authService = context.read<AuthService>();
    
    if (!walletService.hasWallet) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Wallet not connected'),
          backgroundColor: CyberTheme.error(context),
        ),
      );
      return;
    }
    
    // Authenticate before sending
    final authenticated = await authenticateUser(
      context,
      authService: authService,
      reason: 'Authenticate to send CFLY',
    );
    
    if (!authenticated || !mounted) return;
    
    setState(() => _isSending = true);
    
    try {
      final recipient = _recipientController.text.trim();
      final amount = double.parse(_amountController.text.trim());
      
      final success = await kadenaService.transferCFLY(
        toAccount: recipient,
        amount: amount,
      );
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Transfer of ${amount.toStringAsFixed(2)} CFLY submitted!'),
              backgroundColor: CyberTheme.success(context),
            ),
          );
          // Clear form and refresh balance
          _recipientController.clear();
          _amountController.clear();
          await _loadBalance();
          // Go back after successful transfer
          if (mounted) Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Transfer failed: ${kadenaService.error ?? 'Unknown error'}'),
              backgroundColor: CyberTheme.error(context),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: CyberTheme.error(context),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _setMaxAmount() {
    if (_cflyBalance != null && _cflyBalance! > 0) {
      setState(() {
        _amountController.text = _cflyBalance!.toStringAsFixed(8);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CyberTheme.isDark(context);
    final primaryColor = CyberTheme.primary(context);
    final magentaColor = isDark ? CyberColors.neonMagenta : CyberColorsLight.primaryMagenta;
    final onPrimary = isDark ? Colors.black : Colors.white;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Send CFLY',
          style: TextStyle(
            color: CyberTheme.textPrimary(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: CyberTheme.textPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Balance Card
                _buildBalanceCard(isDark, magentaColor),
                
                const SizedBox(height: 24),
                
                // Recipient Section
                _buildSectionHeader('Recipient Address'),
                const SizedBox(height: 8),
                _buildRecipientField(isDark, magentaColor),
                
                const SizedBox(height: 8),
                
                // Quick Actions Row
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionButton(
                        icon: Icons.qr_code_scanner,
                        label: 'Scan QR',
                        onTap: _openQRScanner,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionButton(
                        icon: Icons.content_paste,
                        label: 'Paste',
                        onTap: _pasteFromClipboard,
                        color: magentaColor,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Amount Section
                _buildSectionHeader('Amount'),
                const SizedBox(height: 8),
                _buildAmountField(isDark, magentaColor),
                
                const SizedBox(height: 32),
                
                // Send Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSending ? null : _sendTransaction,
                    icon: _isSending 
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: onPrimary,
                            ),
                          )
                        : const Icon(Icons.send),
                    label: Text(_isSending ? 'Sending...' : 'Send CFLY'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: magentaColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: magentaColor.withOpacity(0.5),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Info Box
                _buildInfoBox(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(bool isDark, Color magentaColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CyberTheme.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: magentaColor.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: magentaColor.withOpacity(isDark ? 0.1 : 0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: magentaColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.account_balance_wallet,
              color: magentaColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available Balance',
                  style: TextStyle(
                    fontSize: 12,
                    color: CyberTheme.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 4),
                _isLoading
                    ? SizedBox(
                        height: 24,
                        width: 100,
                        child: LinearProgressIndicator(
                          color: magentaColor,
                          backgroundColor: magentaColor.withOpacity(0.2),
                        ),
                      )
                    : Text(
                        '${_cflyBalance?.toStringAsFixed(4) ?? '0.0000'} CFLY',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: CyberTheme.textPrimary(context),
                          fontFamily: 'monospace',
                        ),
                      ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadBalance,
            icon: Icon(
              Icons.refresh,
              color: CyberTheme.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: CyberTheme.textSecondary(context),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildRecipientField(bool isDark, Color magentaColor) {
    return TextFormField(
      controller: _recipientController,
      style: TextStyle(
        color: CyberTheme.textPrimary(context),
        fontFamily: 'monospace',
        fontSize: 13,
      ),
      decoration: InputDecoration(
        hintText: 'k:...',
        hintStyle: TextStyle(
          color: CyberTheme.textDim(context).withOpacity(0.5),
        ),
        prefixIcon: Icon(Icons.person_outline, color: magentaColor),
        filled: true,
        fillColor: CyberTheme.card(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: magentaColor.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: magentaColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: magentaColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: CyberTheme.error(context)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: CyberTheme.error(context), width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter recipient address';
        }
        if (!value.startsWith('k:') || value.length < 66) {
          return 'Invalid Kadena address (must start with k:)';
        }
        return null;
      },
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountField(bool isDark, Color magentaColor) {
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(
        color: CyberTheme.textPrimary(context),
        fontFamily: 'monospace',
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: '0.00',
        hintStyle: TextStyle(
          color: CyberTheme.textDim(context).withOpacity(0.5),
        ),
        prefixIcon: Icon(Icons.token, color: magentaColor),
        suffixIcon: TextButton(
          onPressed: _setMaxAmount,
          child: Text(
            'MAX',
            style: TextStyle(
              color: magentaColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        filled: true,
        fillColor: CyberTheme.card(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: magentaColor.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: magentaColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: magentaColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: CyberTheme.error(context)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: CyberTheme.error(context), width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter amount';
        }
        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) {
          return 'Please enter a valid amount';
        }
        if (_cflyBalance != null && amount > _cflyBalance!) {
          return 'Insufficient balance';
        }
        return null;
      },
    );
  }

  Widget _buildInfoBox(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CyberTheme.primary(context).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CyberTheme.primary(context).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: CyberTheme.primary(context),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Gas fees are paid by the Cyberfly gas station. Transactions typically confirm within 30 seconds.',
              style: TextStyle(
                fontSize: 12,
                color: CyberTheme.textSecondary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// QR Scanner Screen
class _QRScannerScreen extends StatefulWidget {
  const _QRScannerScreen();

  @override
  State<_QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<_QRScannerScreen> {
  MobileScannerController? _controller;
  bool _hasScanned = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    
    final barcode = barcodes.first;
    final value = barcode.rawValue;
    
    if (value == null || value.isEmpty) return;
    
    // Check if it's a valid k: address
    String address = value;
    
    // Handle various QR code formats
    // Direct k: address
    if (value.startsWith('k:') && value.length >= 66) {
      address = value;
    }
    // kadena: URI scheme (kadena:k:address or kadena://k:address)
    else if (value.toLowerCase().startsWith('kadena:')) {
      final uri = value.replaceFirst(RegExp(r'^kadena:/?/?', caseSensitive: false), '');
      if (uri.startsWith('k:') && uri.length >= 66) {
        address = uri.split('?').first; // Remove any query params
      } else {
        setState(() => _errorMessage = 'Invalid Kadena URI format');
        return;
      }
    }
    // Check if the scanned value contains a k: address anywhere
    else {
      final kAddressMatch = RegExp(r'k:[a-fA-F0-9]{64}').firstMatch(value);
      if (kAddressMatch != null) {
        address = kAddressMatch.group(0)!;
      } else {
        setState(() => _errorMessage = 'No valid k: address found in QR code');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _errorMessage = null);
        });
        return;
      }
    }
    
    _hasScanned = true;
    Navigator.pop(context, address);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CyberTheme.isDark(context);
    final primaryColor = CyberTheme.primary(context);
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Scan QR Code',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () => _controller?.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch, color: Colors.white),
            onPressed: () => _controller?.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Preview
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          
          // Overlay with scanning area
          CustomPaint(
            painter: _ScannerOverlayPainter(
              borderColor: primaryColor,
              overlayColor: Colors.black.withOpacity(0.5),
            ),
            child: const SizedBox.expand(),
          ),
          
          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Scan a Kadena address QR code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Hint at bottom
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Looking for k:address format',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for scanner overlay
class _ScannerOverlayPainter extends CustomPainter {
  final Color borderColor;
  final Color overlayColor;

  _ScannerOverlayPainter({
    required this.borderColor,
    required this.overlayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scanAreaSize = size.width * 0.7;
    final scanAreaLeft = (size.width - scanAreaSize) / 2;
    final scanAreaTop = (size.height - scanAreaSize) / 2;
    
    final scanRect = Rect.fromLTWH(
      scanAreaLeft,
      scanAreaTop,
      scanAreaSize,
      scanAreaSize,
    );
    
    // Draw semi-transparent overlay
    final overlayPaint = Paint()..color = overlayColor;
    
    // Top
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, scanAreaTop),
      overlayPaint,
    );
    // Bottom
    canvas.drawRect(
      Rect.fromLTWH(0, scanAreaTop + scanAreaSize, size.width, size.height - scanAreaTop - scanAreaSize),
      overlayPaint,
    );
    // Left
    canvas.drawRect(
      Rect.fromLTWH(0, scanAreaTop, scanAreaLeft, scanAreaSize),
      overlayPaint,
    );
    // Right
    canvas.drawRect(
      Rect.fromLTWH(scanAreaLeft + scanAreaSize, scanAreaTop, scanAreaLeft, scanAreaSize),
      overlayPaint,
    );
    
    // Draw corner brackets
    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    
    final cornerLength = 30.0;
    final path = Path();
    
    // Top-left corner
    path.moveTo(scanRect.left, scanRect.top + cornerLength);
    path.lineTo(scanRect.left, scanRect.top);
    path.lineTo(scanRect.left + cornerLength, scanRect.top);
    
    // Top-right corner
    path.moveTo(scanRect.right - cornerLength, scanRect.top);
    path.lineTo(scanRect.right, scanRect.top);
    path.lineTo(scanRect.right, scanRect.top + cornerLength);
    
    // Bottom-right corner
    path.moveTo(scanRect.right, scanRect.bottom - cornerLength);
    path.lineTo(scanRect.right, scanRect.bottom);
    path.lineTo(scanRect.right - cornerLength, scanRect.bottom);
    
    // Bottom-left corner
    path.moveTo(scanRect.left + cornerLength, scanRect.bottom);
    path.lineTo(scanRect.left, scanRect.bottom);
    path.lineTo(scanRect.left, scanRect.bottom - cornerLength);
    
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
