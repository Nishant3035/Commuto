import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'map_picker_screen.dart';
import 'driver_active_ride_screen.dart';
import '../utils/fare_calculator.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/ride_model.dart';

class OfferRideScreen extends StatefulWidget {
  final bool showBackButton;
  final VoidCallback? onRidePublished;

  const OfferRideScreen({
    super.key,
    this.showBackButton = true,
    this.onRidePublished,
  });

  @override
  State<OfferRideScreen> createState() => _OfferRideScreenState();
}

class _OfferRideScreenState extends State<OfferRideScreen>
    with SingleTickerProviderStateMixin {
  String? _pickupAddress;
  LatLng? _pickupLatLng;
  String? _destinationAddress;
  LatLng? _destinationLatLng;
  TimeOfDay? _selectedTime;
  int _seats = 3; // Default 3 for auto sharing
  bool _allowMales = true; // Default allow all
  bool _isLoading = false;
  final TextEditingController _notesController = TextEditingController();

  FareBreakdown? _fareBreakdown;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _calculateFare() {
    if (_pickupLatLng != null && _destinationLatLng != null) {
      final distance = FareCalculator.calculateDistance(
        _pickupLatLng!.latitude,
        _pickupLatLng!.longitude,
        _destinationLatLng!.latitude,
        _destinationLatLng!.longitude,
      );
      setState(() {
        _fareBreakdown = FareCalculator.calculatePerPersonFare(
          distance,
          passengers: _seats,
        );
      });
    }
  }

  Future<void> _pickLocation({required bool isPickup}) async {
    final result = await Navigator.of(context).push<LocationResult>(
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          title: isPickup ? 'Pickup Location' : 'Destination',
          showCurrentLocation: isPickup,
          initialPosition: isPickup ? _pickupLatLng : _destinationLatLng,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        if (isPickup) {
          _pickupAddress = result.address;
          _pickupLatLng = result.latLng;
        } else {
          _destinationAddress = result.address;
          _destinationLatLng = result.latLng;
        }
      });
      _calculateFare();
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2B7DE9),
              onSurface: Color(0xFF1A1D26),
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _publishRide() async {
    if (_pickupAddress == null || _destinationAddress == null) {
      _showError('Please select both pickup and destination on the map');
      return;
    }
    if (_selectedTime == null) {
      _showError('Please select a time for the ride');
      return;
    }
    if (_fareBreakdown == null) {
      _showError('Unable to calculate fare. Please reselect your route.');
      return;
    }

    final didLogin = await AuthService.requireLogin(context);
    if (!didLogin || !mounted) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final rideDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final ride = RideModel(
        id: '', // Will be assigned by Firestore
        driverId: AuthService.userId,
        sourceName: _pickupAddress!,
        sourceLatLng: GeoPoint(_pickupLatLng!.latitude, _pickupLatLng!.longitude),
        destinationName: _destinationAddress!,
        destinationLatLng: GeoPoint(_destinationLatLng!.latitude, _destinationLatLng!.longitude),
        dateTime: rideDateTime,
        seatsTotal: _seats,
        seatsAvailable: _seats - 1,
        pricePerSeat: _fareBreakdown!.totalPerPerson,
        status: RideStatus.active,
        createdAt: DateTime.now(),
      );

      final rideId = await FirestoreService().createRide(ride);

      // Wait for the Cloud Function to generate the OTP
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        setState(() => _isLoading = false);
        // Capture values before reset
        final pickup = _pickupAddress!;
        final destination = _destinationAddress!;
        final time = _formatTime(_selectedTime!);
        final seats = _seats;
        final price = _fareBreakdown!.totalPerPerson;
        _resetForm();
        // Navigate to Driver Active Ride Screen for live updates
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DriverActiveRideScreen(
              rideId: rideId,
              pickup: pickup,
              destination: destination,
              time: time,
              totalSeats: seats,
              pricePerSeat: price,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to publish ride: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
        backgroundColor: const Color(0xFFE53E3E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _pickupAddress = null;
      _pickupLatLng = null;
      _destinationAddress = null;
      _destinationLatLng = null;
      _selectedTime = null;
      _seats = 3;
      _allowMales = true;
      _isLoading = false;
      _fareBreakdown = null;
      _notesController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  children: [
                    if (widget.showBackButton)
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            size: 20,
                            color: Color(0xFF1A1D26),
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 42, height: 42),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Offer a Ride',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A1D26),
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Share your ride, split the cost',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF1A1D26).withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Scrollable form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Route Section
                      _SectionLabel(label: 'ROUTE'),
                      const SizedBox(height: 10),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Pickup
                            _LocationField(
                              icon: Icons.radio_button_checked_rounded,
                              iconColor: const Color(0xFF34A853),
                              label: 'Pickup Location',
                              value: _pickupAddress,
                              placeholder: 'Select on map',
                              onTap: () => _pickLocation(isPickup: true),
                              trailing: const Icon(Icons.map_rounded, size: 18, color: Color(0xFF2B7DE9)),
                            ),

                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                children: [
                                  const SizedBox(width: 9),
                                  Column(
                                    children: List.generate(
                                      3,
                                      (i) => Container(
                                        width: 2,
                                        height: 4,
                                        margin: const EdgeInsets.symmetric(vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1A1D26).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(1),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                ],
                              ),
                            ),

                            // Destination
                            _LocationField(
                              icon: Icons.location_on_rounded,
                              iconColor: const Color(0xFFE53E3E),
                              label: 'Destination',
                              value: _destinationAddress,
                              placeholder: 'Select on map',
                              onTap: () => _pickLocation(isPickup: false),
                              trailing: const Icon(Icons.map_rounded, size: 18, color: Color(0xFF2B7DE9)),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Time Section
                      _SectionLabel(label: 'SCHEDULE'),
                      const SizedBox(height: 10),

                      GestureDetector(
                        onTap: _pickTime,
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.access_time_rounded,
                                  color: Color(0xFFF57C00),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Time of Ride',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF1A1D26).withValues(alpha: 0.4),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _selectedTime != null
                                          ? _formatTime(_selectedTime!)
                                          : 'Select departure time',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: _selectedTime != null
                                            ? const Color(0xFF1A1D26)
                                            : const Color(0xFF1A1D26).withValues(alpha: 0.3),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: Color(0xFFBFC5CF)),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Seats Section
                      _SectionLabel(label: 'PASSENGERS'),
                      const SizedBox(height: 10),

                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F1FD),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.people_rounded,
                                color: Color(0xFF2B7DE9),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total capacity',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF1A1D26).withValues(alpha: 0.4),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '$_seats people (including you)',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1A1D26),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // +/- selector
                            Row(
                              children: [
                                _SeatButton(
                                  icon: Icons.remove_rounded,
                                  onTap: () {
                                    if (_seats > 2) {
                                      setState(() => _seats--);
                                      _calculateFare();
                                    }
                                  },
                                  enabled: _seats > 2,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  child: Text(
                                    '$_seats',
                                    style: GoogleFonts.inter(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1A1D26),
                                    ),
                                  ),
                                ),
                                _SeatButton(
                                  icon: Icons.add_rounded,
                                  onTap: () {
                                    if (_seats < 6) {
                                      setState(() => _seats++);
                                      _calculateFare();
                                    }
                                  },
                                  enabled: _seats < 6,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Fare Breakdown (auto-calculated)
                      if (_fareBreakdown != null) ...[
                        _SectionLabel(label: 'FARE BREAKDOWN'),
                        const SizedBox(height: 10),

                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF34A853).withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Distance & Time
                              Row(
                                children: [
                                  _FareInfoChip(
                                    icon: Icons.straighten_rounded,
                                    label: '${_fareBreakdown!.distanceKm.toStringAsFixed(1)} km',
                                    color: const Color(0xFF2B7DE9),
                                  ),
                                  const SizedBox(width: 12),
                                  _FareInfoChip(
                                    icon: Icons.access_time_rounded,
                                    label: '~${_fareBreakdown!.estimatedMinutes.ceil()} min',
                                    color: const Color(0xFFF57C00),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Fare rows
                              _FareRow(
                                label: 'Total Auto Fare',
                                value: '₹${_fareBreakdown!.totalAutoFare.ceil()}',
                              ),
                              const SizedBox(height: 8),
                              _FareRow(
                                label: 'Split ÷ ${_fareBreakdown!.passengers}',
                                value: '₹${_fareBreakdown!.perPersonFare.ceil()}',
                              ),
                              const SizedBox(height: 8),
                              _FareRow(
                                label: 'App fee',
                                value: '+ ₹${_fareBreakdown!.appFee.ceil()}',
                                valueColor: const Color(0xFF9CA3AF),
                              ),

                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Divider(
                                  color: const Color(0xFF1A1D26).withValues(alpha: 0.08),
                                ),
                              ),

                              // Per person total
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Per person',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1A1D26),
                                    ),
                                  ),
                                  Text(
                                    '₹${_fareBreakdown!.totalPerPerson.ceil()}',
                                    style: GoogleFonts.inter(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF34A853),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              // Savings badge
                              if (_fareBreakdown!.savings > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE6F4EA),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.savings_rounded,
                                        size: 16,
                                        color: Color(0xFF34A853),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'You save ₹${_fareBreakdown!.savings.ceil()} per person!',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF34A853),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],

                      // Girls Only Preference (Visible to females only)
                      if (AuthService.userGender == 'Female') ...[
                        _SectionLabel(label: 'CROWD PREFERENCE'),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3))],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(color: const Color(0xFFFDF4FF), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.female_rounded, color: Color(0xFFD946EF), size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Allow Male Passengers', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1A1D26))),
                                    const SizedBox(height: 3),
                                    Text(
                                      _allowMales ? 'Anyone can join your ride' : 'Restricted to Girls Only for safety',
                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: _allowMales ? const Color(0xFF64748B) : const Color(0xFFD946EF)),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _allowMales,
                                activeTrackColor: const Color(0xFF2B7DE9).withValues(alpha: 0.5),
                                activeThumbColor: const Color(0xFF2B7DE9),
                                onChanged: (val) => setState(() => _allowMales = val),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Notes section
                      _SectionLabel(label: 'NOTES (OPTIONAL)'),
                      const SizedBox(height: 10),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _notesController,
                          maxLines: 3,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1A1D26),
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g. Leaving sharp at 9:15, near gate 2',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF1A1D26).withValues(alpha: 0.3),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(18),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Publish button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _publishRide,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF34A853),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: const Color(0xFF34A853).withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rocket_launch_rounded, size: 20),
                        SizedBox(width: 10),
                        Text('Publish Ride'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== Helper Widgets =====

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1A1D26).withValues(alpha: 0.35),
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SeatButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _SeatButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled
              ? const Color(0xFF2B7DE9).withValues(alpha: 0.1)
              : const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? const Color(0xFF2B7DE9)
              : const Color(0xFF1A1D26).withValues(alpha: 0.2),
        ),
      ),
    );
  }
}

class _LocationField extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;
  final Widget? trailing;

  const _LocationField({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1A1D26).withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value ?? placeholder,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: value != null ? FontWeight.w600 : FontWeight.w400,
                      color: value != null
                          ? const Color(0xFF1A1D26)
                          : const Color(0xFF1A1D26).withValues(alpha: 0.3),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right_rounded, color: Color(0xFFBFC5CF)),
          ],
        ),
      ),
    );
  }
}

class _FareInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FareInfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FareRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _FareRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF1A1D26).withValues(alpha: 0.55),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF1A1D26),
          ),
        ),
      ],
    );
  }
}

// ===== Success Dialog =====

class _RidePublishedDialog extends StatefulWidget {
  final String rideId;
  final String pickup;
  final String destination;
  final String time;
  final int seats;
  final FareBreakdown fareBreakdown;
  final VoidCallback onDone;

  const _RidePublishedDialog({
    required this.rideId,
    required this.pickup,
    required this.destination,
    required this.time,
    required this.seats,
    required this.fareBreakdown,
    required this.onDone,
  });

  @override
  State<_RidePublishedDialog> createState() => _RidePublishedDialogState();
}

class _RidePublishedDialogState extends State<_RidePublishedDialog> {
  String? _otp;

  @override
  void initState() {
    super.initState();
    _fetchOtp();
  }

  Future<void> _fetchOtp() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('rides')
          .doc(widget.rideId)
          .collection('private')
          .doc('data')
          .get();
      if (doc.exists) {
        setState(() {
          _otp = doc.data()?['otp_code'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching OTP: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFE6F4EA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF34A853),
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Ride Published! 🎉',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1D26),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Waiting for ${widget.seats - 1} more to join',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF1A1D26).withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _SummaryRow(
                    icon: Icons.radio_button_checked_rounded,
                    iconColor: const Color(0xFF34A853),
                    text: widget.pickup,
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    icon: Icons.location_on_rounded,
                    iconColor: const Color(0xFFE53E3E),
                    text: widget.destination,
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    icon: Icons.access_time_rounded,
                    iconColor: const Color(0xFFF57C00),
                    text: widget.time,
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    icon: Icons.people_rounded,
                    iconColor: const Color(0xFF2B7DE9),
                    text: '${widget.seats} passengers sharing',
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    icon: Icons.currency_rupee_rounded,
                    iconColor: const Color(0xFF34A853),
                    text: '₹${widget.fareBreakdown.totalPerPerson.ceil()} per person',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            
            // Driver OTP Block
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F1FD),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2B7DE9).withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    'Your Ride OTP',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2B7DE9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _otp ?? '....',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 6.0,
                      color: const Color(0xFF1A1D26),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ask riders for this code before they board',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1A1D26).withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: widget.onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2B7DE9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const _SummaryRow({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1A1D26),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
