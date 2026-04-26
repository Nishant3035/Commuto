import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/ride_model.dart';
import '../models/user_model.dart';
import '../widgets/ride_otp_bottom_sheet.dart';
import '../widgets/sos_overlay_widget.dart';
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
  GoogleMapController? _mapController;
  LatLng? _driverLiveLocation;
  StreamSubscription<GeoPoint?>? _locationSub;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _fetchDriver();
    _startTrackingDriver();
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _fetchDriver() async {
    final driver = await AuthService.getUserProfile(widget.rideData.driverId);
    if (mounted) {
      setState(() => _driver = driver);
    }
  }

  void _startTrackingDriver() {
    _locationSub = _firestoreService
        .streamRideLiveLocation(widget.rideData.id)
        .listen((geoPoint) {
      if (geoPoint != null && mounted) {
        setState(() {
          _driverLiveLocation = LatLng(geoPoint.latitude, geoPoint.longitude);
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(_driverLiveLocation!),
        );
      }
    });
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
          content: Text(
            'Boarded! ₹${_finalPaidAmount.toStringAsFixed(0)} reserved from wallet.',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF34A853),
        ),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Rate Your Driver',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'How was your trip with ${_driver?.name ?? 'your driver'}?',
                    style: GoogleFonts.inter(color: const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (index) {
                      return InkWell(
                        onTap: () async {
                          setState(() => selectedRating = index + 1);
                          await Future.delayed(
                              const Duration(milliseconds: 300));
                          if (!context.mounted) return;
                          Navigator.pop(context);

                          if (_driver != null) {
                            try {
                              await FirestoreService()
                                  .submitRating(_driver!.id, index + 1.0);
                            } catch (e) {
                              // Silent fail
                            }
                          }

                          if (mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text('Thank you for rating!',
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600)),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                            Navigator.popUntil(
                                this.context, (route) => route.isFirst);
                          }
                        },
                        child: Icon(
                          index < selectedRating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 36,
                          color: index < selectedRating
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFCBD5E1),
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
                    Navigator.popUntil(this.context, (route) => route.isFirst);
                  },
                  child: const Text('Skip',
                      style: TextStyle(color: Color(0xFF94A3B8))),
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
    final source = LatLng(
      widget.rideData.sourceLatLng.latitude,
      widget.rideData.sourceLatLng.longitude,
    );
    final dest = LatLng(
      widget.rideData.destinationLatLng.latitude,
      widget.rideData.destinationLatLng.longitude,
    );

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('source'),
        position: source,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: widget.rideData.sourceName),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: dest,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: widget.rideData.destinationName),
      ),
    };

    if (_driverLiveLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverLiveLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
              title: '${_driver?.name ?? "Driver"} (Live)'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Column(
            children: [
              // Map Section
              SizedBox(
                height: 280,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _driverLiveLocation ?? source,
                    zoom: 13,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    // Fit bounds to show all markers
                    final bounds = LatLngBounds(
                      southwest: LatLng(
                        source.latitude < dest.latitude
                            ? source.latitude
                            : dest.latitude,
                        source.longitude < dest.longitude
                            ? source.longitude
                            : dest.longitude,
                      ),
                      northeast: LatLng(
                        source.latitude > dest.latitude
                            ? source.latitude
                            : dest.latitude,
                        source.longitude > dest.longitude
                            ? source.longitude
                            : dest.longitude,
                      ),
                    );
                    Future.delayed(const Duration(milliseconds: 300), () {
                      controller.animateCamera(
                        CameraUpdate.newLatLngBounds(bounds, 60),
                      );
                    });
                  },
                  markers: markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
              ),

              // Content below map
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Status Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: _hasBoarded
                              ? const Color(0xFFECFDF5)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _hasBoarded
                                ? const Color(0xFF10B981)
                                    .withValues(alpha: 0.3)
                                : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _hasBoarded
                                  ? Icons.check_circle
                                  : Icons.directions_car,
                              size: 48,
                              color: _hasBoarded
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF2563EB),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _hasBoarded
                                  ? 'You are on board!'
                                  : 'Waiting for Driver',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _hasBoarded
                                  ? 'Fare processing secured.'
                                  : 'Enter OTP to confirm boarding.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            if (_driverLiveLocation != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.gps_fixed,
                                        size: 14, color: Color(0xFF2563EB)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Live tracking active',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF2563EB),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Driver Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(0xFFEFF6FF),
                              child: Text(
                                _driver?.initials ?? '?',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF2563EB),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Your Driver',
                                      style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: const Color(0xFF64748B),
                                          fontWeight: FontWeight.w600)),
                                  Text(
                                    _driver?.name ?? 'Loading...',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chat_bubble,
                                  color: Color(0xFF2563EB)),
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

                      const SizedBox(height: 24),

                      if (!_hasBoarded)
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _handleBoarding,
                            icon: const Icon(Icons.qr_code_scanner),
                            label: Text('Boarding (Enter OTP)',
                                style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
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
                            label: Text('End of Ride',
                                style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0F172A),
                              side: const BorderSide(
                                  color: Color(0xFF0F172A), width: 2),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // SOS Overlay
          SOSOverlayWidget(rideId: widget.rideData.id),
        ],
      ),
    );
  }
}
