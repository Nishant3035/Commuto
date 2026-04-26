import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/safety_service.dart';
import '../services/location_service.dart';

/// Persistent SOS overlay button for active rides.
/// Long-press activates a 3-second countdown, then triggers SOS.
class SOSOverlayWidget extends StatefulWidget {
  final String rideId;
  final VoidCallback? onSOSTriggered;

  const SOSOverlayWidget({
    super.key,
    required this.rideId,
    this.onSOSTriggered,
  });

  @override
  State<SOSOverlayWidget> createState() => _SOSOverlayWidgetState();
}

class _SOSOverlayWidgetState extends State<SOSOverlayWidget>
    with SingleTickerProviderStateMixin {
  bool _isCountingDown = false;
  int _countdown = 3;
  Timer? _countdownTimer;
  bool _isSOSActive = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    if (_isSOSActive) return;

    HapticFeedback.heavyImpact();
    setState(() {
      _isCountingDown = true;
      _countdown = 3;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown <= 1) {
        timer.cancel();
        _activateSOS();
      } else {
        HapticFeedback.mediumImpact();
        setState(() => _countdown--);
      }
    });
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _isCountingDown = false;
      _countdown = 3;
    });
  }

  Future<void> _activateSOS() async {
    setState(() {
      _isCountingDown = false;
      _isSOSActive = true;
    });
    _pulseController.repeat(reverse: true);
    HapticFeedback.heavyImpact();

    // Get current location with fallback and trigger SOS
    try {
      final location = await LocationService.getCurrentLocation();
      final loc = location ?? const LatLng(19.0760, 72.8777);

      await SafetyService.triggerSOS(
        rideId: widget.rideId,
        currentLocation: loc,
      );

      widget.onSOSTriggered?.call();
    } catch (e) {
      debugPrint('⚠️ SOS activation error: $e');
      // Still keep SOS active visually even if SMS fails
    }
  }

  Future<void> _deactivateSOS() async {
    await SafetyService.stopSOS();
    _pulseController.stop();
    _pulseController.reset();
    setState(() => _isSOSActive = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isSOSActive) {
      return _buildActiveSOSBanner();
    }

    if (_isCountingDown) {
      return _buildCountdownOverlay();
    }

    return _buildSOSButton();
  }

  Widget _buildSOSButton() {
    return Positioned(
      right: 16,
      bottom: 100,
      child: GestureDetector(
        onLongPress: _startCountdown,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sos_rounded, color: Colors.white, size: 22),
              Text(
                'HOLD',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: _cancelCountdown,
        child: Container(
          color: Colors.black.withValues(alpha: 0.7),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFEF4444), width: 4),
                    color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                  ),
                  child: Center(
                    child: Text(
                      '$_countdown',
                      style: GoogleFonts.inter(
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'ACTIVATING SOS...',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tap anywhere to cancel',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSOSBanner() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 12,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              color: Color.lerp(
                const Color(0xFFDC2626),
                const Color(0xFFEF4444),
                _pulseController.value,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444)
                      .withValues(alpha: 0.3 + (_pulseController.value * 0.3)),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.sos_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'SOS ACTIVE',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        'Help is being notified',
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _deactivateSOS,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'STOP',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
