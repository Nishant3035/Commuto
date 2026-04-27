import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../models/ride_model.dart';
import '../models/user_model.dart';
import '../utils/fare_calculator.dart';
import 'booking_summary_screen.dart';

class RideDetailsScreen extends StatefulWidget {
  final RideModel rideData;
  final ValueChanged<String> onBook;

  const RideDetailsScreen({
    super.key,
    required this.rideData,
    required this.onBook,
  });

  @override
  State<RideDetailsScreen> createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends State<RideDetailsScreen> {
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

  Future<void> _launchSOS() async {
    final Uri url = Uri.parse('tel:100');
    if (!await launchUrl(url)) {
      debugPrint('Could not launch SOS');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double displayPrice = widget.rideData.pricePerSeat;

    // Calculate real savings using FareCalculator with actual ride coordinates
    final distanceKm = FareCalculator.calculateDistance(
      widget.rideData.sourceLatLng.latitude,
      widget.rideData.sourceLatLng.longitude,
      widget.rideData.destinationLatLng.latitude,
      widget.rideData.destinationLatLng.longitude,
    );
    final fareInfo = FareCalculator.calculatePerPersonFare(distanceKm);
    final double savings = fareInfo.savings;

    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: Stack(
        children: [
          // Background/Hero Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 250,
            child: Image.asset(
              'assets/images/hero_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF2B7DE9)),
            ),
          ),

          // Header Overlay
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back, color: Color(0xFF1A1D26), size: 20),
                  ),
                ),
                GestureDetector(
                  onTap: _launchSOS,
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(22)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_police, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text('SOS', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          Positioned.fill(
            top: 220,
            child: Container(
              decoration: const BoxDecoration(color: Colors.white),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 240, top: 60),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Host Details', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          _buildPassengerAvatar(
                            name: _driver?.name ?? widget.rideData.driverName,
                            gender: _driver?.gender ?? widget.rideData.driverGender,
                            isDriver: true,
                            imageUrl: _driver?.profilePhotoUrl,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Metrics Row — dynamic CO2 and verification
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              icon: Icons.energy_savings_leaf_outlined,
                              iconColor: const Color(0xFF059669),
                              iconBgColor: const Color(0xFFD1FAE5),
                              title: 'CO₂ Saved',
                              value: '${(distanceKm * 0.150).toStringAsFixed(1)} kg',
                              bgColor: const Color(0xFFF0FDF4),
                              textColor: const Color(0xFF059669),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildMetricCard(
                              icon: Icons.verified_user_outlined,
                              iconColor: const Color(0xFF2563EB),
                              iconBgColor: const Color(0xFFDBEAFE),
                              title: 'Status',
                              value: (_driver?.isAadharVerified ?? false) ? 'Verified' : 'Unverified',
                              bgColor: const Color(0xFFF0F6FF),
                              textColor: const Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Trip Schedule
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Trip Schedule', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                            const SizedBox(height: 24),
                            _buildTimelineItem(
                              title: widget.rideData.sourceName,
                              subtitle: DateFormat('hh:mm a').format(widget.rideData.dateTime),
                              isStart: true,
                            ),
                            _buildTimelineConnector(),
                            _buildTimelineItem(
                              title: widget.rideData.destinationName,
                              subtitle: 'Estimated drop-off',
                              isStart: false,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Overlapping Address Card
          Positioned(
            top: 200,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pick up', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                        const SizedBox(height: 4),
                        Text(widget.rideData.sourceName, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const Icon(Icons.access_time, color: Color(0xFF2563EB), size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Drop off', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                        const SizedBox(height: 4),
                        Text(widget.rideData.destinationName, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Floating Card
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 30, offset: const Offset(0, -5)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Price', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          Text('₹${displayPrice.toInt()}', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          'Save ₹${savings.toInt()}',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF059669)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: widget.rideData.seatsAvailable > 0
                          ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingSummaryScreen(
                              rideData: widget.rideData,
                              onConfirm: (bookingId) {
                                Navigator.pop(context);
                                widget.onBook(bookingId);
                              },
                            ),
                          ),
                        );
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.rideData.seatsAvailable > 0
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF94A3B8),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        widget.rideData.seatsAvailable > 0 ? 'Join Ride' : 'Ride Full',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerAvatar({required String name, required String gender, bool isDriver = false, String? imageUrl}) {
    bool isMale = gender == 'Male';
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFF8FAFC),
                backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                child: imageUrl == null ? const Icon(Icons.person, color: Color(0xFF94A3B8), size: 28) : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: isMale ? const Color(0xFFDBEAFE) : const Color(0xFFFCE7F3), shape: BoxShape.circle),
                  child: Icon(
                    isMale ? Icons.male : Icons.female,
                    size: 12,
                    color: isMale ? const Color(0xFF2563EB) : const Color(0xFFDB2777),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1A1D26))),
          if (isDriver)
            Text('Host', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF2563EB))),
        ],
      ),
    );
  }

  Widget _buildMetricCard({required IconData icon, required Color iconColor, required Color iconBgColor, required String title, required String value, required Color bgColor, required Color textColor}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 16),
          Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({required String title, required String subtitle, required bool isStart}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 16, height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isStart ? Colors.white : const Color(0xFF0F172A),
            border: Border.all(color: isStart ? const Color(0xFF2563EB) : const Color(0xFF0F172A), width: 3),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
              const SizedBox(height: 4),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF64748B))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineConnector() {
    return Container(
      margin: const EdgeInsets.only(left: 7.5, top: 4, bottom: 4),
      height: 32,
      width: 1.5,
      color: const Color(0xFFE2E8F0),
    );
  }
}
