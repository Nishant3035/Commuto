import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LocationPickerScreen extends StatefulWidget {
  final String title; // "Pickup Location" or "Destination"
  final bool showCurrentLocation;

  const LocationPickerScreen({
    super.key,
    required this.title,
    this.showCurrentLocation = false,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<_LocationItem> _filteredLocations = [];
  bool _isSearching = false;

  // Popular locations for suggestions (Mumbai area based on user's examples)
  final List<_LocationItem> _allLocations = [
    _LocationItem('Malad Metro Station', 'Malad West, Mumbai', Icons.train_rounded),
    _LocationItem('Thakur College', 'Kandivali East, Mumbai', Icons.school_rounded),
    _LocationItem('Andheri Station', 'Andheri West, Mumbai', Icons.train_rounded),
    _LocationItem('Borivali Station', 'Borivali West, Mumbai', Icons.train_rounded),
    _LocationItem('Goregaon Station', 'Goregaon West, Mumbai', Icons.train_rounded),
    _LocationItem('Kandivali Station', 'Kandivali West, Mumbai', Icons.train_rounded),
    _LocationItem('Dahisar Metro Station', 'Dahisar, Mumbai', Icons.train_rounded),
    _LocationItem('Thakur Village', 'Kandivali East, Mumbai', Icons.location_city_rounded),
    _LocationItem('Malad West', 'Malad West, Mumbai', Icons.location_on_rounded),
    _LocationItem('Oberoi Mall', 'Goregaon East, Mumbai', Icons.shopping_bag_rounded),
    _LocationItem('Inorbit Mall', 'Malad West, Mumbai', Icons.shopping_bag_rounded),
    _LocationItem('Mindspace', 'Malad West, Mumbai', Icons.business_rounded),
    _LocationItem('Thakur Polytechnic', 'Kandivali East, Mumbai', Icons.school_rounded),
    _LocationItem('D.J. Sanghvi College', 'Vile Parle, Mumbai', Icons.school_rounded),
    _LocationItem('K.J. Somaiya College', 'Vidyavihar, Mumbai', Icons.school_rounded),
    _LocationItem('Mumbai University', 'Kalina, Mumbai', Icons.school_rounded),
    _LocationItem('SPIT College', 'Andheri West, Mumbai', Icons.school_rounded),
    _LocationItem('Dadar Station', 'Dadar, Mumbai', Icons.train_rounded),
    _LocationItem('Bandra Station', 'Bandra West, Mumbai', Icons.train_rounded),
    _LocationItem('Churchgate Station', 'Churchgate, Mumbai', Icons.train_rounded),
    _LocationItem('CST Station', 'Fort, Mumbai', Icons.train_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _filteredLocations = List.from(_allLocations);
  }

  void _filterLocations(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredLocations = List.from(_allLocations);
      } else {
        _filteredLocations = _allLocations
            .where((loc) =>
                loc.name.toLowerCase().contains(query.toLowerCase()) ||
                loc.subtitle.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _selectLocation(_LocationItem location) {
    Navigator.of(context).pop(location.name);
  }

  void _useCurrentLocation() {
    // Simulate detecting current location
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFF2B7DE9),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Detecting location...',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1A1D26),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Simulate delay then return a location
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pop(); // close dialog
      Navigator.of(context).pop('Current Location'); // return result
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              color: const Color(0xFFF5F7FA),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button + title row
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            size: 20,
                            color: Color(0xFF1A1D26),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        widget.title,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1D26),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterLocations,
                      autofocus: true,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1A1D26),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search for a location...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF1A1D26).withValues(alpha: 0.35),
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF2B7DE9),
                          size: 22,
                        ),
                        suffixIcon: _isSearching
                            ? GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  _filterLocations('');
                                },
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Color(0xFF9CA3AF),
                                  size: 20,
                                ),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Current location button (only for pickup)
            if (widget.showCurrentLocation)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: GestureDetector(
                  onTap: _useCurrentLocation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F1FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF2B7DE9).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2B7DE9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.my_location_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Use Current Location',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2B7DE9),
                              ),
                            ),
                            Text(
                              'Detect your location automatically',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF2B7DE9).withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Color(0xFF2B7DE9),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Section label
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: Text(
                _isSearching ? 'Search Results' : 'Popular Locations',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1D26).withValues(alpha: 0.4),
                  letterSpacing: 0.5,
                ),
              ),
            ),

            // Location list
            Expanded(
              child: _filteredLocations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_off_rounded,
                            size: 48,
                            color: const Color(0xFF1A1D26).withValues(alpha: 0.2),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No locations found',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1A1D26).withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _filteredLocations.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: const Color(0xFF1A1D26).withValues(alpha: 0.06),
                      ),
                      itemBuilder: (context, index) {
                        final loc = _filteredLocations[index];
                        return _LocationTile(
                          location: loc,
                          onTap: () => _selectLocation(loc),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  final _LocationItem location;
  final VoidCallback onTap;

  const _LocationTile({required this.location, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                location.icon,
                color: const Color(0xFF1A1D26).withValues(alpha: 0.6),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1D26),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    location.subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF1A1D26).withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFFBFC5CF),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationItem {
  final String name;
  final String subtitle;
  final IconData icon;

  _LocationItem(this.name, this.subtitle, this.icon);
}
