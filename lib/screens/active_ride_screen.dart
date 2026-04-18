import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../models/ride_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../widgets/ride_otp_bottom_sheet.dart';
import 'chat_screen.dart';

class ActiveRideScreen extends StatefulWidget {
  final RideModel rideData;
  final String bookingId;

  const ActiveRideScreen({
    super.key,
    required this.rideData,
    required this.bookingId,
  });

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  bool _hasBoarded = false;
  double _finalPaidAmount = 0.0;
  UserModel? _driver;

  @override
  void initState() {
    super.initState();
    _fetchDriver();
  }

  Future<void> _fetchDriver() async {
    final driver = await AuthService.getUserProfile(widget.rideData.driverId);
    if (mounted) {
      setState(() => _driver = driver);
    }
  }

  void _handleBoarding() async {
    final bool? verified = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RideOtpBottomSheet(bookingId: widget.bookingId),
    );

    if (verified == true && mounted) {
      setState(() {
        _hasBoarded = true;
        _finalPaidAmount = widget.rideData.pricePerSeat;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Boarded! ₹${_finalPaidAmount.toStringAsFixed(0)} reserved from wallet.', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          backgroundColor: const Color(0xFF34A853),
        )
      );
    }
  }

  void _handleEndRide() {
    _showRatingDialog();
  }

  void _showRatingDialog() {
    int selectedRating = 0;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Rate Your Driver',
                style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('How was your trip with ${_driver?.name ?? 'your driver'}?', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (index) {
                      return InkWell(
                        onTap: () async {
                          setState(() {
                            selectedRating = index + 1;
                          });
                          
                          // Short delay for visual feedback
                          await Future.delayed(const Duration(milliseconds: 300));
                          
                          if (!mounted) return;
                          Navigator.pop(context); // close dialog
                          
                          if (_driver != null) {
                            try {
                              await FirestoreService().submitRating(_driver!.id, index + 1.0);
                            } catch (e) {
                              // Ignore failure silently for UX
                            }
                          }
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Thank you for rating!', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                            Navigator.popUntil(context, (route) => route.isFirst);
                          }
                        },
                        child: Icon(
                          index < selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 36,
                          color: index < selectedRating ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                        ),
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: const Text('Skip', style: TextStyle(color: Color(0xFF94A3B8))),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Active Trip', style: GoogleFonts.inter(color: const Color(0xFF1A1D26), fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1D26)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _hasBoarded ? const Color(0xFFECFDF5) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _hasBoarded ? const Color(0xFF10B981).withValues(alpha: 0.3) : const Color(0xFFE2E8F0)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                   Icon(
                    _hasBoarded ? Icons.check_circle : Icons.directions_car,
                    size: 64,
                    color: _hasBoarded ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _hasBoarded ? 'You are on board!' : 'Waiting for Driver',
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                     _hasBoarded ? 'Fare processing secured.' : 'Please enter the OTP provided by the driver to confirm your boarding.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Driver Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                   CircleAvatar(
                    radius: 24, 
                    backgroundImage: _driver?.profilePhotoUrl != null ? NetworkImage(_driver!.profilePhotoUrl!) : null,
                    child: _driver?.profilePhotoUrl == null ? const Icon(Icons.person) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your Driver', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                        Text(_driver?.name ?? 'Loading...', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat_bubble, color: Color(0xFF2563EB)),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          rideId: widget.rideData.id,
                          rideDriverId: widget.rideData.driverId,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            if (!_hasBoarded)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _handleBoarding,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text('Boarding (Enter OTP)', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _handleEndRide,
                  icon: const Icon(Icons.flag),
                  label: Text('End of Ride', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFF0F172A), width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
