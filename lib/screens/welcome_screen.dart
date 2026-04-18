import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main_navigation_screen.dart';
import '../widgets/feature_card.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _cardsController;
  late AnimationController _buttonController;

  late Animation<double> _logoFade;
  late Animation<Offset> _logoSlide;

  late Animation<double> _card1Fade;
  late Animation<Offset> _card1Slide;
  late Animation<double> _card2Fade;
  late Animation<Offset> _card2Slide;
  late Animation<double> _card3Fade;
  late Animation<Offset> _card3Slide;

  late Animation<double> _buttonFade;
  late Animation<double> _buttonScale;

  @override
  void initState() {
    super.initState();

    // Logo animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
    );

    // Cards stagger animation
    _cardsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _card1Fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardsController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _card1Slide = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _cardsController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
      ),
    );

    _card2Fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardsController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );
    _card2Slide = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _cardsController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _card3Fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardsController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );
    _card3Slide = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _cardsController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Button animation
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _buttonFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOut),
    );
    _buttonScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.elasticOut),
    );

    // Start animations in sequence
    _logoController.forward().then((_) {
      _cardsController.forward().then((_) {
        _buttonController.forward();
      });
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _cardsController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Logo Section
              SlideTransition(
                position: _logoSlide,
                child: FadeTransition(
                  opacity: _logoFade,
                  child: Image.asset('assets/images/commuto_logo.png', height: 180),
                ),
              ),

              const SizedBox(height: 36),

              // Feature Cards
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Card 1 - Save up to 70%
                      SlideTransition(
                        position: _card1Slide,
                        child: FadeTransition(
                          opacity: _card1Fade,
                          child: const FeatureCard(
                            icon: Icons.trending_down_rounded,
                            iconColor: Color(0xFF2B7DE9),
                            iconBgColor: Color(0xFFE8F1FD),
                            title: 'Save up to 70%',
                            subtitle: 'Split travel costs',
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Card 2 - Eco-friendly
                      SlideTransition(
                        position: _card2Slide,
                        child: FadeTransition(
                          opacity: _card2Fade,
                          child: const FeatureCard(
                            icon: Icons.eco_rounded,
                            iconColor: Color(0xFF34A853),
                            iconBgColor: Color(0xFFE6F4EA),
                            title: 'Eco-friendly',
                            subtitle: 'Reduce carbon emissions',
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Card 3 - Verified students
                      SlideTransition(
                        position: _card3Slide,
                        child: FadeTransition(
                          opacity: _card3Fade,
                          child: const FeatureCard(
                            icon: Icons.verified_user_outlined,
                            iconColor: Color(0xFF7C3AED),
                            iconBgColor: Color(0xFFF3EEFE),
                            title: 'Verified students',
                            subtitle: 'Safe & trusted community',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Taxi illustration — close to the button
              FadeTransition(
                opacity: _buttonFade,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Image.asset(
                    'assets/images/taxi_icon.png',
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // Browse Rides Button
              FadeTransition(
                opacity: _buttonFade,
                child: ScaleTransition(
                  scale: _buttonScale,
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => MainNavigationScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2B7DE9),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor:
                            const Color(0xFF2B7DE9).withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      child: const Text('Get Started'),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
