import 'package:autism_assessment_app/screens/login_screen.dart';
import 'package:autism_assessment_app/screens/parent/parent_screen.dart';
import 'package:autism_assessment_app/screens/psychologist/psychologist_screen.dart';
import 'package:autism_assessment_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/admin/admin_screen.dart';
import 'services/auth_service.dart';
import 'screens/educator/educator_screen.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      title: 'AutiSense',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/parent': (_) => const ParentScreen(),
        '/psychologist': (_) => const PsychologistScreen(),
        '/educator': (_) => const EducatorScreen(),
        '/admin': (_) => const AdminScreen(),
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
    _fadeAnim = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeIn));
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
                        color: Colors.white.withOpacity(0.2),
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
                            color: Colors.white.withOpacity(0.85))),
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
  static const Color primary = Color(0xFF4A90D9);
  static const Color secondary = Color(0xFF7B68EE);
  static const Color accent = Color(0xFF50C878);
  static const Color warning = Color(0xFFFF8C00);
  static const Color danger = Color(0xFFE74C3C);
  static const Color background = Color(0xFFF8FAFF);
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4A90D9), Color(0xFF7B68EE)],
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF50C878), Color(0xFF2ECC71)],
  );

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: primary),
    scaffoldBackgroundColor: background,
    fontFamily: 'Poppins',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
          color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
      iconTheme: IconThemeData(color: textPrimary),
    ),
    cardTheme: const CardThemeData(
      elevation: 4,
      shadowColor: Colors.black12,
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding:
        const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle:
        const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2)),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}