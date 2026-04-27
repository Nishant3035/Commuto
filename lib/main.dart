import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/auth_service.dart';
import 'screens/welcome_screen.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Global error handling — catch all unhandled Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('⚠️ FlutterError: ${details.exceptionAsString()}');
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('⚠️ PlatformError: $error\n$stack');
    return true;
  };

  // Set system UI style early (mobile only)
  if (!kIsWeb) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  // Initialize Firebase with error recovery
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('⚠️ Firebase init error: $e');
    // On web reload, Firebase may already be initialized
    if (e.toString().contains('already exists')) {
      debugPrint('ℹ️ Firebase was already initialized — continuing');
    }
  }

  runApp(const CommutoApp());
}

class CommutoApp extends StatefulWidget {
  const CommutoApp({super.key});

  @override
  State<CommutoApp> createState() => _CommutoAppState();
}

class _CommutoAppState extends State<CommutoApp> {
  @override
  void initState() {
    super.initState();
    // Load user profile in background (non-blocking)
    AuthService.loadCurrentUserProfile(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    // Auto-skip welcome screen for already logged-in users
    final bool isLoggedIn = AuthService.isLoggedIn;

    return MaterialApp(
      title: 'Commuto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1D4ED8),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: isLoggedIn
          ? const MainNavigationScreen()
          : const WelcomeScreen(),
    );
  }
}
