import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

// Conditional import for web JS interop
import 'places_service_web_stub.dart'
    if (dart.library.html) 'places_service_web.dart' as web_places;

/// Unified Places service that works on both mobile and web.
///
/// On MOBILE: Uses HTTP API (no CORS issues)
/// On WEB: Uses Google Maps JavaScript API via JS interop (avoids CORS)
class PlacesService {
  static const String _apiKey = 'AIzaSyCVpIx5LWUzmA8MKu12S1jwwi_RG5MaLjw';

  // Mumbai bias
  static const double _biasLat = 19.0760;
  static const double _biasLng = 72.8777;
  static const int _biasRadius = 50000;

  // Debounce timer for search
  static Timer? _debounceTimer;

  /// Search places with real-time autocomplete suggestions.
  /// Debounced to prevent excessive API calls.
  static Future<List<Map<String, dynamic>>> searchPlaces(
    String query, {
    LatLng? biasLocation,
  }) async {
    if (query.trim().isEmpty) return [];

    final lat = biasLocation?.latitude ?? _biasLat;
    final lng = biasLocation?.longitude ?? _biasLng;

    try {
      if (kIsWeb) {
        return await web_places.searchPlacesWeb(query, lat, lng);
      } else {
        return await _searchPlacesMobile(query, lat, lng);
      }
    } catch (e) {
      debugPrint('⚠️ PlacesService.searchPlaces error: $e');
      return [];
    }
  }

  /// Mobile: HTTP-based Places Autocomplete API
  static Future<List<Map<String, dynamic>>> _searchPlacesMobile(
    String query,
    double lat,
    double lng,
  ) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json'
      '?input=${Uri.encodeComponent(query)}'
      '&location=$lat,$lng'
      '&radius=$_biasRadius'
      '&components=country:in'
      '&key=$_apiKey',
    );

    final response = await http.get(url).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('Places API timed out'),
    );

    if (response.statusCode != 200) {
      debugPrint('⚠️ Places API HTTP ${response.statusCode}');
      return [];
    }

    final data = json.decode(response.body);
    if (data['status'] != 'OK' && data['status'] != 'ZERO_RESULTS') {
      debugPrint('⚠️ Places API status: ${data['status']} — ${data['error_message'] ?? ''}');
      return [];
    }

    final predictions = data['predictions'] as List? ?? [];
    return predictions.map<Map<String, dynamic>>((p) {
      return {
        'place_id': p['place_id'],
        'description': p['description'],
        'main_text': p['structured_formatting']?['main_text'] ?? p['description'],
        'secondary_text': p['structured_formatting']?['secondary_text'] ?? '',
      };
    }).toList();
  }

  /// Get place details (coordinates + formatted address) by placeId
  static Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    if (placeId.isEmpty) return null;

    try {
      if (kIsWeb) {
        return await web_places.getPlaceDetailsWeb(placeId);
      } else {
        return await _getPlaceDetailsMobile(placeId);
      }
    } catch (e) {
      debugPrint('⚠️ PlacesService.getPlaceDetails error: $e');
      return null;
    }
  }

  /// Mobile: HTTP-based Place Details API
  static Future<Map<String, dynamic>?> _getPlaceDetailsMobile(
    String placeId,
  ) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=$placeId'
      '&fields=name,geometry,formatted_address'
      '&key=$_apiKey',
    );

    final response = await http.get(url).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('Place Details API timed out'),
    );

    if (response.statusCode != 200) return null;

    final data = json.decode(response.body);
    if (data['status'] != 'OK') return null;

    final result = data['result'];
    final location = result['geometry']?['location'];
    if (location == null) return null;

    return {
      'name': result['name'] ?? result['formatted_address'] ?? '',
      'address': result['formatted_address'] ?? '',
      'lat': location['lat'],
      'lng': location['lng'],
    };
  }

  /// Reverse geocode: LatLng → Address
  static Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=$lat,$lng'
        '&key=$_apiKey',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Geocoding API timed out'),
      );

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);
      if (data['status'] != 'OK') return null;

      final results = data['results'] as List;
      if (results.isEmpty) return null;

      return results[0]['formatted_address'];
    } catch (e) {
      debugPrint('⚠️ Reverse geocode error: $e');
      return null;
    }
  }

  /// Debounced search — use this in UI for real-time suggestions
  static void searchDebounced(
    String query, {
    LatLng? biasLocation,
    required Function(List<Map<String, dynamic>>) onResults,
    Duration delay = const Duration(milliseconds: 350),
  }) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      onResults([]);
      return;
    }
    _debounceTimer = Timer(delay, () async {
      final results = await searchPlaces(query, biasLocation: biasLocation);
      onResults(results);
    });
  }

  /// Cancel any pending debounced search
  static void cancelPendingSearch() {
    _debounceTimer?.cancel();
  }
}
