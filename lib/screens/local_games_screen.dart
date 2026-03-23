import 'package:flutter/material.dart';
import '../widgets/category_card.dart';
import 'setup_players_screen.dart';
import 'not_a_word_setup_screen.dart';
import 'settings_screen.dart';
import 'name_animal_game_screen.dart';
import 'point_store_screen.dart';
import '../data/services/point_service.dart';
import 'package:google_fonts/google_fonts.dart';

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
                      const SizedBox(height: 20),
                      // Logo
                      Center(
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 150,
                        ),
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
                        title: 'من هو؟',
                        imagePath: 'assets/images/who_is.png',
                        backgroundColor: const Color(0xFFFFB74D),
                        onTap: () => _navigateToSetup(
                            context,
                            'من هو؟',
                            'assets/images/who_is.png',
                            const Color(0xFFFFB74D)),
                      ),
                      CategoryCard(
                        title: 'حرف واسم',
                        imagePath:
                            'assets/images/logo.png', // Temporary until API resets
                        backgroundColor: const Color(0xFFA5D6A7),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const NameAnimalGameScreen())),
                      ),
                      CategoryCard(
                        title: 'كمل المثل',
                        imagePath:
                            'assets/images/logo.png', // Temporary until API resets
                        backgroundColor: const Color(0xFFCE93D8),
                        onTap: () => _navigateToSetup(context, 'كمل المثل',
                            'assets/images/logo.png', const Color(0xFFCE93D8)),
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
