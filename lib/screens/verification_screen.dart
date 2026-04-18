import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';

// Conditionally import ML Kit only on non-web platforms
import 'verification_native.dart' if (dart.library.html) 'verification_web.dart' as scanner;

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  bool _isScanning = false;
  bool _isSuccess = false;
  String? _extractedName;
  String? _extractedCollege;
  String? _extractedId;
  String? _detectedGender;
  String? _errorMessage;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (kIsWeb && source == ImageSource.camera) {
        setState(() => _errorMessage = 'Camera is not available on web. Please use Gallery.');
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (image != null && mounted) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = image;
          _imageBytes = bytes;
          _errorMessage = null;
          _isSuccess = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not access camera/gallery');
      }
    }
  }

  Future<void> _scanDocument() async {
    if (_selectedImage == null) {
      setState(() => _errorMessage = 'Please capture or select your College ID first');
      return;
    }

    setState(() {
      _isScanning = true;
      _errorMessage = null;
    });

    try {
      final result = await scanner.scanImage(_selectedImage!);

      if (result == null || (result['college'] == null && result['name'] == null)) {
        setState(() {
          _isScanning = false;
          _errorMessage = 'Could not identify a valid College ID. Make sure the full card is visible.';
        });
        return;
      }

      setState(() {
        _isScanning = false;
        _isSuccess = true;
        _extractedName = result['name'];
        _extractedCollege = result['college'];
        _extractedId = result['id'];
        _detectedGender = _guessGender(result['name'] ?? '');
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
        _errorMessage = 'Scanning failed: ${e.toString()}';
      });
    }
  }

  String _guessGender(String name) {
    final femaleSuffixes = ['a', 'i', 'ee', 'ya', 'ka', 'na', 'ta', 'sha', 'ha'];
    final lower = name.toLowerCase().split(' ').first;
    for (final suffix in femaleSuffixes) {
      if (lower.endsWith(suffix)) return 'Female';
    }
    return 'Male';
  }

  Future<void> _confirmVerification() async {
    await AuthService.completeStudentVerification(
      gender: _detectedGender ?? 'Unspecified',
    );
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('College ID Verification',
            style: GoogleFonts.inter(
                color: const Color(0xFF1A1D26), fontWeight: FontWeight.w800)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1A1D26)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildStepIndicator(),
            const SizedBox(height: 24),
            _buildCaptureArea(),
            const SizedBox(height: 24),

            if (!_isSuccess) ...[
              Row(
                children: [
                  if (!kIsWeb) ...[
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.camera_alt_rounded,
                        label: 'Camera',
                        onTap: () => _pickImage(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      onTap: () => _pickImage(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFDC2626), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

            if (_isSuccess) ...[
              const SizedBox(height: 8),
              _buildExtractedDetails(),
              const SizedBox(height: 8),
              _buildGenderSelector(),
            ],

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isScanning
                    ? null
                    : (_isSuccess ? _confirmVerification : _scanDocument),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSuccess
                      ? const Color(0xFF10B981)
                      : const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isScanning
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          ),
                          const SizedBox(width: 12),
                          Text(kIsWeb ? 'Verifying...' : 'Scanning with ML Kit...',
                              style: GoogleFonts.inter(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                        ],
                      )
                    : Text(
                        _isSuccess
                            ? 'Confirm & Verify'
                            : (_selectedImage != null
                                ? (kIsWeb ? 'Verify College ID' : 'Scan College ID')
                                : 'Select ID First'),
                        style: GoogleFonts.inter(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              kIsWeb
                  ? 'On web, verification is simulated for demo. Use the mobile app for ML Kit scanning.'
                  : 'We use on-device ML to read your College ID. Your photo is never uploaded to any server.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF94A3B8), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _stepDot(1, 'Capture', true),
        Expanded(child: Container(height: 2, color: _selectedImage != null ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0))),
        _stepDot(2, 'Scan', _selectedImage != null),
        Expanded(child: Container(height: 2, color: _isSuccess ? const Color(0xFF10B981) : const Color(0xFFE2E8F0))),
        _stepDot(3, 'Verify', _isSuccess),
      ],
    );
  }

  Widget _stepDot(int step, String label, bool active) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? (_isSuccess && step == 3 ? const Color(0xFF10B981) : const Color(0xFF2563EB))
                : const Color(0xFFE2E8F0),
          ),
          child: Center(
            child: active && (step < 3 || _isSuccess)
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text('$step', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: active ? Colors.white : const Color(0xFF94A3B8))),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: active ? const Color(0xFF0F172A) : const Color(0xFF94A3B8))),
      ],
    );
  }

  Widget _buildCaptureArea() {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: _isSuccess ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
            width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20)
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: _imageBytes != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(_imageBytes!, fit: BoxFit.cover),
                  if (_isSuccess)
                    Container(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      child: const Center(
                        child: Icon(Icons.check_circle, size: 64, color: Color(0xFF10B981)),
                      ),
                    ),
                  if (_isScanning)
                    Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      ),
                    ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.badge_outlined, size: 56, color: const Color(0xFF94A3B8).withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text('Capture your College ID',
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                  const SizedBox(height: 4),
                  Text(kIsWeb ? 'Select from gallery' : 'Use camera or select from gallery',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
                ],
              ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF2563EB), size: 28),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
          ],
        ),
      ),
    );
  }

  Widget _buildExtractedDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 20),
              const SizedBox(width: 8),
              Text('ID Verified Successfully',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF059669))),
            ],
          ),
          const SizedBox(height: 16),
          if (_extractedName != null) _infoRow('Name', _extractedName!),
          if (_extractedCollege != null) _infoRow('College', _extractedCollege!),
          if (_extractedId != null) _infoRow('Student ID', _extractedId!),
          _infoRow('Gender', _detectedGender ?? 'Unspecified'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF059669)))),
          Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF065F46)))),
        ],
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Confirm your gender (for safety features)',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
          const SizedBox(height: 12),
          Row(
            children: [
              _genderChip('Male', Icons.male_rounded),
              const SizedBox(width: 12),
              _genderChip('Female', Icons.female_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _genderChip(String gender, IconData icon) {
    final isSelected = _detectedGender == gender;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _detectedGender = gender),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF94A3B8)),
              const SizedBox(width: 8),
              Text(gender,
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B))),
            ],
          ),
        ),
      ),
    );
  }
}
