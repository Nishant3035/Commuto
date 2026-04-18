import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AadharVerificationBottomSheet extends StatefulWidget {
  final Function(String gender) onVerified;
  const AadharVerificationBottomSheet({super.key, required this.onVerified});

  @override
  State<AadharVerificationBottomSheet> createState() => _AadharVerificationBottomSheetState();
}

class _AadharVerificationBottomSheetState extends State<AadharVerificationBottomSheet> {
  bool _isOtpMode = false;
  bool _isLoading = false;
  final TextEditingController _aadharController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  void _handleVerifyAadhar() async {
    if (!_isOtpMode) {
      if (_aadharController.text.length != 12) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid 12-digit Aadhar number'))
        );
        return;
      }
      
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(seconds: 2)); // Simulate Aadhar API call
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isOtpMode = true;
        });
      }
    } else {
      if (_otpController.text.length != 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter the 6-digit OTP sent to your Aadhar-linked mobile'))
        );
        return;
      }

      setState(() => _isLoading = true);
      await Future.delayed(const Duration(milliseconds: 1500)); // Simulate OTP verification

      if (mounted) {
        setState(() => _isLoading = false);
        // Mock data extraction from Aadhar
        // For simulation, we'll let the user choose a gender if they aren't verified yet, 
        // or we'll "extract" it based on the mock.
        // The user specifically wants to ensure safety, so this is where the "real" check happens.
        
        _showGenderConfirmation();
      }
    }
  }

  void _showGenderConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Data Extracted', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Aadhar Verification Successful.', style: GoogleFonts.inter(color: Colors.green, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            _buildInfoRow('Name', 'Priya Sharma'),
            _buildInfoRow('Gender', 'Female'),
            _buildInfoRow('DOB', '15-08-2002'),
            const SizedBox(height: 16),
            Text(
              'Your details are verified. This ensures a safe environment for all Commuto users.',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              widget.onVerified('Female');
              Navigator.pop(context); // Close bottom sheet
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Details'),
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
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
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Secure Aadhar Verification',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your Aadhar is used only for identity and safety verification. We do not store your sensitive data.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 32),
          
          if (!_isOtpMode) ...[
            Text(
              'AADHAR NUMBER (12 DIGITS)',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF94A3B8),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _aadharController,
              keyboardType: TextInputType.number,
              maxLength: 12,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.0,
              ),
              decoration: InputDecoration(
                counterText: '',
                prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF2563EB)),
                hintText: 'XXXX XXXX XXXX',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ] else ...[
            Text(
              'ENTER 6-DIGIT OTP',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF94A3B8),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 8.0,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: 'XXXXXX',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'OTP sent to mobile linked with Aadhar',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
              ),
            ),
          ],
          
          const SizedBox(height: 40),
          
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleVerifyAadhar,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      _isOtpMode ? 'Verify OTP' : 'Send OTP',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
