import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/ride_model.dart';
import '../models/booking_model.dart';
import '../services/firestore_service.dart';
import '../utils/fare_calculator.dart';
import 'main_navigation_screen.dart';

class RideSummaryScreen extends StatefulWidget {
  final String rideId;

  const RideSummaryScreen({super.key, required this.rideId});

  @override
  State<RideSummaryScreen> createState() => _RideSummaryScreenState();
}

class _RideSummaryScreenState extends State<RideSummaryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  RideModel? _ride;
  List<BookingModel> _bookings = [];
  bool _isLoading = true;
  double _selectedRating = 0;

  @override
  void initState() {
    super.initState();
    _fetchSummaryData();
  }

  Future<void> _fetchSummaryData() async {
    try {
      final ride = await _firestoreService.streamRide(widget.rideId).first;
      final bookings = await _firestoreService.getBookingsForRide(widget.rideId).first;
      
      if (mounted) {
        setState(() {
          _ride = ride;
          _bookings = bookings.where((b) => b.status == BookingStatus.confirmed).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _submitRatings() {
    if (_selectedRating == 0) return;
    
    // Submit rating for each confirmed passenger
    for (var booking in _bookings) {
      _firestoreService.submitRating(booking.riderId, _selectedRating);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ratings submitted! Thank you.', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
    _goHome();
  }

  void _goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
      );
    }

    if (_ride == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Summary')),
        body: const Center(child: Text('Unable to load summary')),
      );
    }

    // Calculate totals
    final int confirmedPassengers = _bookings.length;
    final double totalEarned = confirmedPassengers * _ride!.pricePerSeat;

    final distanceKm = FareCalculator.calculateDistance(
      _ride!.sourceLatLng.latitude, _ride!.sourceLatLng.longitude,
      _ride!.destinationLatLng.latitude, _ride!.destinationLatLng.longitude,
    );
    final double co2SavedStr = distanceKm * 0.150 * confirmedPassengers;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Ride Summary',
          style: GoogleFonts.inter(
            color: const Color(0xFF1A1D26),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, size: 64, color: Color(0xFF10B981)),
            ),
            const SizedBox(height: 24),
            Text(
              'Trip Completed!',
              style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text(
              'You successfully transported $confirmedPassengers passenger(s).',
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 32),

            // Earnings Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Text('TOTAL EARNED', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8), letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  Text('₹${totalEarned.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.w900, color: const Color(0xFF10B981))),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(height: 1)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('CO₂ Emissions Saved', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                      Row(
                        children: [
                          const Icon(Icons.eco_rounded, size: 16, color: Color(0xFF10B981)),
                          const SizedBox(width: 6),
                          Text('${co2SavedStr.toStringAsFixed(2)} kg', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Rating section
            if (confirmedPassengers > 0) ...[
              Text('Rate Your Passengers', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1A1D26))),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starValue = index + 1.0;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedRating = starValue);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        starValue <= _selectedRating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 44,
                        color: starValue <= _selectedRating
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedRating > 0
                    ? '${_selectedRating.toInt()} / 5'
                    : 'Tap a star to rate',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),

              // Submit Rating Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedRating > 0 ? _submitRatings : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    disabledBackgroundColor: const Color(0xFFE2E8F0),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    'Submit Rating',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ] else ...[
              Text('No confirmed passengers for this ride.', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B))),
            ],

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: _goHome,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE2E8F0), width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  'Skip & Go Home',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
