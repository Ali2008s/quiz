import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/category_card.dart';
import 'xo_game_screen.dart';
import 'mheibes_game_screen.dart';
import 'rps_game_screen.dart';
import '../data/services/auth_service.dart';

class OnlineGamesScreen extends StatefulWidget {
  const OnlineGamesScreen({super.key});

  @override
  State<OnlineGamesScreen> createState() => _OnlineGamesScreenState();
}

class _OnlineGamesScreenState extends State<OnlineGamesScreen> {
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final name = await AuthService.getUserName();
    setState(() {
      _userName = name;
    });
  }

  Future<void> _checkRegistrationAndNavigate(
      BuildContext context, Widget screen) async {
    // Retry loading once just in case the plugin was late
    if (_userName == null) {
      final name = await AuthService.getUserName();
      if (name != null) {
        setState(() => _userName = name);
      }
    }

    if (_userName != null && _userName!.isNotEmpty) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
    } else {
      _showRegistrationDialog(context, screen);
    }
  }

  void _showRegistrationDialog(BuildContext context, Widget screen) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        title: Text(
          'أهلاً بك! شنو اسمك؟',
          textAlign: TextAlign.center,
          style:
              GoogleFonts.lalezar(fontSize: 26, color: const Color(0xFF1A1A2E)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars_rounded, size: 60, color: Color(0xFFFFCC33)),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              textAlign: TextAlign.center,
              style: GoogleFonts.lalezar(fontSize: 20),
              decoration: InputDecoration(
                hintText: 'اكتب اسمك هنا...',
                hintStyle: GoogleFonts.lalezar(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide:
                      const BorderSide(color: Color(0xFF1A1A1A), width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide:
                      const BorderSide(color: Color(0xFF1A1A1A), width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide:
                      const BorderSide(color: Color(0xFFEF5350), width: 3),
                ),
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isNotEmpty) {
                    await AuthService.setUserName(nameController.text.trim());
                    setState(() {
                      _userName = nameController.text.trim();
                    });
                    if (context.mounted) Navigator.pop(context);
                    if (context.mounted) {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => screen));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF5350),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Colors.white, width: 2),
                  ),
                  elevation: 5,
                ),
                child: Text(
                  'دخـول',
                  style: GoogleFonts.lalezar(fontSize: 22, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.03,
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Wrap(
                    spacing: 40,
                    runSpacing: 40,
                    children: List.generate(
                      100,
                      (index) => Icon(
                        [
                          Icons.wifi,
                          Icons.language,
                          Icons.public,
                          Icons.games,
                          Icons.sports_esports,
                        ][index % 5],
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF5350),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF1A1A1A),
                                  width: 3,
                                ),
                              ),
                              child: const Icon(Icons.menu,
                                  color: Colors.white, size: 28),
                            ),
                            if (_userName != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFA5D6A7),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: const Color(0xFF1A1A1A), width: 2),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      _userName!,
                                      style: GoogleFonts.lalezar(
                                          fontSize: 14,
                                          color: const Color(0xFF1A1A2E)),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.person,
                                        color: Colors.white, size: 20),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Center(
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 120,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'ألعاب أونلاين',
                        style: GoogleFonts.lalezar(
                            fontSize: 28, color: const Color(0xFFEF5350)),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid.count(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    children: [
                      CategoryCard(
                          title: 'حجرة ورقة مقص',
                          imagePath: 'assets/images/logo.png',
                          backgroundColor: const Color(0xFF81C784),
                          onTap: () => _checkRegistrationAndNavigate(
                              context, const RPSGameScreen())),
                      CategoryCard(
                          title: 'XO',
                          imagePath: 'assets/images/logo.png',
                          backgroundColor: const Color(0xFF64B5F6),
                          onTap: () => _checkRegistrationAndNavigate(
                              context, const XOGameScreen())),
                    ],
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
