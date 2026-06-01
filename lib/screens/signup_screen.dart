import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _selectedRole = 'parent';
  bool _isLoading = false;
  String? _error;

  late final AnimationController _animationController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
              decoration:
                  const BoxDecoration(gradient: AppTheme.primaryGradient)),
          Positioned(
            right: -60,
            top: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.18),
                    Colors.white.withOpacity(0.04)
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: -70,
            bottom: -70,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.14),
                    Colors.white.withOpacity(0.02)
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.18)),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 140,
                                  height: 140,
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
                                  child: const Icon(Icons.person_add,
                                      size: 72, color: Colors.white),
                                ),
                                const SizedBox(height: 36),
                                const Text('Create your AutiSense account',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 40,
                                        fontWeight: FontWeight.w900,
                                        height: 1.2,
                                        letterSpacing: 0.5)),
                                const SizedBox(height: 16),
                                const Text(
                                  'Start your journey with a secure, supportive autism assessment experience.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 18,
                                      height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
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
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 22, horizontal: 28),
                                  decoration: const BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(32)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: const [
                                      Text('Sign Up',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 32,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5)),
                                      SizedBox(height: 10),
                                      Text(
                                        'Personalize your access with a role and secure password.',
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 16,
                                            height: 1.4),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(32, 36, 32, 32),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      TextField(
                                        controller: _nameCtrl,
                                        decoration: InputDecoration(
                                          labelText: 'Full Name',
                                          prefixIcon: const Icon(Icons.person),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 20, vertical: 20),
                                          labelStyle:
                                              const TextStyle(fontSize: 16),
                                        ),
                                        enabled: !_isLoading,
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                      const SizedBox(height: 24),
                                      TextField(
                                        controller: _emailCtrl,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        decoration: InputDecoration(
                                          labelText: 'Email',
                                          prefixIcon: const Icon(Icons.email),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 20, vertical: 20),
                                          labelStyle:
                                              const TextStyle(fontSize: 16),
                                        ),
                                        enabled: !_isLoading,
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                      const SizedBox(height: 24),
                                      TextField(
                                        controller: _passCtrl,
                                        obscureText: true,
                                        decoration: InputDecoration(
                                          labelText: 'Password',
                                          prefixIcon: const Icon(Icons.lock),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 20, vertical: 20),
                                          labelStyle:
                                              const TextStyle(fontSize: 16),
                                        ),
                                        enabled: !_isLoading,
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                      const SizedBox(height: 32),
                                      const Text('Choose your role',
                                          style: TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 17)),
                                      const SizedBox(height: 16),
                                      Wrap(
                                        spacing: 14,
                                        runSpacing: 14,
                                        children: [
                                          _buildRoleChip('parent', 'Parent'),
                                          _buildRoleChip(
                                              'psychologist', 'Psychologist'),
                                        ],
                                      ),
                                      if (_error != null) ...[
                                        const SizedBox(height: 28),
                                        Container(
                                          padding: const EdgeInsets.all(18),
                                          decoration: BoxDecoration(
                                            color: AppTheme.danger
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                              color: AppTheme.danger
                                                  .withValues(alpha: 0.25),
                                            ),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(Icons.error_outline,
                                                  color: AppTheme.danger,
                                                  size: 24),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Text(_error!,
                                                    style: TextStyle(
                                                        color: AppTheme.danger,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w500)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 32),
                                      SizedBox(
                                        height: 66,
                                        child: ElevatedButton.icon(
                                          icon: _isLoading
                                              ? const SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2.5,
                                                          color: Colors.white),
                                                )
                                              : const Icon(
                                                  Icons.app_registration,
                                                  size: 28),
                                          label: Text(
                                            _isLoading
                                                ? 'Creating account...'
                                                : 'Create Account',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.primary,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                            ),
                                          ),
                                          onPressed:
                                              _isLoading ? null : _register,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      TextButton(
                                        onPressed: _isLoading
                                            ? null
                                            : () =>
                                                Navigator.pushReplacementNamed(
                                                    context, '/login'),
                                        child: const Text(
                                          'Already have an account? Sign In',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Your privacy is secure with us.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(String value, String label) {
    final selected = _selectedRole == value;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (selected)
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 2,
            )
        ],
      ),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: _isLoading
            ? null
            : (isSelected) {
                if (isSelected) {
                  setState(() => _selectedRole = value);
                }
              },
        selectedColor: AppTheme.primary,
        backgroundColor: AppTheme.surface,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppTheme.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color:
                selected ? AppTheme.primary : AppTheme.primary.withOpacity(0.2),
            width: selected ? 2 : 1.5,
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
        _ => '/parent',
      };
      if (mounted) Navigator.pushReplacementNamed(context, route);
    } else {
      setState(() => _error = result['message'] ?? 'Registration failed');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }
}
