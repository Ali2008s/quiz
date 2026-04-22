import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/category_card.dart';
import 'xo_game_screen.dart';
import 'rps_game_screen.dart';
import 'domino_game_screen.dart';
import 'ludo_online_screen.dart';
import '../data/services/auth_service.dart';
import '../data/services/audio_service.dart';
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
    final TextEditingController nameController = TextEditingController();
    String selectedAvatar = AuthService.availableAvatars[0];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          title: Text(
            'أهلاً بك! شنو اسمك؟',
            textAlign: TextAlign.center,
            style: GoogleFonts.lalezar(fontSize: 26, color: const Color(0xFF1A1A2E)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                      borderSide: const BorderSide(color: Color(0xFF1A1A1A), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('اختر صورتك الشخصية:',
                    style: GoogleFonts.lalezar(fontSize: 18, color: Colors.black87)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 100,
                  width: 300,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: AuthService.availableAvatars.length,
                    itemBuilder: (context, index) {
                      final avatar = AuthService.availableAvatars[index];
                      final isSelected = selectedAvatar == avatar;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedAvatar = avatar),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: isSelected ? const Color(0xFFEF5350) : Colors.transparent,
                                width: 3),
                          ),
                          child: CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: NetworkImage(avatar),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isNotEmpty) {
                    AudioService.playClick();
                    await AuthService.setUserName(nameController.text);
                    await AuthService.setUserAvatar(selectedAvatar);
                    setState(() {
                      _userName = nameController.text;
                      _userAvatar = selectedAvatar;
                    });
                    Navigator.pop(context);
                    AdManagerService.showInterstitial(onAdClosed: () {
                      Navigator.push(
                          context, MaterialPageRoute(builder: (context) => screen));
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF5350),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: Text('حفظ ودخول', style: GoogleFonts.lalezar(color: Colors.white, fontSize: 18)),
              ),
            ),
            const SizedBox(height: 10),
          ],
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
                        border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
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
                                  color: const Color(0xFF1A1A2E), fontSize: 18)),
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
                    imagePath: 'assets/images/logo.png', // Temporary until image generation works
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
