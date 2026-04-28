import 'dart:async';
import 'dart:js_interop';
import 'dart:js_util' as js_util;
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as html;

/// Web-specific Places API implementation using Google Maps JavaScript API.
/// This avoids CORS issues by calling the JS API directly in the browser.

/// Search places using Google Maps JS AutocompleteSuggestion
Future<List<Map<String, dynamic>>> searchPlacesWeb(
  String query,
  double biasLat,
  double biasLng,
) async {
  try {
    final request = {
      'input': query,
      'componentRestrictions': {'country': 'in'},
    }.jsify() as JSObject;

    final response = await js_util.promiseToFuture<JSObject>(
      _AutocompleteSuggestionClass.fetchAutocompleteSuggestions(request),
    ).timeout(const Duration(seconds: 8), onTimeout: () => JSObject());

    final suggestions = js_util.getProperty(response, 'suggestions');
    if (suggestions is! JSArray) return [];

    final results = <Map<String, dynamic>>[];
    final dartSuggestions = suggestions.toDart;
    for (int i = 0; i < dartSuggestions.length; i++) {
      final suggestion = dartSuggestions[i];
      if (suggestion is! JSObject) continue;
      final prediction = js_util.getProperty(suggestion, 'placePrediction');
      if (prediction is! JSObject) continue;

      final placeId = _readText(js_util.getProperty(prediction, 'placeId'));
      final fullText = _readText(js_util.getProperty(prediction, 'text'));
      final structured = js_util.getProperty(prediction, 'structuredFormat');
      final mainText = structured is JSObject
          ? _readText(js_util.getProperty(structured, 'mainText'))
          : '';
      final secondaryText = structured is JSObject
          ? _readText(js_util.getProperty(structured, 'secondaryText'))
          : '';

      if (placeId.isEmpty) continue;
      results.add({
        'place_id': placeId,
        'description': fullText,
        'main_text': mainText.isNotEmpty ? mainText : fullText,
        'secondary_text': secondaryText,
      });
    }

    return results;
  } catch (e) {
    debugPrint('⚠️ Web Places search error: $e');
    return [];
  }
}

/// Get place details using Google Maps JS PlacesService
Future<Map<String, dynamic>?> getPlaceDetailsWeb(String placeId) async {
  try {
    final completer = Completer<Map<String, dynamic>?>();

    final service = _getPlacesService();
    if (service == null) {
      debugPrint('⚠️ Google Maps JS PlacesService not available');
      return null;
    }

    final request = {
      'placeId': placeId,
      'fields': ['name', 'geometry', 'formatted_address'],
    }.jsify() as JSObject;

    service.getDetails(
      request,
      ((JSObject? rawPlace, JSString status) {
        if (status.toDart != 'OK' || rawPlace == null) {
          completer.complete(null);
          return;
        }

        final place = rawPlace as _PlaceResult;
        final geometry = place.geometry;
        if (geometry == null) {
          completer.complete(null);
          return;
        }

        final location = geometry.location;
        completer.complete({
          'name': place.name?.toDart ?? '',
          'address': place.formatted_address?.toDart ?? '',
          'lat': location.lat(),
          'lng': location.lng(),
        });
      }).toJS,
    );

    return await completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () => null,
    );
  } catch (e) {
    debugPrint('⚠️ Web Place details error: $e');
    return null;
  }
}

// ──────────────────────────────────────────────────────────
// JS Interop bindings for Google Maps Places JavaScript API
// ──────────────────────────────────────────────────────────

@JS('google.maps.places.AutocompleteSuggestion')
extension type _AutocompleteSuggestionClass._(JSObject _) implements JSObject {
  external static JSPromise fetchAutocompleteSuggestions(JSObject request);
}

@JS('google.maps.places.PlacesService')
extension type _PlacesServiceClass._(JSObject _) implements JSObject {
  external factory _PlacesServiceClass(JSObject attrContainer);
  external void getDetails(JSObject request, JSFunction callback);
}

@JS('google.maps.LatLng')
extension type _LatLngClass._(JSObject _) implements JSObject {
  external factory _LatLngClass(JSNumber lat, JSNumber lng);
  external double lat();
  external double lng();
}

extension type _PlaceResult._(JSObject _) implements JSObject {
  external JSString? get name;
  external JSString? get formatted_address;
  external _Geometry? get geometry;
}

extension type _Geometry._(JSObject _) implements JSObject {
  external _LatLngClass get location;
}

// ── Helper functions ──

String _readText(dynamic value) {
  if (value is JSString) return value.toDart;
  if (value is JSObject) {
    final inner = js_util.getProperty(value, 'text');
    if (inner is JSString) return inner.toDart;
  }
  return '';
}

_PlacesServiceClass? _getPlacesService() {
  try {
    // PlacesService needs a DOM element — create a hidden div
    final div = html.document.createElement('div');
    return _PlacesServiceClass(div as JSObject);
  } catch (e) {
    debugPrint('⚠️ Cannot create PlacesService: $e');
    return null;
  }
}

_LatLngClass _createLatLng(double lat, double lng) {
  return _LatLngClass(lat.toJS, lng.toJS);
}
