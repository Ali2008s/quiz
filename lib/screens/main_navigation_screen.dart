import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'local_games_screen.dart';
import 'online_games_screen.dart';
import 'leaderboard_screen.dart';
import 'point_store_screen.dart';
import 'settings_screen.dart';
import '../data/services/point_service.dart';
import '../data/services/audio_service.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const LocalGamesScreen(),
    const OnlineGamesScreen(),
    const LeaderboardScreen(),
  ];

  void _onItemTapped(int index) {
    AudioService.playClick();
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 70,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Points Badge (Store button)
            GestureDetector(
              onTap: () async {
                AudioService.playClick();
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PointStoreScreen()));
                setState(() {}); // Refresh points when returning
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFCC33), width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 5,
                        offset: Offset(0, 3))
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars_rounded,
                        color: Color(0xFFFFCC33), size: 24),
                    const SizedBox(width: 8),
                    FutureBuilder<int>(
                        future: PointService.getPoints(),
                        builder: (context, snapshot) {
                          return Text('${snapshot.data ?? 0}',
                              style: GoogleFonts.lalezar(
                                  fontSize: 18, color: Colors.white));
                        }),
                  ],
                ),
              ),
            ),
            // App Title or Central Text

            // Settings Button (Right side)
            GestureDetector(
              onTap: () {
                AudioService.playClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF81D4FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF1A1A1A),
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.menu,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: SizedBox(
        height: 110,
        child: Center(
          child: Container(
            width: double.infinity,
            height: 85,
            constraints: const BoxConstraints(maxWidth: 500),
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFF1A1A1A), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                backgroundColor: Colors.white,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: const Color(0xFFEF5350),
                unselectedItemColor: const Color(0xFFBDBDBD),
                selectedLabelStyle: GoogleFonts.lalezar(fontSize: 14, height: 1.2),
                unselectedLabelStyle:
                    GoogleFonts.lalezar(fontSize: 12, height: 1.2),
                items: const [
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Icon(Icons.home_rounded, size: 28),
                    ),
                    activeIcon: Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Icon(Icons.home_rounded, size: 32),
                    ),
                    label: 'أوفلاين',
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Icon(Icons.language_rounded, size: 28),
                    ),
                    activeIcon: Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Icon(Icons.language_rounded, size: 32),
                    ),
                    label: 'أونلاين',
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Icon(Icons.emoji_events_rounded, size: 28),
                    ),
                    activeIcon: Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Icon(Icons.emoji_events_rounded, size: 32),
                    ),
                    label: 'الصداره',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
