import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';

class VerifyResetCodeScreen extends StatefulWidget {
  final String email;

  const VerifyResetCodeScreen({super.key, required this.email});

  @override
  State<VerifyResetCodeScreen> createState() => _VerifyResetCodeScreenState();
}

class _VerifyResetCodeScreenState extends State<VerifyResetCodeScreen> {
  final _codeCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Header section
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.25),
                              blurRadius: 20,
                              spreadRadius: 5,
                            )
                          ],
                        ),
                        child: const Icon(Icons.verified_user,
                            size: 56, color: Colors.white),
                      ),
                      const SizedBox(height: 24),
                      const Text('Verify Your Code',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              height: 1.2)),
                      const SizedBox(height: 12),
                      Text(
                        'We sent a verification code to ${widget.email}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 16, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Form section
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.18),
                        blurRadius: 32,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Enter Verification Code',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary)),
                      const SizedBox(height: 8),
                      const Text(
                        'Check your email for the 6-digit code (expires in 10 minutes).',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 28),

                      // Code field
                      TextField(
                        controller: _codeCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          labelText: 'Verification Code',
                          counterText: '',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 20),
                          labelStyle: const TextStyle(fontSize: 16),
                        ),
                        enabled: !_isLoading,
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8),
                      ),
                      const SizedBox(height: 20),

                      // Error message
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppTheme.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.danger.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.error_outline,
                                  color: AppTheme.danger, size: 24),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(_error!,
                                    style: TextStyle(
                                        color: AppTheme.danger,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Verify button
                      SizedBox(
                        height: 66,
                        child: ElevatedButton.icon(
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white),
                                )
                              : const Icon(Icons.check_circle_outline,
                                  size: 28),
                          label: Text(
                            _isLoading ? 'Verifying...' : 'Verify Code',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: _isLoading ? null : _verifyCode,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Back button
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text(
                          'Back',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _verifyCode() async {
    if (_codeCtrl.text.isEmpty || _codeCtrl.text.length != 6) {
      setState(() => _error = 'Please enter a valid 6-digit code');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result =
        await ApiService.verifyResetCode(widget.email, _codeCtrl.text);

    if (mounted) {
      setState(() => _isLoading = false);

      if (result['success']) {
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/reset-password',
            arguments: {'email': widget.email, 'code': _codeCtrl.text},
          );
        }
      } else {
        setState(() => _error =
            result['message'] ?? 'Invalid or expired verification code');
      }
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }
}
