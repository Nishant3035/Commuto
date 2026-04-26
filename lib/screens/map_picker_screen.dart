import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/places_service.dart';
import '../services/location_service.dart';

class MapPickerScreen extends StatefulWidget {
  final String title;
  final LatLng? initialLocation;

  const MapPickerScreen({
    super.key,
    this.title = 'Select Location',
    this.initialLocation,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;
  LatLng _selectedLocation = LocationService.defaultLocation;
  String _selectedAddress = 'Tap on map or search to select';
  bool _isLoadingAddress = false;
  bool _isSearching = false;
  bool _showSearchResults = false;
  List<Map<String, dynamic>> _searchResults = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation!;
      _reverseGeocode(_selectedLocation);
    } else {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    PlacesService.cancelPendingSearch();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    final result = await LocationService.getCurrentLocationWithFallback();
    if (!mounted) return;

    setState(() {
      _selectedLocation = result.location;
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(result.location, result.isActual ? 16 : 12),
    );

    if (!result.isActual) {
      // Show fallback notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Location unavailable. Showing Mumbai as default.',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    _reverseGeocode(result.location);
  }

  Future<void> _reverseGeocode(LatLng location) async {
    setState(() => _isLoadingAddress = true);
    final address = await PlacesService.reverseGeocode(
      location.latitude,
      location.longitude,
    );
    if (mounted) {
      setState(() {
        _selectedAddress = address ?? 'Selected location';
        _isLoadingAddress = false;
      });
    }
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedLocation = position;
      _showSearchResults = false;
    });
    _reverseGeocode(position);
  }

  void _onSearchChanged(String query) {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    PlacesService.searchDebounced(
      query,
      biasLocation: _selectedLocation,
      onResults: (results) {
        if (mounted) {
          setState(() {
            _searchResults = results;
            _showSearchResults = results.isNotEmpty;
            _isSearching = false;
          });
        }
      },
    );
  }

  Future<void> _selectSearchResult(Map<String, dynamic> result) async {
    final placeId = result['place_id'] as String? ?? '';
    if (placeId.isEmpty) return;

    setState(() {
      _isSearching = true;
      _showSearchResults = false;
      _searchController.clear();
    });

    FocusScope.of(context).unfocus();

    final detail = await PlacesService.getPlaceDetails(placeId);
    if (detail != null && mounted) {
      final lat = detail['lat'] as double;
      final lng = detail['lng'] as double;
      final name = detail['name'] as String? ?? '';
      final address = detail['address'] as String? ?? '';

      setState(() {
        _selectedLocation = LatLng(lat, lng);
        _selectedAddress = name.isNotEmpty ? '$name, $address' : address;
        _isSearching = false;
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(lat, lng), 17),
      );
    } else {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load place details',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _confirmSelection() {
    Navigator.pop(context, {
      'name': _selectedAddress,
      'lat': _selectedLocation.latitude,
      'lng': _selectedLocation.longitude,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: 14,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onTap: _onMapTap,
            markers: {
              Marker(
                markerId: const MarkerId('selected'),
                position: _selectedLocation,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure),
              ),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Top bar — Search + Back
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Color(0xFF0F172A)),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search for places, shops, landmarks...',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      if (_isSearching)
                        const Padding(
                          padding: EdgeInsets.only(right: 16),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        )
                      else if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear,
                              color: Color(0xFF94A3B8), size: 20),
                          onPressed: () {
                            _searchController.clear();
                            PlacesService.cancelPendingSearch();
                            setState(() {
                              _searchResults = [];
                              _showSearchResults = false;
                            });
                          },
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.only(right: 16),
                          child: Icon(Icons.search,
                              color: Color(0xFF94A3B8), size: 22),
                        ),
                    ],
                  ),
                ),

                // Search Results Dropdown
                if (_showSearchResults && _searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 320),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 1,
                          color: Color(0xFFF1F5F9),
                        ),
                        itemBuilder: (context, index) {
                          final result = _searchResults[index];
                          return ListTile(
                            dense: true,
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.location_on_outlined,
                                color: Color(0xFF2563EB),
                                size: 18,
                              ),
                            ),
                            title: Text(
                              result['main_text'] ?? result['description'] ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              result['secondary_text'] ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _selectSearchResult(result),
                          );
                        },
                      ),
                    ),
                  ),

                // No results state
                if (_showSearchResults == false &&
                    _searchController.text.length >= 2 &&
                    !_isSearching &&
                    _searchResults.isEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_off,
                            color: Color(0xFF94A3B8), size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'No places found. Try a different search.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // My Location FAB
          Positioned(
            right: 16,
            bottom: 200,
            child: FloatingActionButton.small(
              heroTag: 'my_location',
              onPressed: _getCurrentLocation,
              backgroundColor: Colors.white,
              elevation: 4,
              child: const Icon(Icons.my_location,
                  color: Color(0xFF2563EB), size: 22),
            ),
          ),

          // Bottom Confirmation Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).padding.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
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
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.place,
                            color: Colors.white, size: 22),
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
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            _isLoadingAddress
                                ? Row(
                                    children: [
                                      const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Getting address...',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    _selectedAddress,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
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
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoadingAddress ? null : _confirmSelection,
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
                      child: Text(
                        'Confirm Location',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
