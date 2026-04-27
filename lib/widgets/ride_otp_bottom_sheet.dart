import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'otp_field.dart';
import '../services/firestore_service.dart';

class RideOtpBottomSheet extends StatefulWidget {
  final String bookingId;
  final String? rideId;

  const RideOtpBottomSheet({
    super.key,
    required this.bookingId,
    this.rideId,
  });

  @override
  State<RideOtpBottomSheet> createState() => _RideOtpBottomSheetState();
}

class _RideOtpBottomSheetState extends State<RideOtpBottomSheet>
    with SingleTickerProviderStateMixin {
  String _enteredOtp = "";
  bool _isLoading = false;
  String? _errorText;
  
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  void _verifyOtp() async {
    if (_enteredOtp.length < 4) {
      setState(() => _errorText = 'Enter 4-digit code');
      return;
    }

    // Guard against duplicate calls
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      debugPrint('🔐 RideOtpBottomSheet: verifying OTP "$_enteredOtp" for booking ${widget.bookingId}');
      final success =
          await FirestoreService().verifyOtp(widget.bookingId, _enteredOtp);
      
      if (success) {
        if (mounted) {
          Navigator.pop(context, true); // Success
        }
      } else {
        // If the full verify failed, try a direct OTP check to give a better error
        if (widget.rideId != null) {
          final otpMatch = await FirestoreService().checkOtpOnly(widget.rideId!, _enteredOtp);
          if (otpMatch) {
            _handleError('OTP correct but booking failed. Try again.');
          } else {
            _handleError('Incorrect OTP. Please check with your host.');
          }
        } else {
          _handleError('Incorrect OTP. Please check with your host.');
        }
      }
    } catch (e) {
      debugPrint('❌ RideOtpBottomSheet error: $e');
      final errorMsg = e.toString();
      if (errorMsg.contains('No seats available')) {
        _handleError('No seats available. Ride is full.');
      } else {
        _handleError('Verification error. Please try again.');
      }
    }
  }

  void _handleError(String message) {
    if (!mounted) return;
    _shakeController.forward(from: 0.0);
    setState(() {
      _isLoading = false;
      _errorText = message;
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    final dx = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.linear));

    return AnimatedBuilder(
      animation: dx,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(dx.value, 0),
          child: child,
        );
      },
      child: Container(
        padding: EdgeInsets.only(
          top: 16,
          left: 24,
          right: 24,
          bottom: 32 + bottomInset,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F1FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shield_rounded, color: Color(0xFF2B7DE9)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enter Ride OTP',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A1D26),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enter the 4-digit code provided by your host',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            OtpField(
              length: 4,
              hasError: _errorText != null,
              onChanged: (val) {
                _enteredOtp = val;
                if (_errorText != null) setState(() => _errorText = null);
              },
              onCompleted: (val) {
                _enteredOtp = val;
                _verifyOtp();
              },
            ),

            if (_errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: Text(
                    _errorText!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2B7DE9),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Unlock Ride',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
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
