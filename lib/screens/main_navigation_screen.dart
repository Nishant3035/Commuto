import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
import 'find_ride_screen.dart';
import 'offer_ride_screen.dart';
import 'profile_screen.dart';

class MainNavigationController extends InheritedWidget {
  final ValueChanged<int> selectTab;

  const MainNavigationController({
    super.key,
    required this.selectTab,
    required super.child,
  });

  static ValueChanged<int>? maybeSelectTab(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<MainNavigationController>()
        ?.selectTab;
  }

  @override
  bool updateShouldNotify(MainNavigationController oldWidget) {
    return oldWidget.selectTab != selectTab;
  }
}

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      const FindRideScreen(),
      OfferRideScreen(
        showBackButton: false,
        onRidePublished: () => _onItemTapped(0),
      ),
      const ProfileScreen(),
    ];

    return MainNavigationController(
      selectTab: _onItemTapped,
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 8,
            selectedItemColor: const Color(0xFF1D4ED8),
            unselectedItemColor: const Color(0xFF94A3B8),
            selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700),
            unselectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
            items: const [
              BottomNavigationBarItem(
                icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_outlined)),
                activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home)),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.search_outlined)),
                activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.search)),
                label: 'Find',
              ),
              BottomNavigationBarItem(
                icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.add_circle_outline)),
                activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.add_circle)),
                label: 'Offer',
              ),
              BottomNavigationBarItem(
                icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person_outline)),
                activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person)),
                label: 'Profile',
              ),
            ],
          ),
      ),
    );
  }
}
