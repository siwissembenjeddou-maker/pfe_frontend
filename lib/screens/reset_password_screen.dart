import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String code;

  const ResetPasswordScreen(
      {super.key, required this.email, required this.code});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

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
                        child: const Icon(Icons.lock_open,
                            size: 56, color: Colors.white),
                      ),
                      const SizedBox(height: 24),
                      const Text('Create New Password',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              height: 1.2)),
                      const SizedBox(height: 12),
                      const Text(
                        'Enter a strong password to secure your account.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
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
                      const Text('New Password',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary)),
                      const SizedBox(height: 8),
                      const Text(
                        'Choose a strong password with at least 8 characters.',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 28),

                      // New password field
                      TextField(
                        controller: _passCtrl,
                        obscureText: !_showPassword,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_showPassword
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () =>
                                setState(() => _showPassword = !_showPassword),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 20),
                          labelStyle: const TextStyle(fontSize: 16),
                        ),
                        enabled: !_isLoading,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 24),

                      // Confirm password field
                      TextField(
                        controller: _confirmPassCtrl,
                        obscureText: !_showConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_showConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () => setState(() =>
                                _showConfirmPassword = !_showConfirmPassword),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 20),
                          labelStyle: const TextStyle(fontSize: 16),
                        ),
                        enabled: !_isLoading,
                        style: const TextStyle(fontSize: 18),
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

                      // Reset button
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
                              : const Icon(Icons.check_circle, size: 28),
                          label: Text(
                            _isLoading
                                ? 'Resetting Password...'
                                : 'Reset Password',
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
                          onPressed: _isLoading ? null : _resetPassword,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Back to login
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pushNamedAndRemoveUntil(
                                context, '/login', (route) => false),
                        child: const Text(
                          'Back to Sign In',
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

  Future<void> _resetPassword() async {
    if (_passCtrl.text.isEmpty || _confirmPassCtrl.text.isEmpty) {
      setState(() => _error = 'Please fill all password fields');
      return;
    }

    if (_passCtrl.text.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters');
      return;
    }

    if (_passCtrl.text != _confirmPassCtrl.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await ApiService.resetPassword(
        widget.email, widget.code, _passCtrl.text);

    if (mounted) {
      setState(() => _isLoading = false);

      if (result['success']) {
        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset successfully! Please sign in.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          // Navigate back to login
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/login', (route) => false);
          }
        }
      } else {
        setState(
            () => _error = result['message'] ?? 'Failed to reset password');
      }
    }
  }

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }
}
