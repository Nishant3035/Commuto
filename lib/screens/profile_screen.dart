import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../widgets/aadhar_verification_bottom_sheet.dart';
import '../widgets/wallet_topup_bottom_sheet.dart';
import 'ride_history_screen.dart';
import 'verification_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _profile;
  bool _isLoadingProfile = false;

  bool get _isLoggedIn => AuthService.isLoggedIn;
  UserModel? get _resolvedProfile => _profile ?? AuthService.cachedUserProfile;

  @override
  void initState() {
    super.initState();
    _refreshProfile();
  }

  Future<void> _refreshProfile() async {
    if (!_isLoggedIn) {
      if (mounted) {
        setState(() => _profile = null);
      }
      return;
    }

    setState(() => _isLoadingProfile = true);
    final profile = await AuthService.loadCurrentUserProfile(forceRefresh: true);
    if (mounted) {
      setState(() {
        _profile = profile;
        _isLoadingProfile = false;
      });
    }
  }

  void _handleLogin() async {
    final didLogin = await AuthService.requireLogin(context);
    if (didLogin && mounted) {
      await _refreshProfile();
    }
  }

  void _handleLogout() async {
    await AuthService.logout();
    if (mounted) {
      setState(() => _profile = null);
    }
  }

  void _showTopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => WalletTopupBottomSheet(
        onTopup: (amount) async {
          // Use the profile screen's context, not the bottom sheet's
          try {
            await AuthService.topUpWallet(amount);
          } catch (e) {
            debugPrint('Top-up error: $e');
          }
          await _refreshProfile();
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Rs ${amount.toInt()} added to wallet successfully!',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
      ),
    );
  }

  void _showAadharVerify() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => AadharVerificationBottomSheet(
        onVerified: (gender) async {
          final messenger = ScaffoldMessenger.of(sheetContext);
          await AuthService.completeAadharVerification(
            gender: gender,
            name: _resolvedProfile?.name == 'New User' ? 'Priya Sharma' : null,
          );
          await _refreshProfile();
          if (!mounted) return;

          messenger.showSnackBar(
            const SnackBar(
              content: Text('Aadhar verified. Identity secured.'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _handleVerifyStudent() async {
    final bool? verified = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VerificationScreen()),
    );
    if (verified == true && mounted) {
      await _refreshProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Profile & Impact',
          style: GoogleFonts.inter(
            color: const Color(0xFF1A1D26),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoggedIn
          ? (_isLoadingProfile && _resolvedProfile == null
              ? const Center(child: CircularProgressIndicator())
              : _buildProfileContent())
          : _buildLoginPrompt(),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline,
                size: 64,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sign in to Commuto',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1D26),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Join the student community to split costs, save the planet, and travel safely.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D4ED8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Secure Login',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    final profile = _resolvedProfile;
    final displayName = profile?.name.isNotEmpty == true
        ? profile!.name
        : AuthService.fullName;
    final phoneNumber =
        profile?.phoneNumber ?? AuthService.phoneNumber ?? 'No Phone';
    final gender = profile?.gender ?? AuthService.userGender;
    final isAadharVerified =
        profile?.isAadharVerified ?? AuthService.isAadharVerified;
    final isStudent = profile?.isStudent ?? AuthService.isStudent;
    final walletBalance = profile?.walletBalance ?? AuthService.walletBalance;
    final co2Saved = profile?.co2Saved ?? AuthService.co2Saved;
    final totalMoneySaved =
        profile?.totalMoneySaved ?? AuthService.totalMoneySaved;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: const Color(0xFFE2E8F0),
                    backgroundImage: gender == 'Female'
                        ? const NetworkImage('https://i.pravatar.cc/150?img=32')
                        : const NetworkImage('https://i.pravatar.cc/150?img=11'),
                  ),
                  if (isAadharVerified)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified,
                          color: Color(0xFF2563EB),
                          size: 24,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1D26),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      phoneNumber,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        gender,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF334155)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BALANCE',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rs ${walletBalance.toInt()}',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showTopup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    'Top Up',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'YOUR PLANET IMPACT',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF065F46),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Text('Trees', style: TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildImpactStat('${co2Saved.toInt()}kg', 'CO2 Saved'),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: VerticalDivider(),
                    ),
                    _buildImpactStat('14', 'Trees Worth'),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.savings,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Total Lifetime Savings: ',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Rs ${totalMoneySaved.toInt()}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF10B981),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'IDENTITY & SAFETY',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (!isAadharVerified)
            _buildActionItem(
              icon: Icons.shield_outlined,
              title: 'Verify Aadhar Identity',
              subtitle: 'Mandatory for safe community gender matching',
              color: const Color(0xFFEF4444),
              onTap: _showAadharVerify,
            )
          else
            _buildVerifiedBadge(
              'Aadhar Identity Verified',
              const Color(0xFF2563EB),
            ),
          const SizedBox(height: 12),
          if (!isStudent)
            _buildActionItem(
              icon: Icons.school_outlined,
              title: 'College ID Verification',
              subtitle: 'Unlock student exclusive pricing',
              color: const Color(0xFFD946EF),
              onTap: _handleVerifyStudent,
            )
          else
            _buildVerifiedBadge(
              'Student Access Verified',
              const Color(0xFF10B981),
            ),
          const SizedBox(height: 32),
          _buildMenuTile(Icons.history_rounded, 'Ride History', onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const RideHistoryScreen()));
          }),
          _buildMenuTile(Icons.notifications_active_outlined, 'Notifications'),
          _buildMenuTile(Icons.help_center_outlined, 'Help & Support'),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: _handleLogout,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: Color(0xFFEF4444),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Logout Account',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildImpactStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF065F46),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF059669),
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.1), width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifiedBadge(String title, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_rounded, color: color, size: 28),
          const SizedBox(width: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1E293B)),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1E293B),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title screen coming soon!')),
        );
      },
    );
  }
}
