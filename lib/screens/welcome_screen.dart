import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main_navigation_screen.dart';

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
  late AnimationController _bgController;

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

    // Background continuous animation
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Logo animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, -0.4),
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
      begin: const Offset(0, 0.3),
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
      begin: const Offset(0, 0.3),
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
      begin: const Offset(0, 0.3),
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
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFEFF6FF),
              Color(0xFFF0F9FF),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 32),

                // Logo Section with gradient glow
                SlideTransition(
                  position: _logoSlide,
                  child: FadeTransition(
                    opacity: _logoFade,
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB)
                                    .withValues(alpha: 0.15),
                                blurRadius: 40,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: Image.asset('assets/images/commuto_logo.png',
                              height: 140),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Share rides. Save money.\nGo green.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                            height: 1.5,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
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
                            child: _buildPremiumFeatureCard(
                              icon: Icons.trending_down_rounded,
                              gradient: const [
                                Color(0xFF2563EB),
                                Color(0xFF3B82F6)
                              ],
                              bgColor: const Color(0xFFEFF6FF),
                              title: 'Save up to 70%',
                              subtitle: 'Split travel costs with co-riders',
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Card 2 - Eco-friendly
                        SlideTransition(
                          position: _card2Slide,
                          child: FadeTransition(
                            opacity: _card2Fade,
                            child: _buildPremiumFeatureCard(
                              icon: Icons.eco_rounded,
                              gradient: const [
                                Color(0xFF059669),
                                Color(0xFF10B981)
                              ],
                              bgColor: const Color(0xFFF0FDF4),
                              title: 'Eco-friendly',
                              subtitle: 'Reduce your carbon footprint daily',
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Card 3 - Verified students
                        SlideTransition(
                          position: _card3Slide,
                          child: FadeTransition(
                            opacity: _card3Fade,
                            child: _buildPremiumFeatureCard(
                              icon: Icons.verified_user_outlined,
                              gradient: const [
                                Color(0xFF7C3AED),
                                Color(0xFF8B5CF6)
                              ],
                              bgColor: const Color(0xFFF5F3FF),
                              title: 'Verified students',
                              subtitle: 'Safe & trusted community only',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Taxi illustration
                FadeTransition(
                  opacity: _buttonFade,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Image.asset(
                      'assets/images/taxi_icon.png',
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // Get Started Button — premium gradient
                FadeTransition(
                  opacity: _buttonFade,
                  child: ScaleTransition(
                    scale: _buttonScale,
                    child: Container(
                      width: double.infinity,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB)
                                .withValues(alpha: 0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      MainNavigationScreen(),
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                return FadeTransition(
                                    opacity: animation, child: child);
                              },
                              transitionDuration:
                                  const Duration(milliseconds: 400),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          textStyle: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Get Started'),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.arrow_forward_rounded,
                                  size: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumFeatureCard({
    required IconData icon,
    required List<Color> gradient,
    required Color bgColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: bgColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Gradient icon container
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: gradient[0].withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
