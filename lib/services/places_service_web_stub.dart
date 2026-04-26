// Stub for non-web platforms.
// These functions are never called on mobile — the PlacesService uses HTTP API instead.
// This file exists only to satisfy the conditional import on non-web platforms.

Future<List<Map<String, dynamic>>> searchPlacesWeb(
  String query,
  double biasLat,
  double biasLng,
) async {
  throw UnsupportedError('searchPlacesWeb is only supported on web');
}

Future<Map<String, dynamic>?> getPlaceDetailsWeb(String placeId) async {
  throw UnsupportedError('getPlaceDetailsWeb is only supported on web');
}
