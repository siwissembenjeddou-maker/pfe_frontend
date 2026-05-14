import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _selectedRole = 'parent';
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // Logo & Title
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.psychology,
                                      size: 60, color: Colors.white),
                                ),
                                const SizedBox(height: 32),
                                const Text('AutiSense',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold)),
                                const Text('Autism Assessment Platform',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 16)),
                              ],
                            ),
                          ),
                        ),

                        // Login Form
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(32)),
                          ),
                          child: Column(
                            children: [
                              const Text('Welcome Back',
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              const Text('Sign in to your account',
                                  style:
                                      TextStyle(color: AppTheme.textSecondary)),
                              const SizedBox(height: 32),

                              // Role Selector
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.account_circle,
                                        color: AppTheme.primary),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _selectedRole,
                                          items: const [
                                            DropdownMenuItem(
                                                value: 'parent',
                                                child: Text('Parent')),
                                            DropdownMenuItem(
                                                value: 'psychologist',
                                                child: Text('Psychologist')),
                                            DropdownMenuItem(
                                                value: 'educator',
                                                child: Text('Educator')),
                                            DropdownMenuItem(
                                                value: 'admin',
                                                child: Text('Admin')),
                                          ],
                                          onChanged: _isLoading
                                              ? null
                                              : (v) => setState(
                                                  () => _selectedRole = v!),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Email
                              TextField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: const Icon(Icons.email),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                enabled: !_isLoading,
                              ),
                              const SizedBox(height: 16),

                              // Password
                              TextField(
                                controller: _passCtrl,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                enabled: !_isLoading,
                              ),
                              const SizedBox(height: 24),

                              // Error message
                              if (_error != null)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.danger.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: AppTheme.danger
                                            .withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error,
                                          color: AppTheme.danger, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                          child: Text(_error!,
                                              style: TextStyle(
                                                  color: AppTheme.danger))),
                                    ],
                                  ),
                                ),
                              if (_error != null) const SizedBox(height: 16),

                              // Login Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton.icon(
                                  icon: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white))
                                      : const Icon(Icons.login),
                                  label: Text(
                                      _isLoading ? 'Signing In...' : 'Sign In'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  onPressed: _isLoading ? null : _login,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => Navigator.pushReplacementNamed(
                                        context, '/signup'),
                                child: const Text('Create a new account'),
                              ),
                              const SizedBox(height: 16),
                              // Footer
                              const Text('Secure & Private',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'Please fill all fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final auth = context.read<AuthService>();
    final result =
        await auth.login(_emailCtrl.text, _passCtrl.text, _selectedRole);

    setState(() => _isLoading = false);

    if (result['success']) {
      final String route;
      switch (_selectedRole) {
        case 'parent':
          route = '/parent';
          break;
        case 'psychologist':
          route = '/psychologist';
          break;
        case 'educator':
          route = '/educator';
          break;
        case 'admin':
          route = '/admin';
          break;
        default:
          route = '/parent';
      }
      if (mounted) Navigator.pushReplacementNamed(context, route);
    } else {
      setState(() => _error = result['message'] ?? 'Login failed');
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }
}
