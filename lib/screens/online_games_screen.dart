import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/category_card.dart';
import 'xo_game_screen.dart';
import 'rps_game_screen.dart';
import 'domino_game_screen.dart';
import 'ludo_online_screen.dart';
import 'player_profile_setup_screen.dart';
import '../data/services/auth_service.dart';
import '../data/services/ad_manager_service.dart';

class OnlineGamesScreen extends StatefulWidget {
  const OnlineGamesScreen({super.key});

  @override
  State<OnlineGamesScreen> createState() => _OnlineGamesScreenState();
}

class _OnlineGamesScreenState extends State<OnlineGamesScreen> {
  String? _userName;
  String? _userAvatar;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final name = await AuthService.getUserName();
    final avatar = await AuthService.getUserAvatar();
    if (mounted) {
      setState(() {
        _userName = name;
        _userAvatar = avatar;
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
      AdManagerService.showInterstitial(onAdClosed: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => screen));
      });
    } else {
      _showRegistrationDialog(context, screen);
    }
  }

  void _showRegistrationDialog(BuildContext context, Widget screen) {
    // استخدام شاشة الملف الشخصي الجديدة الجميلة
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerProfileSetupScreen(
          nextScreen: screen,
          title: 'أهلاً بك في عالم الألعاب! 🎮',
        ),
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
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: const Color(0xFF1A1A1A), width: 2),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 4))
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_userAvatar != null)
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(_userAvatar!),
                              backgroundColor: Colors.grey[200],
                            ),
                          const SizedBox(width: 12),
                          Text('أهلاً بك يا $_userName 👋',
                              style: GoogleFonts.lalezar(
                                  color: const Color(0xFF1A1A2E),
                                  fontSize: 18)),
                        ],
                      ),
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
                  CategoryCard(
                    title: 'حجرة ورقة مقص',
                    imagePath: 'assets/images/rps.png',
                    backgroundColor: const Color(0xFFFFB74D),
                    onTap: () => _checkRegistrationAndNavigate(
                        context, const RPSGameScreen()),
                  ),
                  CategoryCard(
                    title: 'دومينو أونلاين',
                    imagePath: 'assets/images/domino.png',
                    backgroundColor: const Color(0xFFB39DDB),
                    onTap: () => _checkRegistrationAndNavigate(
                        context, const DominoGameScreen()),
                  ),
                  CategoryCard(
                    title: 'لودو أونلاين',
                    imagePath:
                        'assets/images/logo.png', // Temporary until image generation works
                    backgroundColor: const Color(0xFFD4A96A),
                    onTap: () => _checkRegistrationAndNavigate(
                        context, const LudoOnlineScreen()),
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
