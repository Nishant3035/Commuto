import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'main_navigation_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserModel? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (AuthService.isLoggedIn) {
      final profile = await AuthService.loadCurrentUserProfile(forceRefresh: true);
      if (mounted) {
        setState(() => _userProfile = profile);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayName = 'Commuter';
    if (AuthService.isLoggedIn) {
      displayName = _userProfile?.name ?? AuthService.fullName;
    }

    return Container(
      color: const Color(0xFFF8FAFC),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good ${DateTime.now().hour < 12 ? 'Morning' : 'Evening'},',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
                      ),
                      Text(
                        displayName,
                        style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), letterSpacing: -0.5),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Highlighted Action Cards
              Text('WHAT\'S YOUR PLAN TODAY?', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8), letterSpacing: 1.0)),
              const SizedBox(height: 16), 
              
              _buildModernActionCard(
                context,
                title: 'Find a Ride',
                subtitle: 'Join an existing shared auto',
                icon: Icons.search_rounded,
                color: const Color(0xFF2563EB),
                onTap: () {
                  final selectTab = MainNavigationController.maybeSelectTab(context);
                  if (selectTab != null) {
                    selectTab(1);
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MainNavigationScreen(initialIndex: 1)));
                  }
                },
              ),
              const SizedBox(height: 16), 
              _buildModernActionCard(
                context,
                title: 'Offer a Ride',
                subtitle: 'Split costs of your auto booking',
                icon: Icons.add_circle_outline_rounded,
                color: const Color(0xFF10B981),
                onTap: () {
                  final selectTab = MainNavigationController.maybeSelectTab(context);
                  if (selectTab != null) {
                    selectTab(2);
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MainNavigationScreen(initialIndex: 2)));
                  }
                },
              ),

              const SizedBox(height: 48),

              // Global Community Impact Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF064E3B), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF059669).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.park_rounded, color: Colors.white, size: 30),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                          child: Text('LIVE DATA', style: GoogleFonts.inter(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('14,320 kg', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                    Text('CO₂ Emissions Prevented This Month', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.8))),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🌳', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text('Equivalent to planting 680 trees', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                        ],
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _buildSavingsRow(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernActionCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF0F172A), width: 2.5),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFCBD5E1), size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickStat('₹12.4L', 'Total Saved'),
          Container(width: 1, height: 30, color: const Color(0xFFF1F5F9)),
          _buildQuickStat('3,400+', 'Active Autos'),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
        Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
      ],
    );
  }
}
