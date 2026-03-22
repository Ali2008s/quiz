import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/category_card.dart';
import 'setup_players_screen.dart';
import 'not_a_word_setup_screen.dart';
import 'xo_game_screen.dart';
import 'mheibes_game_screen.dart';
import 'rps_game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Subdued icon pattern background
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
                          Icons.fingerprint,
                          Icons.theater_comedy,
                          Icons.casino,
                          Icons.history_edu,
                          Icons.visibility,
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
                      // Custom Header
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
                            // Voice Status indicator
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFA5D6A7),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'المايك متاح',
                                    style: GoogleFonts.lalezar(fontSize: 14, color: const Color(0xFF1A1A2E)),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.mic, color: Colors.white, size: 20),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Logo
                      Center(
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 150,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'الألعاب المحلية',
                        style: GoogleFonts.lalezar(fontSize: 28, color: const Color(0xFF1A1A2E)),
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
                        title: 'إعترافات',
                        imagePath: 'assets/images/fingerprint.png',
                        backgroundColor: const Color(0xFFFFCC33),
                        onTap: () => _navigateToSetup(context, 'إعترافات', 'assets/images/fingerprint.png', const Color(0xFFFFD54F)),
                      ),
                      CategoryCard(
                        title: 'تحدي الأوامر',
                        imagePath: 'assets/images/wheel.png',
                        backgroundColor: const Color(0xFFACE6FE),
                        onTap: () => _navigateToSetup(context, 'تحدي الأوامر', 'assets/images/wheel.png', const Color(0xFF81D4FA)),
                      ),
                      CategoryCard(
                        title: 'جاوب خطأ',
                        imagePath: 'assets/images/check_cross.png',
                        backgroundColor: const Color(0xFFF48FB1),
                        onTap: () => _navigateToSetup(context, 'جاوب خطأ', 'assets/images/check_cross.png', const Color(0xFFF48FB1)),
                      ),
                      CategoryCard(
                        title: 'ولا كلمة',
                        imagePath: 'assets/images/silent.png',
                        backgroundColor: const Color(0xFFA5D6A7),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotAWordSetupScreen())),
                      ),
                      CategoryCard(
                        title: 'الجاسوس',
                        imagePath: 'assets/images/spy.png',
                        backgroundColor: const Color(0xFFB39DDB),
                        onTap: () => _navigateToSetup(context, 'الجاسوس', 'assets/images/spy.png', const Color(0xFFB39DDB)),
                      ),
                      CategoryCard(
                        title: 'قريباً',
                        imagePath: 'assets/images/logo.png',
                        backgroundColor: Colors.white,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'ألعاب أونلاين',
                        style: GoogleFonts.lalezar(fontSize: 28, color: const Color(0xFFEF5350)),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid.count(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    children: [
                      CategoryCard(
                        title: 'محيبس',
                        imagePath: 'assets/images/logo.png',
                        backgroundColor: const Color(0xFFFFB74D),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MheibesGameScreen())),
                      ),
                      CategoryCard(
                        title: 'حجرة ورقة مقص',
                        imagePath: 'assets/images/logo.png',
                        backgroundColor: const Color(0xFF81C784),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RPSGameScreen())),
                      ),
                      CategoryCard(
                        title: 'XO',
                        imagePath: 'assets/images/logo.png',
                        backgroundColor: const Color(0xFF64B5F6),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const XOGameScreen())),
                      ),
                      CategoryCard(
                        title: 'دومينو',
                        imagePath: 'assets/images/logo.png',
                        backgroundColor: const Color(0xFFBA68C8),
                        onTap: () => _showOnlineComingSoon(context, 'دومينو'),
                      ),
                      CategoryCard(
                        title: 'لودو',
                        imagePath: 'assets/images/logo.png',
                        backgroundColor: const Color(0xFFFF8A65),
                        onTap: () => _showOnlineComingSoon(context, 'لودو'),
                      ),
                    ],
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 50)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToSetup(BuildContext context, String title, String path, Color color) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SetupPlayersScreen(
          title: title,
          imagePath: path,
          backgroundColor: color,
        ),
      ),
    );
  }

  void _showOnlineComingSoon(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF1A1A1A), width: 3)),
        title: Text(title, style: GoogleFonts.lalezar(fontSize: 24), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mic, size: 50, color: Color(0xFFEF5350)),
            const SizedBox(height: 20),
            Text(
              'واجهة اللعبة قيد التجهيز!\nستدعم الأونلاين والمايك قريباً.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lalezar(fontSize: 18),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('حسناً', style: GoogleFonts.lalezar(fontSize: 18, color: const Color(0xFF81D4FA))),
          ),
        ],
      ),
    );
  }
}
