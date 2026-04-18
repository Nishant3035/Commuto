import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../models/ride_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
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
    // Prevent user from booking their own ride
    final currentUser = AuthService.currentUser;
    if (currentUser != null && ride.driverId == currentUser.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You cannot join your own ride!', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          title: isOrigin ? 'Leaving from' : 'Going to',
          showCurrentLocation: isOrigin,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        if (isOrigin) {
          _leavingFrom = result.address;
        } else {
          _goingTo = result.address;
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
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Could not load rides right now',
              style: GoogleFonts.inter(color: const Color(0xFF64748B)),
            ),
          );
        }

        List<RideModel> displayRides = snapshot.data ?? [];
        
        // Additional local filtering if needed
        if (_filterGirlsOnly && AuthService.userGender == 'Female') {
           // We'd need driver profile for this, which we'll handle in the UI card
        }

        return Column(
          children: [
            const SizedBox(height: 12),
            _buildSearchHeader(),

            // Dynamic Gender Toggle for Females
            if (AuthService.userGender == 'Female')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_user, color: Color(0xFFD946EF), size: 18),
                        const SizedBox(width: 8),
                        Text('Match Girls Only', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFFD946EF))),
                      ],
                    ),
                    Switch(
                      value: _filterGirlsOnly,
                      activeTrackColor: const Color(0xFFD946EF).withValues(alpha: 0.5),
                      activeThumbColor: const Color(0xFFD946EF),
                      onChanged: (val) => setState(() => _filterGirlsOnly = val),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
              child: displayRides.isEmpty
                  ? Center(child: Text('No rides found', style: GoogleFonts.inter(color: const Color(0xFF64748B))))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: displayRides.length,
                      itemBuilder: (context, index) {
                        return _buildRideCard(displayRides[index]);
                      },
                    ),
            ),
          ],
        );
      }
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
                child: Container(width: 2, height: 16, color: const Color(0xFFE2E8F0)),
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

  Widget _buildSearchInput({required IconData icon, required Color iconColor, required String hint, bool isActive = false, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: isActive ? Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.5), width: 1.5) : Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hint,
                style: GoogleFonts.inter(color: isActive ? const Color(0xFF1A1D26) : const Color(0xFF94A3B8), fontWeight: FontWeight.w600, fontSize: 15),
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
    return FutureBuilder<UserModel?>(
      future: AuthService.getUserProfile(ride.driverId),
      builder: (context, userSnapshot) {
        final driver = userSnapshot.data;
        
        return InkWell(
          onTap: () => _handleJoinRide(ride),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
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
              children: [
                // Top Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: NetworkImage(driver?.profilePhotoUrl ?? 'https://i.pravatar.cc/150'),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: Icon(
                                Icons.person,
                                size: 14,
                                color: const Color(0xFF3B82F6),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  driver?.name ?? 'Loading...',
                                  style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
                                const SizedBox(width: 4),
                                Text(driver?.rating.toString() ?? '5.0', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
                                const SizedBox(width: 8),
                                Text('•', style: TextStyle(color: Color(0xFFCBD5E1))),
                                const SizedBox(width: 8),
                                Expanded(child: Text(ride.destinationName, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)), overflow: TextOverflow.ellipsis)),
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
                            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF10B981)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: const Color(0xFFF1F5F9)),
                // Bottom Info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.access_time, color: Color(0xFF64748B), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('hh:mm a').format(ride.dateTime),
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF1A1D26)),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: ride.seatsAvailable > 0 ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${ride.seatsAvailable} seats left',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: ride.seatsAvailable > 0 ? const Color(0xFF2563EB) : const Color(0xFF94A3B8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
