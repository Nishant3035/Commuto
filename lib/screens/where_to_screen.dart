import 'package:flutter/material.dart';
import 'main_navigation_screen.dart';

class WhereToScreen extends StatefulWidget {
  const WhereToScreen({super.key});

  @override
  State<WhereToScreen> createState() => _WhereToScreenState();
}

class _WhereToScreenState extends State<WhereToScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _cardsController;

  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  late Animation<double> _card1Fade;
  late Animation<Offset> _card1Slide;
  late Animation<double> _card2Fade;
  late Animation<Offset> _card2Slide;

  @override
  void initState() {
    super.initState();

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(-0.2, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );

    _cardsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _card1Fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardsController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _card1Slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _cardsController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _card2Fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardsController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );
    _card2Slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _cardsController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _headerController.forward().then((_) {
      _cardsController.forward();
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _cardsController.dispose();
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Back button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    size: 20,
                    color: Color(0xFF1A1D26),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Header text
              SlideTransition(
                position: _headerSlide,
                child: FadeTransition(
                  opacity: _headerFade,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Where to?',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1D26),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Choose how you want to travel today.',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF1A1D26).withValues(alpha: 0.5),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // Option Cards
              Expanded(
                child: Column(
                  children: [
                    // Find a Ride card
                    SlideTransition(
                      position: _card1Slide,
                      child: FadeTransition(
                        opacity: _card1Fade,
                        child: _OptionCard(
                          icon: Icons.search_rounded,
                          iconColor: const Color(0xFF2B7DE9),
                          iconBgColor: const Color(0xFFD6E4F9),
                          title: 'Find a Ride',
                          subtitle:
                              'Search for available rides and book a seat.',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const MainNavigationScreen(initialIndex: 1),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Offer a Ride card
                    SlideTransition(
                      position: _card2Slide,
                      child: FadeTransition(
                        opacity: _card2Fade,
                        child: _OptionCard(
                          icon: Icons.directions_car_rounded,
                          iconColor: const Color(0xFF34A853),
                          iconBgColor: const Color(0xFFD4EDDA),
                          title: 'Offer a Ride',
                          subtitle:
                              'Publish your route and split costs with others.',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const MainNavigationScreen(initialIndex: 2),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<_OptionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF1A1D26).withValues(alpha: 0.18),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon circle
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: widget.iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: widget.iconColor,
                  size: 30,
                ),
              ),

              const SizedBox(height: 18),

              // Title
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1D26),
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 6),

              // Subtitle
              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF1A1D26).withValues(alpha: 0.5),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
