import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/parent/parent_screen.dart';
import 'screens/psychologist/psychologist_screen.dart';
import 'screens/admin/admin_screen.dart';
import 'screens/educator/educator_screen.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'screens/verify_reset_code_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/forgot_password_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  ApiService.onUnauthorized = () {
    if (navigatorKey.currentContext != null) {
      final auth =
          Provider.of<AuthService>(navigatorKey.currentContext!, listen: false);
      auth.logout();
      navigatorKey.currentState
          ?.pushNamedAndRemoveUntil('/login', (route) => false);
    }
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: const AutiSenseApp(),
    ),
  );
}

class AutiSenseApp extends StatelessWidget {
  const AutiSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'AutiSense',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/parent': (_) => const ParentScreen(),
        '/psychologist': (_) => const PsychologistScreen(),
        '/educator': (_) => const EducatorScreen(),
        '/admin': (_) => const AdminScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/verify-reset-code': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String;
          return VerifyResetCodeScreen(email: args);
        },
        '/reset-password': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return ResetPasswordScreen(
            email: args['email'] as String,
            code: args['code'] as String,
          );
        },
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _fadeAnim = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _scaleAnim = Tween(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(Icons.child_care,
                          size: 70, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    const Text('AutoSense',
                        style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2)),
                    const SizedBox(height: 8),
                    Text('Autism Assessment Platform',
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.85))),
                    const SizedBox(height: 48),
                    const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppTheme {
  // Modern, warm color palette for family-friendly app
  static const Color primary = Color(0xFF6366F1); // Indigo - warm blue
  static const Color secondary = Color(0xFF8B5CF6); // Violet - warm purple
  static const Color accent = Color(0xFF10B981); // Emerald - fresh green
  static const Color warning = Color(0xFFF59E0B); // Amber - warm orange
  static const Color danger = Color(0xFFEF4444); // Red - coral red
  static const Color success = Color(0xFF22C55E); // Green - bright green
  static const Color background = Color(0xFFFAFAFA); // Warm off-white
  static const Color cardBg = Colors.white;
  static const Color surface = Color(0xFFF8FAFC); // Light gray-blue
  static const Color textPrimary = Color(0xFF1E293B); // Dark slate
  static const Color textSecondary = Color(0xFF64748B); // Medium gray
  static const Color textMuted = Color(0xFF94A3B8); // Light gray

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF22C55E)],
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
  );

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
          primary: primary,
          secondary: secondary,
          tertiary: accent,
          error: danger,
          surface: surface,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: textPrimary,
        ),
        scaffoldBackgroundColor: background,
        fontFamily: 'Poppins',
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: const TextStyle(
              color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
          iconTheme: const IconThemeData(color: textPrimary),
          shadowColor: Colors.black.withValues(alpha: 0.05),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          color: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(vertical: 4),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: textMuted.withValues(alpha: 0.3))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: textMuted.withValues(alpha: 0.3))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primary, width: 2)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          labelStyle: const TextStyle(color: textSecondary),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          indicatorColor: primary.withValues(alpha: 0.1),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              );
            }
            return const TextStyle(
              color: textSecondary,
              fontSize: 12,
            );
          }),
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: primary,
          unselectedLabelColor: textSecondary,
          indicatorColor: primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        ),
      );
}
