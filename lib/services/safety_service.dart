import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';

/// Service to handle SOS alerts, emergency contact management,
/// and live location sharing during emergencies.
class SafetyService {
  static final FirestoreService _firestoreService = FirestoreService();
  static String? _activeAlertId;
  static StreamSubscription<LatLng>? _sosLocationSub;
  static bool _isSOSActive = false;

  static bool get isSOSActive => _isSOSActive;

  // ── Emergency Contacts ──

  /// Add an emergency contact (max 2)
  static Future<bool> addEmergencyContact(
      String name, String phone) async {
    final profile = await AuthService.loadCurrentUserProfile(forceRefresh: true);
    if (profile == null) return false;

    if (profile.emergencyContacts.length >= 2) return false;

    final updatedContacts = [
      ...profile.emergencyContacts,
      EmergencyContact(name: name, phone: phone),
    ];

    await AuthService.updateProfile(
      profile.copyWith(emergencyContacts: updatedContacts),
    );
    return true;
  }

  /// Remove an emergency contact by index
  static Future<void> removeEmergencyContact(int index) async {
    final profile = await AuthService.loadCurrentUserProfile(forceRefresh: true);
    if (profile == null) return;

    final updatedContacts = List<EmergencyContact>.from(profile.emergencyContacts);
    if (index < updatedContacts.length) {
      updatedContacts.removeAt(index);
    }

    await AuthService.updateProfile(
      profile.copyWith(emergencyContacts: updatedContacts),
    );
  }

  // ── SOS Trigger ──

  /// Trigger SOS: writes alert to Firestore, opens SMS to contacts, starts live location
  static Future<void> triggerSOS({
    required String rideId,
    required LatLng currentLocation,
  }) async {
    if (_isSOSActive) return;

    _isSOSActive = true;

    final profile = AuthService.cachedUserProfile;
    final userName = profile?.name ?? 'Commuto User';
    final contacts = profile?.emergencyContacts ?? [];

    // Build contact data
    final contactData = contacts.map((c) => {'name': c.name, 'phone': c.phone}).toList();

    // Write SOS alert to Firestore
    _activeAlertId = await _firestoreService.createSOSAlert(
      userId: AuthService.userId,
      rideId: rideId,
      lat: currentLocation.latitude,
      lng: currentLocation.longitude,
      contacts: contactData,
    );

    // Start continuous location sharing
    _sosLocationSub = LocationService.startTracking(distanceFilter: 5).listen(
      (position) {
        if (_activeAlertId != null) {
          _firestoreService.updateSOSLocation(
            _activeAlertId!,
            position.latitude,
            position.longitude,
          );
        }
      },
    );

    // Send SMS to all emergency contacts + 112
    final mapsLink =
        'https://maps.google.com/?q=${currentLocation.latitude},${currentLocation.longitude}';
    final message =
        'EMERGENCY SOS from $userName via Commuto! I need help. My current location: $mapsLink (Ride ID: $rideId)';

    final allPhones = <String>[
      ...contacts.map((c) => c.phone),
      '112', // National emergency
    ];

    final phoneList = allPhones.join(',');
    final smsUri = Uri.parse('sms:$phoneList?body=${Uri.encodeComponent(message)}');

    try {
      await launchUrl(smsUri);
    } catch (e) {
      debugPrint('Could not launch SMS: $e');
      // Fallback: try individual SMS
      for (final phone in allPhones) {
        try {
          await launchUrl(Uri.parse('sms:$phone?body=${Uri.encodeComponent(message)}'));
          break;
        } catch (_) {}
      }
    }
  }

  /// Stop SOS alert
  static Future<void> stopSOS() async {
    _isSOSActive = false;
    _sosLocationSub?.cancel();
    _sosLocationSub = null;

    if (_activeAlertId != null) {
      await _firestoreService.deactivateSOS(_activeAlertId!);
      _activeAlertId = null;
    }

    LocationService.stopTracking();
  }
}
