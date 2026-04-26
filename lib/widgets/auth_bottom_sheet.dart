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

  // OTP field key for programmatic clear/reset
  final GlobalKey<_OtpFieldWrapperState> _otpFieldKey = GlobalKey();

  Timer? _timer;
  int _start = 60;
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
    _start = 60;
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

  /// Go back from OTP mode to phone number entry
  void _backToPhone() {
    _timer?.cancel();
    setState(() {
      _isOtpMode = false;
      _isLoading = false;
      _errorText = null;
      _verificationId = null;
      _enteredOtp = '';
      _canResend = false;
      _start = 60;
    });
  }

  void _handleAction() async {
    setState(() {
      _errorText = null;
    });

    if (!_isOtpMode) {
      // ── PHONE NUMBER MODE ──
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
          isResend: false, // First time — not a resend
          onCodeSent: (verificationId) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _isOtpMode = true;
              _verificationId = verificationId;
            });
            _startTimer();
          },
          onError: (e) {
            if (!mounted) return;
            String errorMsg = e.message ?? 'Verification failed';
            if (errorMsg.contains('BILLING_NOT_ENABLED') ||
                errorMsg.contains('billing')) {
              errorMsg =
                  'Phone verification requires Firebase Blaze plan. Please upgrade at console.firebase.google.com';
            } else if (errorMsg.contains('too-many-requests')) {
              errorMsg = 'Too many attempts. Please wait a few minutes.';
            } else if (errorMsg.contains('invalid-phone-number')) {
              errorMsg = 'Invalid phone number format. Please check and try again.';
            }
            setState(() {
              _isLoading = false;
              _errorText = errorMsg;
            });
          },
          onVerificationCompleted: () {
            // Auto-verification on Android
            if (mounted) {
              Navigator.pop(context, true);
            }
          },
        );
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorText = 'An error occurred. Please try again.';
        });
      }
    } else {
      // ── OTP VERIFICATION MODE ──
      if (_enteredOtp.length < 6) {
        setState(() {
          _errorText = 'Enter the 6-digit code';
        });
        return;
      }

      setState(() => _isLoading = true);

      try {
        // signInWithOtp uses the stored verificationId internally as fallback
        await AuthService.signInWithOtp(_verificationId!, _enteredOtp);
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        // Check if sign-in actually succeeded despite the exception
        if (AuthService.isLoggedIn) {
          if (mounted) {
            Navigator.pop(context, true);
          }
          return;
        }

        if (!mounted) return;

        String errorMsg = 'Invalid OTP. Please try again.';
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('invalid-verification-code') ||
            errStr.contains('wrong')) {
          errorMsg = 'Wrong verification code. Please check and re-enter.';
        } else if (errStr.contains('session-expired') ||
            errStr.contains('expired') ||
            errStr.contains('invalid-verification-id')) {
          errorMsg = 'Code expired. Please tap Resend to get a new code.';
          // Enable resend immediately on session expiry
          _timer?.cancel();
          _canResend = true;
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
        isResend: true, // Use stored forceResendingToken
        onCodeSent: (verificationId) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _verificationId = verificationId;
            _errorText = null;
          });
          _startTimer();

          // Show success feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('New code sent!',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        onError: (e) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _errorText = e.message ?? 'Failed to resend code';
          });
        },
        onVerificationCompleted: () {
          if (mounted) {
            Navigator.pop(context, true);
          }
        },
      );
    } catch (e) {
      if (!mounted) return;
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

            // Back button + Icon badge row
            Row(
              children: [
                if (_isOtpMode)
                  GestureDetector(
                    onTap: _backToPhone,
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: Color(0xFF475569), size: 20),
                    ),
                  ),
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
                    _isOtpMode
                        ? Icons.sms_outlined
                        : Icons.phone_android_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ],
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
                              onSubmitted: (_) => _handleAction(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            else
              // OTP Input — use a fresh key to force rebuild on resend
              _OtpFieldWrapper(
                key: _otpFieldKey,
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
                          onPressed: _isLoading ? null : _resendCode,
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
                        _isOtpMode ? 'Verify' : 'Send Code',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
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

/// Wrapper for OtpField that can be rebuilt on resend to clear fields
class _OtpFieldWrapper extends StatefulWidget {
  final bool hasError;
  final Function(String) onChanged;
  final Function(String) onCompleted;

  const _OtpFieldWrapper({
    super.key,
    required this.hasError,
    required this.onChanged,
    required this.onCompleted,
  });

  @override
  State<_OtpFieldWrapper> createState() => _OtpFieldWrapperState();
}

class _OtpFieldWrapperState extends State<_OtpFieldWrapper> {
  Key _internalKey = UniqueKey();

  void reset() {
    setState(() => _internalKey = UniqueKey());
  }

  @override
  Widget build(BuildContext context) {
    return OtpField(
      key: _internalKey,
      length: 6,
      hasError: widget.hasError,
      onChanged: widget.onChanged,
      onCompleted: widget.onCompleted,
    );
  }
}
