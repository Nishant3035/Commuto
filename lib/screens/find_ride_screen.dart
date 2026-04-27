import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../models/ride_model.dart';
import '../services/firestore_service.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/empty_state_widget.dart';
import 'active_ride_screen.dart';
import 'map_picker_screen.dart';
import 'ride_details_screen.dart';

class FindRideScreen extends StatefulWidget {
  const FindRideScreen({super.key});

  @override
  State<FindRideScreen> createState() => _FindRideScreenState();
}

class _FindRideScreenState extends State<FindRideScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String? _leavingFrom;
  String? _goingTo;
  bool _filterGirlsOnly = false;
  final DateTime _selectedDate = DateTime.now();

  void _handleJoinRide(RideModel ride) async {
    debugPrint(
        '[FindRide] My userId: ${AuthService.userId}, ride driverId: ${ride.driverId}');
    if (AuthService.isLoggedIn && ride.driverId == AuthService.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('This is your own ride',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RideDetailsScreen(
          rideData: ride,
          onBook: (bookingId) => _processBooking(ride, bookingId),
        ),
      ),
    );
  }

  void _processBooking(RideModel ride, String bookingId) async {
    final bool didLogin = await AuthService.requireLogin(context);
    if (!didLogin || !mounted) return;

    // Create activity for rider
    await _firestoreService.addActivity(
      userId: AuthService.userId,
      title: 'Ride Joined',
      body:
          'You joined a ride from ${ride.sourceName} to ${ride.destinationName}',
      type: 'ride_joined',
      rideId: ride.id,
    );

    // Notify driver
    await _firestoreService.addActivity(
      userId: ride.driverId,
      title: 'New Passenger',
      body: '${AuthService.fullName} has joined your ride!',
      type: 'ride_joined',
      rideId: ride.id,
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveRideScreen(
          rideData: ride,
          bookingId: bookingId,
        ),
      ),
    );
  }

  Future<void> _pickLocation({required bool isOrigin}) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          title: isOrigin ? 'Leaving from' : 'Going to',
        ),
      ),
    );
    if (result != null) {
      setState(() {
        if (isOrigin) {
          _leavingFrom = result['name'] as String;
        } else {
          _goingTo = result['name'] as String;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RideModel>>(
      stream: _firestoreService.searchRides(
        source: _leavingFrom,
        destination: _goingTo,
        date: _selectedDate,
        womenOnly: _filterGirlsOnly,
        currentUserGender: AuthService.userGender,
      ),
      builder: (context, snapshot) {
        final isLoading =
            snapshot.connectionState == ConnectionState.waiting;
        final hasError = snapshot.hasError;
        final displayRides = snapshot.data ?? [];

        return Column(
          children: [
            const SizedBox(height: 12),
            _buildSearchHeader(),

            // Women-Only Toggle — only show for female users
            if (AuthService.userGender == 'Female')
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_user,
                            color: Color(0xFFD946EF), size: 18),
                        const SizedBox(width: 8),
                        Text('Match Girls Only',
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFD946EF))),
                      ],
                    ),
                    Switch(
                      value: _filterGirlsOnly,
                      activeTrackColor:
                          const Color(0xFFD946EF).withValues(alpha: 0.5),
                      activeThumbColor: const Color(0xFFD946EF),
                      onChanged: (val) =>
                          setState(() => _filterGirlsOnly = val),
                    ),
                  ],
                ),
              ),

            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'AVAILABLE ON ${DateFormat('MMM dd').format(_selectedDate).toUpperCase()}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: isLoading
                  ? ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      children: const [
                        RideCardSkeleton(),
                        RideCardSkeleton(),
                        RideCardSkeleton(),
                      ],
                    )
                  : hasError
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.wifi_off_rounded,
                                  size: 48, color: Color(0xFF94A3B8)),
                              const SizedBox(height: 16),
                              Text(
                                'Could not load rides',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton.icon(
                                onPressed: () => setState(() {}),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : displayRides.isEmpty
                          ? EmptyStateWidget(
                              icon: Icons.directions_car_outlined,
                              title: _filterGirlsOnly
                                  ? 'No women-only rides available'
                                  : 'No rides found',
                              subtitle: _leavingFrom != null || _goingTo != null
                                  ? 'Try a different route or check back later'
                                  : 'Be the first to offer a ride today!',
                              iconColor: const Color(0xFF2563EB),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 8),
                              itemCount: displayRides.length,
                              itemBuilder: (context, index) {
                                return TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: Duration(
                                      milliseconds: 300 + (index * 100)),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, child) {
                                    return Opacity(
                                      opacity: value,
                                      child: Transform.translate(
                                        offset:
                                            Offset(0, 20 * (1 - value)),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child:
                                      _buildRideCard(displayRides[index]),
                                );
                              },
                            ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSearchInput(
              icon: Icons.my_location,
              iconColor: const Color(0xFF3B82F6),
              hint: _leavingFrom ?? 'Current Location',
              isActive: _leavingFrom != null,
              onTap: () => _pickLocation(isOrigin: true),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                    width: 2, height: 16, color: const Color(0xFFE2E8F0)),
              ),
            ),
            _buildSearchInput(
              icon: Icons.location_on,
              iconColor: const Color(0xFFEF4444),
              hint: _goingTo ?? 'Where are you going?',
              isActive: _goingTo != null,
              onTap: () => _pickLocation(isOrigin: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchInput({
    required IconData icon,
    required Color iconColor,
    required String hint,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: isActive
              ? Border.all(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
                  width: 1.5)
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hint,
                style: GoogleFonts.inter(
                    color: isActive
                        ? const Color(0xFF1A1D26)
                        : const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                    fontSize: 15),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideCard(RideModel ride) {
    // Use denormalized driver data from ride instead of extra Firestore reads
    final driverName = ride.driverName.isNotEmpty ? ride.driverName : 'Host';
    final isFull = ride.seatsAvailable <= 0;

    return InkWell(
      onTap: isFull ? null : () => _handleJoinRide(ride),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isFull ? const Color(0xFFF8FAFC) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isFull ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Opacity(
          opacity: isFull ? 0.6 : 1.0,
          child: Column(
          children: [
            // Top Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar with initials
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFEFF6FF),
                    child: Text(
                      driverName.isNotEmpty
                          ? driverName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join().toUpperCase()
                          : '?',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                driverName,
                                style: GoogleFonts.inter(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (ride.isWomenOnly) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFCE7F3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.female,
                                        size: 12, color: Color(0xFFDB2777)),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Girls',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFDB2777),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text('• ',
                                style: TextStyle(color: Color(0xFFCBD5E1))),
                            Expanded(
                                child: Text(ride.destinationName,
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF64748B)),
                                    overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${ride.pricePerSeat.toInt()}',
                        style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF10B981)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: const Color(0xFFF1F5F9)),
            // Bottom Info
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.access_time,
                        color: Color(0xFF64748B), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('hh:mm a').format(ride.dateTime),
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1D26)),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isFull
                          ? const Color(0xFFFEE2E2)
                          : ride.seatsAvailable > 0
                              ? const Color(0xFFEFF6FF)
                              : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isFull ? 'FULL' : '${ride.seatsAvailable} seats left',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isFull
                              ? const Color(0xFFDC2626)
                              : ride.seatsAvailable > 0
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF94A3B8)),
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
