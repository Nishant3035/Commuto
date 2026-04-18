import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class MapPickerScreen extends StatefulWidget {
  final String title;
  final bool showCurrentLocation;
  final LatLng? initialPosition;

  const MapPickerScreen({
    super.key,
    required this.title,
    this.showCurrentLocation = false,
    this.initialPosition,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  LatLng _selectedPosition = const LatLng(19.1990, 72.8577); // Malad, Mumbai default
  String _selectedAddress = 'Tap on the map to select location';
  bool _isLoadingAddress = false;
  bool _isGettingCurrentLocation = false;

  final TextEditingController _searchController = TextEditingController();
  List<_SearchResult> _searchResults = [];
  bool _showSearchResults = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.initialPosition != null) {
      _selectedPosition = widget.initialPosition!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _onMapTap(LatLng position) async {
    setState(() {
      _selectedPosition = position;
      _isLoadingAddress = true;
      _showSearchResults = false;
    });
    await _reverseGeocode(position);
  }

  Future<void> _reverseGeocode(LatLng position) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&addressdetails=1',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'Commuto-App/1.0',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final displayName = data['display_name'] as String? ?? 'Unknown location';
        // Shorten the address
        final parts = displayName.split(',');
        final shortAddress = parts.take(3).join(',').trim();
        setState(() {
          _selectedAddress = shortAddress;
          _isLoadingAddress = false;
        });
      } else {
        setState(() {
          _selectedAddress = 'Location selected';
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      setState(() {
        _selectedAddress = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        _isLoadingAddress = false;
      });
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.length < 3) {
      setState(() => _showSearchResults = false);
      return;
    }

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=$query,Mumbai,India&limit=5',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'Commuto-App/1.0',
      });

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          _searchResults = data.map((item) {
            final displayName = item['display_name'] as String;
            final parts = displayName.split(',');
            return _SearchResult(
              name: parts.take(2).join(',').trim(),
              fullAddress: parts.take(4).join(',').trim(),
              lat: double.parse(item['lat']),
              lon: double.parse(item['lon']),
            );
          }).toList();
          _showSearchResults = _searchResults.isNotEmpty;
        });
      }
    } catch (e) {
      // Silently fail on search errors
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchPlaces(query);
    });
  }

  Future<void> _goToCurrentLocation() async {
    setState(() => _isGettingCurrentLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please enable location services',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
              backgroundColor: const Color(0xFFE53E3E),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        setState(() => _isGettingCurrentLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isGettingCurrentLocation = false);
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedPosition = latLng;
        _isGettingCurrentLocation = false;
      });

      final controller = await _mapController.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
      await _reverseGeocode(latLng);
    } catch (e) {
      setState(() => _isGettingCurrentLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get location',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            backgroundColor: const Color(0xFFE53E3E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _selectSearchResult(_SearchResult result) async {
    final latLng = LatLng(result.lat, result.lon);
    setState(() {
      _selectedPosition = latLng;
      _selectedAddress = result.fullAddress;
      _showSearchResults = false;
      _searchController.clear();
    });

    final controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
  }

  void _confirmLocation() {
    Navigator.of(context).pop(LocationResult(
      address: _selectedAddress,
      latLng: _selectedPosition,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedPosition,
              zoom: 14,
            ),
            onMapCreated: (controller) {
              _mapController.complete(controller);
            },
            onTap: _onMapTap,
            markers: {
              Marker(
                markerId: const MarkerId('selected'),
                position: _selectedPosition,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  widget.title.contains('Pickup')
                      ? BitmapDescriptor.hueGreen
                      : BitmapDescriptor.hueRed,
                ),
              ),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Top bar with search
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Back + Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Back button
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Padding(
                            padding: EdgeInsets.all(14),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              size: 22,
                              color: Color(0xFF1A1D26),
                            ),
                          ),
                        ),
                        // Search field
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search ${widget.title.toLowerCase()}...',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF1A1D26).withValues(alpha: 0.35),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _showSearchResults = false);
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(14),
                              child: Icon(Icons.close_rounded, size: 20, color: Color(0xFF9CA3AF)),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Search results dropdown
                  if (_showSearchResults)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _searchResults.map((result) {
                          return InkWell(
                            onTap: () => _selectSearchResult(result),
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 20, color: Color(0xFF2B7DE9)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          result.name,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF1A1D26),
                                          ),
                                        ),
                                        Text(
                                          result.fullAddress,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: const Color(0xFF1A1D26).withValues(alpha: 0.45),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Current location FAB
          if (widget.showCurrentLocation)
            Positioned(
              right: 16,
              bottom: 200,
              child: GestureDetector(
                onTap: _isGettingCurrentLocation ? null : _goToCurrentLocation,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: _isGettingCurrentLocation
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF2B7DE9),
                          ),
                        )
                      : const Icon(
                          Icons.my_location_rounded,
                          color: Color(0xFF2B7DE9),
                          size: 22,
                        ),
                ),
              ),
            ),

          // Bottom card with selected location + confirm
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location info row
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: widget.title.contains('Pickup')
                              ? const Color(0xFFE6F4EA)
                              : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.title.contains('Pickup')
                              ? Icons.radio_button_checked_rounded
                              : Icons.location_on_rounded,
                          color: widget.title.contains('Pickup')
                              ? const Color(0xFF34A853)
                              : const Color(0xFFE53E3E),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF1A1D26).withValues(alpha: 0.4),
                              ),
                            ),
                            const SizedBox(height: 3),
                            _isLoadingAddress
                                ? Row(
                                    children: [
                                      const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF2B7DE9),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Getting address...',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: const Color(0xFF1A1D26).withValues(alpha: 0.4),
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    _selectedAddress,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1A1D26),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _selectedAddress != 'Tap on the map to select location'
                          ? _confirmLocation
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2B7DE9),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFE0E5EC),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Confirm Location'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResult {
  final String name;
  final String fullAddress;
  final double lat;
  final double lon;

  _SearchResult({
    required this.name,
    required this.fullAddress,
    required this.lat,
    required this.lon,
  });
}

class LocationResult {
  final String address;
  final LatLng latLng;

  LocationResult({required this.address, required this.latLng});
}
