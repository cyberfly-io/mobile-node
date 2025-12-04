import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';

/// Dialog for PIN input and verification
class PinInputDialog extends StatefulWidget {
  final AuthService authService;
  final String title;
  final String? subtitle;
  final bool isSetup; // true for setting new PIN, false for verification
  
  const PinInputDialog({
    super.key,
    required this.authService,
    required this.title,
    this.subtitle,
    this.isSetup = false,
  });
  
  /// Show PIN input dialog and return true if authenticated
  static Future<bool> show(
    BuildContext context, {
    required AuthService authService,
    String title = 'Enter PIN',
    String? subtitle,
    bool isSetup = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PinInputDialog(
        authService: authService,
        title: title,
        subtitle: subtitle,
        isSetup: isSetup,
      ),
    );
    return result ?? false;
  }
  
  @override
  State<PinInputDialog> createState() => _PinInputDialogState();
}

class _PinInputDialogState extends State<PinInputDialog> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  String? _error;
  bool _isLoading = false;
  bool _showConfirm = false;
  
  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }
  
  Future<void> _handleSubmit() async {
    final pin = _pinController.text;
    
    if (pin.length < 4) {
      setState(() => _error = 'PIN must be at least 4 digits');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    if (widget.isSetup) {
      if (!_showConfirm) {
        // Show confirmation field
        setState(() {
          _showConfirm = true;
          _isLoading = false;
        });
        return;
      }
      
      // Verify PINs match
      if (pin != _confirmPinController.text) {
        setState(() {
          _error = 'PINs do not match';
          _isLoading = false;
          _confirmPinController.clear();
        });
        return;
      }
      
      // Save new PIN
      final success = await widget.authService.setPin(pin);
      if (success) {
        if (mounted) Navigator.of(context).pop(true);
      } else {
        setState(() {
          _error = 'Failed to save PIN';
          _isLoading = false;
        });
      }
    } else {
      // Verify existing PIN
      final isValid = await widget.authService.verifyPin(pin);
      if (isValid) {
        if (mounted) Navigator.of(context).pop(true);
      } else {
        setState(() {
          _error = 'Incorrect PIN';
          _isLoading = false;
          _pinController.clear();
        });
        HapticFeedback.heavyImpact();
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1D1E33),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.title,
        style: const TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.subtitle != null) ...[
            Text(
              widget.subtitle!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // PIN input
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            autofocus: true,
            enabled: !_showConfirm,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              letterSpacing: 8,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '••••',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 24,
                letterSpacing: 8,
              ),
              counterText: '',
              filled: true,
              fillColor: const Color(0xFF0A0E21),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF00D9FF)),
              ),
            ),
            onSubmitted: (_) {
              if (!_showConfirm) _handleSubmit();
            },
          ),
          
          // Confirm PIN input (for setup)
          if (_showConfirm) ...[
            const SizedBox(height: 16),
            Text(
              'Confirm PIN',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              autofocus: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                letterSpacing: 8,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '••••',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 24,
                  letterSpacing: 8,
                ),
                counterText: '',
                filled: true,
                fillColor: const Color(0xFF0A0E21),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00D9FF)),
                ),
              ),
              onSubmitted: (_) => _handleSubmit(),
            ),
          ],
          
          // Error message
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00D9FF),
            foregroundColor: Colors.black,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_showConfirm ? 'Confirm' : (widget.isSetup ? 'Next' : 'Unlock')),
        ),
      ],
    );
  }
}

/// Helper function to authenticate with PIN or biometrics
Future<bool> authenticateUser(
  BuildContext context, {
  required AuthService authService,
  String reason = 'Authenticate to continue',
}) async {
  final result = await authService.authenticate(reason: reason);
  
  switch (result) {
    case AuthResult.success:
      return true;
    case AuthResult.requirePin:
      if (!context.mounted) return false;
      return await PinInputDialog.show(
        context,
        authService: authService,
        title: 'Enter PIN',
        subtitle: reason,
      );
    case AuthResult.failed:
      return false;
    case AuthResult.notSetup:
      // No auth set up, allow access
      return true;
  }
}
