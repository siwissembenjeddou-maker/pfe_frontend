import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl = TextEditingController();
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
          child: Column(
            children: [
              Expanded(
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
                      child: const Icon(Icons.person_add,
                          size: 60, color: Colors.white),
                    ),
                    const SizedBox(height: 32),
                    const Text('Create Account',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold)),
                    const Text('Join AutiSense today',
                        style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        const Text('Sign Up',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Create a new account to get started',
                            style: TextStyle(color: AppTheme.textSecondary)),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _nameCtrl,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          enabled: !_isLoading,
                        ),
                        const SizedBox(height: 16),
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
                                    ],
                                    onChanged: _isLoading
                                        ? null
                                        : (role) => setState(
                                            () => _selectedRole = role!),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_error != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppTheme.danger.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error,
                                    color: AppTheme.danger, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(_error!,
                                      style: TextStyle(color: AppTheme.danger)),
                                ),
                              ],
                            ),
                          ),
                        if (_error != null) const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.app_registration),
                            label: Text(
                                _isLoading ? 'Creating...' : 'Create Account'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isLoading ? null : _register,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.pushReplacementNamed(
                                  context, '/login'),
                          child: const Text('Already have an account? Sign In'),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _register() async {
    if (_nameCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _passCtrl.text.isEmpty) {
      setState(() => _error = 'Please fill all fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final auth = context.read<AuthService>();
    final result = await auth.register(
      name: _nameCtrl.text,
      email: _emailCtrl.text,
      password: _passCtrl.text,
      role: _selectedRole,
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      final route = switch (_selectedRole) {
        'parent' => '/parent',
        'psychologist' => '/psychologist',
        'educator' => '/educator',
        _ => '/parent',
      };
      if (mounted) Navigator.pushReplacementNamed(context, route);
    } else {
      setState(() => _error = result['message'] ?? 'Registration failed');
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }
}
