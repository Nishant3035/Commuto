import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/booking_model.dart';
import '../models/ride_model.dart';
import 'history_ride_detail_screen.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = AuthService.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1D26)),
        title: Text(
          'Ride History',
          style: GoogleFonts.inter(
            color: const Color(0xFF1A1D26),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: const Color(0xFF94A3B8),
          indicatorColor: const Color(0xFF2563EB),
          indicatorWeight: 3,
          labelStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'My Bookings'),
            Tab(text: 'My Rides'),
          ],
        ),
      ),
      body: userId == null
          ? _buildEmptyState('Please log in to see your ride history')
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBookingsTab(userId),
                _buildDriverRidesTab(userId),
              ],
            ),
    );
  }

  Widget _buildBookingsTab(String userId) {
    return StreamBuilder<List<BookingModel>>(
      stream: _firestoreService.getMyBookings(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2563EB)),
          );
        }

        final bookings = snapshot.data ?? [];
        if (bookings.isEmpty) {
          return _buildEmptyState('No bookings yet.\nFind a ride and book your first trip!');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            return _buildBookingCard(bookings[index]);
          },
        );
      },
    );
  }

  Widget _buildDriverRidesTab(String userId) {
    return StreamBuilder<List<RideModel>>(
      stream: _firestoreService.getDriverRides(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2563EB)),
          );
        }

        final rides = snapshot.data ?? [];
        if (rides.isEmpty) {
          return _buildEmptyState('No rides offered yet.\nStart offering rides to see them here!');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: rides.length,
          itemBuilder: (context, index) {
            return _buildDriverRideCard(rides[index]);
          },
        );
      },
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    final statusColor = switch (booking.status) {
      BookingStatus.confirmed => const Color(0xFF10B981),
      BookingStatus.pending => const Color(0xFFF59E0B),
      BookingStatus.cancelled => const Color(0xFFEF4444),
    };
    final statusText = switch (booking.status) {
      BookingStatus.confirmed => 'Confirmed',
      BookingStatus.pending => 'Pending',
      BookingStatus.cancelled => 'Cancelled',
    };
    final statusIcon = switch (booking.status) {
      BookingStatus.confirmed => Icons.check_circle_rounded,
      BookingStatus.pending => Icons.access_time_rounded,
      BookingStatus.cancelled => Icons.cancel_rounded,
    };

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HistoryRideDetailScreen(booking: booking),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking #${booking.id.substring(0, 8)}',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a').format(booking.createdAt),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (booking.otpVerified) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'OTP Verified — Ride Completed',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildDriverRideCard(RideModel ride) {
    final statusColor = switch (ride.status) {
      RideStatus.active => const Color(0xFF2563EB),
      RideStatus.full => const Color(0xFFF59E0B),
      RideStatus.completed => const Color(0xFF10B981),
      RideStatus.cancelled => const Color(0xFFEF4444),
    };
    final statusText = switch (ride.status) {
      RideStatus.active => 'Active',
      RideStatus.full => 'Full',
      RideStatus.completed => 'Completed',
      RideStatus.cancelled => 'Cancelled',
    };

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HistoryRideDetailScreen(ride: ride),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Route info
            Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF10B981), width: 2.5),
                      ),
                    ),
                    Container(
                      width: 1.5,
                      height: 24,
                      color: const Color(0xFFE2E8F0),
                    ),
                    const Icon(Icons.location_on, size: 14, color: Color(0xFFEF4444)),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.sourceName,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        ride.destinationName,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            // Bottom row
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 16, color: const Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(
                  DateFormat('dd MMM, hh:mm a').format(ride.dateTime),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '₹${ride.pricePerSeat.toInt()}/seat',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            if (ride.status == RideStatus.active) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people_rounded, size: 18, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${ride.seatsAvailable} of ${ride.seatsTotal} seats available',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 48,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
