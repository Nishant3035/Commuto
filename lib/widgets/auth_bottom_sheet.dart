import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'otp_field.dart';

class AuthBottomSheet extends StatefulWidget {
  const AuthBottomSheet({super.key});

  @override
  State<AuthBottomSheet> createState() => _AuthBottomSheetState();
}

class _AuthBottomSheetState extends State<AuthBottomSheet> {
  bool _isOtpMode = false;
  bool _isLoading = false;
  String? _errorText;
  String? _verificationId;
  final TextEditingController _phoneController = TextEditingController();
  String _enteredOtp = "";
  
  Timer? _timer;
  int _start = 30;
  bool _canResend = false;

  void _startTimer() {
    _canResend = false;
    _start = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _canResend = true;
          timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  void _handleAction() async {
    setState(() {
      _errorText = null;
    });

    if (!_isOtpMode) {
      if (_phoneController.text.trim().length < 10) {
        setState(() {
          _errorText = 'Enter a valid 10-digit number';
        });
        return;
      }
      setState(() => _isLoading = true);
      
      try {
        await AuthService.verifyPhone(
          phone: _phoneController.text.trim(),
          onCodeSent: (verificationId) {
            setState(() {
              _isLoading = false;
              _isOtpMode = true;
              _verificationId = verificationId;
            });
            _startTimer();
          },
          onError: (e) {
            String errorMsg = e.message ?? 'Verification failed';
            // Firebase Spark plan doesn't support phone auth
            if (errorMsg.contains('BILLING_NOT_ENABLED') || errorMsg.contains('billing')) {
              errorMsg = 'Phone verification requires Firebase Blaze plan. Please upgrade at console.firebase.google.com';
            }
            setState(() {
              _isLoading = false;
              _errorText = errorMsg;
            });
          },
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorText = 'An error occurred. Please try again.';
        });
      }
    } else {
      // OTP Verification Mode
      if (_enteredOtp.length < 6) {
        setState(() {
          _errorText = 'Enter the 6-digit code';
        });
        return;
      }

      setState(() => _isLoading = true);
      
      try {
        await AuthService.signInWithOtp(_verificationId!, _enteredOtp);
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorText = 'Invalid OTP. Please try again.';
        });
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine bottom padding for keyboard
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
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
          // Drag handle pill
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

          // Title
          Text(
            _isOtpMode ? 'Enter verification code' : 'Enter your number',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1D26),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            _isOtpMode
                ? 'We sent a code to +91 ${_phoneController.text}'
                : "We'll send you a 6-digit verification code to keep your account safe.",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),

          // Input Fields
          if (!_isOtpMode)
            Row(
              children: [
                // Country Code
                Container(
                  width: 72,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '+91',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1D26),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Phone Number Input
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFD6E4F9), width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 16, right: 10),
                          child: Icon(Icons.phone_android_rounded,
                              color: Color(0xFF9CA3AF), size: 20),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            autofocus: true,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1D26),
                              letterSpacing: 1.0,
                            ),
                            decoration: InputDecoration(
                              counterText: "",
                              hintText: '98765 43210',
                              border: InputBorder.none,
                              hintStyle: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF9CA3AF).withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          else
            // New Individual Box OTP Input
            OtpField(
              length: 6,
              hasError: _errorText != null,
              onChanged: (val) {
                _enteredOtp = val;
                if (_errorText != null) setState(() => _errorText = null);
              },
              onCompleted: (val) {
                _enteredOtp = val;
                _handleAction();
              },
            ),
          
          if (_isOtpMode)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Center(
                child: _canResend
                    ? TextButton(
                        onPressed: _handleAction,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF1D4ED8),
                        ),
                        child: Text(
                          'Resend Code',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Resend code in ',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            '0:${_start.toString().padLeft(2, '0')}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1D4ED8),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

          if (_errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _errorText!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.redAccent,
                ),
              ),
            ),

          const SizedBox(height: 32),

          // Send Code / Verify Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D4ED8), // Deep vibrant blue
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
                      _isOtpMode ? 'Verify' : 'Send Code',
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
    );
  }
}
