import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _showPassword = false;

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
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo & Branding Section
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            children: [
                              Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.25),
                                      blurRadius: 25,
                                      spreadRadius: 8,
                                    )
                                  ],
                                ),
                                child: const Icon(Icons.psychology,
                                    size: 72, color: Colors.white),
                              ),
                              const SizedBox(height: 36),
                              const Text('AutiSense',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 48,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5)),
                              const SizedBox(height: 8),
                              const Text(
                                'Autism Assessment Platform',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                    letterSpacing: 0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Login Form Container
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(36),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(36),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withOpacity(0.2),
                                  blurRadius: 40,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text('Welcome Back',
                                    style: TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 32,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5)),
                                const SizedBox(height: 10),
                                const Text(
                                  'Sign in to access your assessment dashboard',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 15,
                                      height: 1.5),
                                ),
                                const SizedBox(height: 36),

                                // Email Field
                                TextField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: 'Email Address',
                                    prefixIcon:
                                        const Icon(Icons.email_outlined),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 18),
                                    labelStyle: const TextStyle(fontSize: 15),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                            color: Color(0xFFE0E0E0))),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                            color: Color(0xFFE0E0E0),
                                            width: 1.5)),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                            color: AppTheme.primary, width: 2)),
                                  ),
                                  enabled: !_isLoading,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 20),

                                // Password Field
                                TextField(
                                  controller: _passCtrl,
                                  obscureText: !_showPassword,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock_outlined),
                                    suffixIcon: IconButton(
                                      icon: Icon(_showPassword
                                          ? Icons.visibility
                                          : Icons.visibility_off),
                                      onPressed: () => setState(
                                          () => _showPassword = !_showPassword),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 18),
                                    labelStyle: const TextStyle(fontSize: 15),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                            color: Color(0xFFE0E0E0))),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                            color: Color(0xFFE0E0E0),
                                            width: 1.5)),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                            color: AppTheme.primary, width: 2)),
                                  ),
                                  enabled: !_isLoading,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 14),

                                // Forgot Password Link
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () => Navigator.of(context)
                                            .pushNamed('/forgot-password'),
                                    child: const Text(
                                      'Forgot your password?',
                                      style: TextStyle(
                                        color: AppTheme.primary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Error Message
                                if (_error != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.danger
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppTheme.danger
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.error_outline,
                                            color: AppTheme.danger, size: 22),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(_error!,
                                              style: TextStyle(
                                                  color: AppTheme.danger,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],

                                // Sign In Button
                                SizedBox(
                                  height: 64,
                                  child: ElevatedButton.icon(
                                    icon: _isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white),
                                          )
                                        : const Icon(Icons.login_outlined,
                                            size: 26),
                                    label: Text(
                                      _isLoading ? 'Signing In...' : 'Sign In',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(18)),
                                    ),
                                    onPressed: _isLoading ? null : _login,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Divider
                                Row(
                                  children: [
                                    Expanded(
                                        child: Divider(
                                            color: Colors.grey[300],
                                            thickness: 1)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      child: Text('or',
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500)),
                                    ),
                                    Expanded(
                                        child: Divider(
                                            color: Colors.grey[300],
                                            thickness: 1)),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Create Account Button
                                SizedBox(
                                  height: 56,
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.person_add_outlined,
                                        size: 22),
                                    label: const Text(
                                      'Create a New Account',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.primary,
                                      side: BorderSide(
                                          color: AppTheme.primary, width: 2),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(18)),
                                    ),
                                    onPressed: _isLoading
                                        ? null
                                        : () => Navigator.pushReplacementNamed(
                                            context, '/signup'),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Footer
                                Center(
                                  child: Text(
                                    '🔒 Secure & Private Assessment',
                                    style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
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
    final result = await auth.login(_emailCtrl.text, _passCtrl.text);

    setState(() => _isLoading = false);

    if (result['success']) {
      final userRole = auth.currentUser?.role ?? '';
      final String route;
      switch (userRole) {
        case 'parent':
          route = '/parent';
          break;
        case 'psychologist':
          route = '/psychologist';
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
    _animationController.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }
}
