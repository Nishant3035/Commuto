import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'screens/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI style early
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Run the app immediately — load profile in background
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
      ),
      home: const WelcomeScreen(),
    );
  }
}
