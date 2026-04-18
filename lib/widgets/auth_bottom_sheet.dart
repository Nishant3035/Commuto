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

class _AuthBottomSheetState extends State<AuthBottomSheet>
    with SingleTickerProviderStateMixin {
  bool _isOtpMode = false;
  bool _isLoading = false;
  String? _errorText;
  String? _verificationId;
  final TextEditingController _phoneController = TextEditingController();
  String _enteredOtp = "";

  Timer? _timer;
  int _start = 30;
  bool _canResend = false;

  late AnimationController _sheetAnimController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _sheetAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn = CurvedAnimation(
      parent: _sheetAnimController,
      curve: Curves.easeOutCubic,
    );
    _sheetAnimController.forward();
  }

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

      // Demo mode: skip OTP, directly log in
      if (AuthService.demoMode) {
        setState(() => _isLoading = true);
        try {
          await AuthService.demoLogin(_phoneController.text.trim());
          if (mounted) {
            Navigator.pop(context, true);
          }
        } catch (e) {
          setState(() {
            _isLoading = false;
            _errorText = 'Something went wrong. Please try again.';
          });
        }
        return;
      }

      // Real Firebase OTP flow
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
            if (errorMsg.contains('BILLING_NOT_ENABLED') ||
                errorMsg.contains('billing')) {
              errorMsg =
                  'Phone verification requires Firebase Blaze plan. Please upgrade at console.firebase.google.com';
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
        String errorMsg = 'Invalid OTP. Please try again.';
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('invalid-verification-code') ||
            errStr.contains('wrong')) {
          errorMsg = 'Wrong verification code. Please check and re-enter.';
        } else if (errStr.contains('session-expired') ||
            errStr.contains('expired')) {
          errorMsg = 'Code expired. Please tap Resend to get a new code.';
        } else if (errStr.contains('too-many-requests') ||
            errStr.contains('quota')) {
          errorMsg = 'Too many attempts. Please wait a few minutes.';
        } else if (errStr.contains('network')) {
          errorMsg = 'Network error. Please check your connection.';
        }
        setState(() {
          _isLoading = false;
          _errorText = errorMsg;
        });
      }
    }
  }

  void _resendCode() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
      _enteredOtp = '';
    });

    try {
      await AuthService.verifyPhone(
        phone: _phoneController.text.trim(),
        onCodeSent: (verificationId) {
          setState(() {
            _isLoading = false;
            _verificationId = verificationId;
          });
          _startTimer();
        },
        onError: (e) {
          setState(() {
            _isLoading = false;
            _errorText = e.message ?? 'Failed to resend code';
          });
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorText = 'Failed to resend. Try again.';
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _timer?.cancel();
    _sheetAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine bottom padding for keyboard
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return FadeTransition(
      opacity: _fadeIn,
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
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 30,
              offset: Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle pill
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Icon badge
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                _isOtpMode ? Icons.sms_outlined : Icons.phone_android_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              _isOtpMode ? 'Enter verification code' : 'Welcome to Commuto',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              _isOtpMode
                  ? 'We sent a code to +91 ${_phoneController.text}'
                  : AuthService.demoMode
                      ? 'Enter your phone number to get started instantly.'
                      : "We'll send you a 6-digit verification code to keep your account safe.",
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
                height: 1.5,
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
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2563EB).withValues(alpha: 0.08),
                          const Color(0xFF2563EB).withValues(alpha: 0.04),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '+91',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Phone Number Input
                  Expanded(
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 16, right: 10),
                            child: Icon(Icons.phone_android_rounded,
                                color: Color(0xFF94A3B8), size: 20),
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
                                color: const Color(0xFF0F172A),
                                letterSpacing: 1.5,
                              ),
                              decoration: InputDecoration(
                                counterText: "",
                                hintText: '98765 43210',
                                border: InputBorder.none,
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF94A3B8),
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
                          onPressed: _resendCode,
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
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFFECACA),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Color(0xFFEF4444), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorText!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 28),

            // Continue / Verify Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D4ED8),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      const Color(0xFF1D4ED8).withValues(alpha: 0.6),
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
                        _isOtpMode
                            ? 'Verify'
                            : AuthService.demoMode
                                ? 'Continue'
                                : 'Send Code',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
              ),
            ),

            if (AuthService.demoMode && !_isOtpMode)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline,
                            color: Color(0xFF16A34A), size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Demo mode — no OTP needed',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ],
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
