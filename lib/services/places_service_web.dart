import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as html;

/// Web-specific Places API implementation using Google Maps JavaScript API.
/// This avoids CORS issues by calling the JS API directly in the browser.

/// Search places using Google Maps JS AutocompleteService
Future<List<Map<String, dynamic>>> searchPlacesWeb(
  String query,
  double biasLat,
  double biasLng,
) async {
  try {
    final completer = Completer<List<Map<String, dynamic>>>();

    // Access the google.maps.places.AutocompleteService via JS interop
    final service = _getAutocompleteService();
    if (service == null) {
      debugPrint('⚠️ Google Maps JS AutocompleteService not available');
      return [];
    }

    final request = {
      'input': query,
      'componentRestrictions': {'country': 'in'},
    }.jsify() as JSObject;

    service.getPlacePredictions(
      request,
      ((JSArray? predictions, JSString status) {
        if (status.toDart != 'OK') {
          debugPrint('⚠️ Web Places API Error: ${status.toDart}');
          completer.complete([]);
          return;
        }
        if (predictions == null) {
          completer.complete([]);
          return;
        }

        final results = <Map<String, dynamic>>[];
        final dartPredictions = predictions.toDart;
        for (int i = 0; i < dartPredictions.length; i++) {
          final p = dartPredictions[i] as _AutocompletePrediction;
          results.add({
            'place_id': p.place_id.toDart,
            'description': p.description.toDart,
            'main_text': p.structured_formatting?.main_text?.toDart ?? p.description.toDart,
            'secondary_text': p.structured_formatting?.secondary_text?.toDart ?? '',
          });
        }
        completer.complete(results);
      }).toJS,
    );

    return await completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () => [],
    );
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

@JS('google.maps.places.AutocompleteService')
extension type _AutocompleteServiceClass._(JSObject _) implements JSObject {
  external factory _AutocompleteServiceClass();
  external void getPlacePredictions(JSObject request, JSFunction callback);
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

extension type _AutocompleteRequest._(JSObject _) implements JSObject {
  external factory _AutocompleteRequest({
    JSString input,
    _ComponentRestrictions componentRestrictions,
  });
}

extension type _ComponentRestrictions._(JSObject _) implements JSObject {
  external factory _ComponentRestrictions({JSString country});
}

extension type _PlaceDetailsRequest._(JSObject _) implements JSObject {
  external factory _PlaceDetailsRequest({
    JSString placeId,
    JSArray fields,
  });
}

extension type _AutocompletePrediction._(JSObject _) implements JSObject {
  external JSString get place_id;
  external JSString get description;
  external _StructuredFormatting? get structured_formatting;
}

extension type _StructuredFormatting._(JSObject _) implements JSObject {
  external JSString? get main_text;
  external JSString? get secondary_text;
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

_AutocompleteServiceClass? _getAutocompleteService() {
  try {
    return _AutocompleteServiceClass();
  } catch (e) {
    debugPrint('⚠️ Cannot create AutocompleteService: $e');
    return null;
  }
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
