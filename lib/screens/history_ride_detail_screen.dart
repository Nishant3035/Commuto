import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';
import '../models/ride_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../utils/fare_calculator.dart';
import 'chat_screen.dart';

class HistoryRideDetailScreen extends StatefulWidget {
  final RideModel? ride;
  final BookingModel? booking;

  const HistoryRideDetailScreen({
    super.key,
    this.ride,
    this.booking,
  }) : assert(ride != null || booking != null);

  @override
  State<HistoryRideDetailScreen> createState() => _HistoryRideDetailScreenState();
}

class _HistoryRideDetailScreenState extends State<HistoryRideDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  RideModel? _rideData;
  UserModel? _driver;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      if (widget.ride != null) {
        _rideData = widget.ride;
      } else if (widget.booking != null) {
        _rideData = await _firestoreService.streamRide(widget.booking!.rideId).first;
      }

      if (_rideData != null) {
        _driver = await _firestoreService.getUser(_rideData!.driverId);
      }
    } catch (e) {
      debugPrint('Error fetching details: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
      );
    }

    if (_rideData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ride Details')),
        body: const Center(child: Text('Ride details not found.')),
      );
    }

    final distanceKm = FareCalculator.calculateDistance(
      _rideData!.sourceLatLng.latitude, _rideData!.sourceLatLng.longitude,
      _rideData!.destinationLatLng.latitude, _rideData!.destinationLatLng.longitude,
    );

    final isDriver = widget.ride != null; // Since driver uses ride tab
    final statusColor = switch (_rideData!.status) {
      RideStatus.active => const Color(0xFF2563EB),
      RideStatus.full => const Color(0xFFF59E0B),
      RideStatus.completed => const Color(0xFF10B981),
      RideStatus.cancelled => const Color(0xFFEF4444),
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1D26)),
        title: Text(
          'Trip Details',
          style: GoogleFonts.inter(
            color: const Color(0xFF1A1D26),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(_rideData!.dateTime),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _rideData!.status.name.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Route Details
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF10B981), width: 3.5),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Pickup Location', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                            Text(_rideData!.sourceName, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(width: 2, height: 30, color: const Color(0xFFE2E8F0)),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Color(0xFFEF4444)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Drop-off Location', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                            Text(_rideData!.destinationName, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Driver details (for rider)
            if (!isDriver && _driver != null) ...[
              Text(
                'HOST DETAILS',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFFF1F5F9),
                      backgroundImage: _driver!.profilePhotoUrl != null ? NetworkImage(_driver!.profilePhotoUrl!) : null,
                      child: _driver!.profilePhotoUrl == null ? const Icon(Icons.person, color: Color(0xFF94A3B8)) : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_driver!.name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 4),
                              Text(_driver!.rating.toStringAsFixed(1), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Fare and Savings details
            Text(
              'PAYMENT & SAVINGS',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF94A3B8),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
              ),
              child: Column(
                children: [
                  _buildStatRow('Fare per seat', '₹${_rideData!.pricePerSeat.toInt()}', Icons.payments_rounded, const Color(0xFF2563EB)),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                  _buildStatRow('CO₂ Saved', '${(distanceKm * 0.150).toStringAsFixed(2)} kg', Icons.eco_rounded, const Color(0xFF10B981)),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                  _buildStatRow('Est. Auto Fare', '₹${FareCalculator.calculateTotalFare(distanceKm).toStringAsFixed(0)}', Icons.directions_car_filled_rounded, const Color(0xFF64748B)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Chat History Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        rideId: _rideData!.id,
                        rideDriverId: _rideData!.driverId,
                        readOnly: true,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                label: Text(
                  'View Chat History',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
        ),
      ],
    );
  }
}
