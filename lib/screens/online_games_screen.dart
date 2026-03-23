import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/category_card.dart';
import 'xo_game_screen.dart';
import 'rps_game_screen.dart';
import 'domino_game_screen.dart';
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
    if (mounted) {
      setState(() {
        _userName = name;
      });
    }
  }

  Future<void> _checkRegistrationAndNavigate(
      BuildContext context, Widget screen) async {
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
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  await AuthService.setUserName(nameController.text);
                  setState(() => _userName = nameController.text);
                  Navigator.pop(context);
                  Navigator.push(
                      context, MaterialPageRoute(builder: (context) => screen));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF5350),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              child: Text('حفظ ودخول',
                  style: GoogleFonts.lalezar(color: Colors.white)),
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
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  if (_userName != null)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA5D6A7).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0xFFA5D6A7)),
                      ),
                      child: Text('أهلاً بك يا $_userName 👋',
                          style: GoogleFonts.lalezar(
                              color: const Color(0xFF2E7D32), fontSize: 18)),
                    ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset('assets/images/logo.png', height: 150),
                  ),
                  const SizedBox(height: 10),
                  const SizedBox(height: 20),
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
                    title: 'XO أونلاين',
                    imagePath: 'assets/images/xo.png',
                    backgroundColor: const Color(0xFF81D4FA),
                    onTap: () => _checkRegistrationAndNavigate(
                        context, const XOGameScreen()),
                  ),
                  // CategoryCard(
                  //   title: 'محيبس أونلاين',
                  //   imagePath: 'assets/images/mheibes.png',
                  //   backgroundColor: const Color(0xFFA5D6A7),
                  //   onTap: () => _checkRegistrationAndNavigate(
                  //       context, const MheibesGameScreen()),
                  // ),
                  CategoryCard(
                    title: 'حجرة ورقة مقص',
                    imagePath: 'assets/images/rps.png',
                    backgroundColor: const Color(0xFFFFB74D),
                    onTap: () => _checkRegistrationAndNavigate(
                        context, const RPSGameScreen()),
                  ),
                  CategoryCard(
                    title: 'دومينو أونلاين',
                    imagePath: 'assets/images/logo.png', // Changed from domino.png
                    backgroundColor: const Color(0xFFB39DDB),
                    onTap: () => _checkRegistrationAndNavigate(
                        context, const DominoGameScreen()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
