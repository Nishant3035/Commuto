import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SafetyDialogs {
  /// Shows a warning if a female user tries to join a ride that contains male passengers.
  /// Returns `true` if they wish to proceed anyway, or `false` to cancel.
  static Future<bool> showMixedGenderWarning(BuildContext context, int maleCount) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_outlined, color: Color(0xFFEF4444), size: 36),
                ),
                const SizedBox(height: 20),
                Text(
                  'Safety Notice',
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 12),
                Text(
                  'There are currently $maleCount male passenger(s) in this ride. Would you still like to join?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF64748B), height: 1.5),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          'Wait for next',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF64748B)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444), // Warning Red
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          'Yes, Join',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return result ?? false;
  }
}
