import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/booking_model.dart';
import '../models/user_model.dart';
import 'chat_screen.dart';
import 'ride_summary_screen.dart';

class DriverActiveRideScreen extends StatefulWidget {
  final String rideId;
  final String pickup;
  final String destination;
  final String time;
  final int totalSeats;
  final double pricePerSeat;

  const DriverActiveRideScreen({
    super.key,
    required this.rideId,
    required this.pickup,
    required this.destination,
    required this.time,
    required this.totalSeats,
    required this.pricePerSeat,
  });

  @override
  State<DriverActiveRideScreen> createState() => _DriverActiveRideScreenState();
}

class _DriverActiveRideScreenState extends State<DriverActiveRideScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String? _otp;

  @override
  void initState() {
    super.initState();
    _fetchOtp();
  }

  Future<void> _fetchOtp() async {
    try {
      final doc = await _firestoreService.getRideOtp(widget.rideId);
      if (mounted) {
        setState(() => _otp = doc);
      }
    } catch (e) {
      debugPrint('Error fetching OTP: $e');
    }
  }

  void _copyOtp() {
    if (_otp != null) {
      Clipboard.setData(ClipboardData(text: _otp!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP copied to clipboard', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          backgroundColor: const Color(0xFF2563EB),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _endRide() async {
    // Mark ride as completed in Firestore
    await _firestoreService.endRide(widget.rideId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ride ended. Thank you for driving with Commuto!', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => RideSummaryScreen(rideId: widget.rideId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('Leave ride?', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
              content: Text('Your ride is still active. Are you sure you want to leave?', style: GoogleFonts.inter()),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Stay')),
                TextButton(
                  onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
                  child: const Text('Leave', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text('Your Active Ride', style: GoogleFonts.inter(color: const Color(0xFF1A1D26), fontSize: 20, fontWeight: FontWeight.w800)),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: _endRide,
              child: Text('End Ride', style: GoogleFonts.inter(color: const Color(0xFFEF4444), fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                rideId: widget.rideId,
                rideDriverId: AuthService.currentUser?.uid ?? '',
              ),
            ),
          ),
          backgroundColor: const Color(0xFF2563EB),
          child: const Icon(Icons.chat_rounded, color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // OTP Display Card
              _buildOtpCard(),
              const SizedBox(height: 20),

              // Route Card
              _buildRouteCard(),
              const SizedBox(height: 20),

              // Live Passengers Section
              Text(
                'PASSENGERS',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              _buildLivePassengersList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ride OTP', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.8))),
                    Text('Share with passengers before boarding', style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withValues(alpha: 0.6))),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _copyOtp,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.copy_rounded, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _otp ?? '• • • •',
            style: GoogleFonts.inter(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              letterSpacing: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask passengers to enter this code',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF10B981), width: 2.5),
                    ),
                  ),
                  Container(width: 1.5, height: 28, color: const Color(0xFFE2E8F0)),
                  const Icon(Icons.location_on, size: 14, color: Color(0xFFEF4444)),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.pickup, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 20),
                    Text(widget.destination, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              _infoChip(Icons.access_time_rounded, widget.time),
              const SizedBox(width: 12),
              _infoChip(Icons.people_rounded, '${widget.totalSeats} seats'),
              const Spacer(),
              Text('₹${widget.pricePerSeat.toInt()}/seat', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF10B981))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(text, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildLivePassengersList() {
    return StreamBuilder<List<BookingModel>>(
      stream: _firestoreService.getBookingsForRide(widget.rideId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(color: Color(0xFF2563EB)),
          ));
        }

        final bookings = snapshot.data ?? [];

        if (bookings.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.people_outline_rounded, size: 32, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 16),
                Text('Waiting for passengers...', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
                const SizedBox(height: 4),
                Text('You\'ll see live updates here when someone books', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)), textAlign: TextAlign.center),
              ],
            ),
          );
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people_rounded, size: 18, color: Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  Text(
                    '${bookings.length} passenger${bookings.length > 1 ? 's' : ''} joined',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF059669)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...bookings.map((booking) => _buildPassengerCard(booking)),
          ],
        );
      },
    );
  }

  Widget _buildPassengerCard(BookingModel booking) {
    return FutureBuilder<UserModel?>(
      future: AuthService.getUserProfile(booking.riderId),
      builder: (context, snapshot) {
        final rider = snapshot.data;
        final isConfirmed = booking.status == BookingStatus.confirmed;
        final isVerified = booking.otpVerified;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isVerified 
                  ? const Color(0xFF10B981).withValues(alpha: 0.3) 
                  : const Color(0xFFF1F5F9),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: rider?.profilePhotoUrl != null ? NetworkImage(rider!.profilePhotoUrl!) : null,
                child: rider?.profilePhotoUrl == null ? const Icon(Icons.person, size: 20) : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rider?.name ?? 'Passenger',
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('hh:mm a').format(booking.createdAt),
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isVerified
                      ? const Color(0xFFECFDF5)
                      : isConfirmed
                          ? const Color(0xFFEFF6FF)
                          : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isVerified ? Icons.verified_rounded : isConfirmed ? Icons.check_circle_outline : Icons.access_time,
                      size: 14,
                      color: isVerified ? const Color(0xFF10B981) : isConfirmed ? const Color(0xFF2563EB) : const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isVerified ? 'Boarded' : isConfirmed ? 'Confirmed' : 'Pending',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isVerified ? const Color(0xFF10B981) : isConfirmed ? const Color(0xFF2563EB) : const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
