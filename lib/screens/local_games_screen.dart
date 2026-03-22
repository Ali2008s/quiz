import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/category_card.dart';
import 'setup_players_screen.dart';
import 'not_a_word_setup_screen.dart';

class LocalGamesScreen extends StatelessWidget {
  const LocalGamesScreen({super.key});

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
                                  const SizedBox(width: 8),
                                  const Icon(Icons.mic,
                                      color: Colors.white, size: 20),
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
                          height: 120,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'الألعاب المحلية',
                        style: GoogleFonts.lalezar(
                            fontSize: 28, color: const Color(0xFF1A1A2E)),
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
                        onTap: () => _navigateToSetup(
                            context,
                            'إعترافات',
                            'assets/images/fingerprint.png',
                            const Color(0xFFFFD54F)),
                      ),
                      CategoryCard(
                        title: 'تحدي الأوامر',
                        imagePath: 'assets/images/wheel.png',
                        backgroundColor: const Color(0xFFACE6FE),
                        onTap: () => _navigateToSetup(context, 'تحدي الأوامر',
                            'assets/images/wheel.png', const Color(0xFF81D4FA)),
                      ),
                      CategoryCard(
                        title: 'جاوب خطأ',
                        imagePath: 'assets/images/check_cross.png',
                        backgroundColor: const Color(0xFFF48FB1),
                        onTap: () => _navigateToSetup(
                            context,
                            'جاوب خطأ',
                            'assets/images/check_cross.png',
                            const Color(0xFFF48FB1)),
                      ),
                      CategoryCard(
                        title: 'ولا كلمة',
                        imagePath: 'assets/images/silent.png',
                        backgroundColor: const Color(0xFFA5D6A7),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const NotAWordSetupScreen())),
                      ),
                      CategoryCard(
                        title: 'الجاسوس',
                        imagePath: 'assets/images/spy.png',
                        backgroundColor: const Color(0xFFB39DDB),
                        onTap: () => _navigateToSetup(context, 'الجاسوس',
                            'assets/images/spy.png', const Color(0xFFB39DDB)),
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
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToSetup(
      BuildContext context, String title, String path, Color color) {
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
}
