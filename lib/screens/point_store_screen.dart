import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/services/point_service.dart';
import '../data/services/audio_service.dart';
import '../data/services/ad_manager_service.dart';
import '../widgets/banner_ad_widget.dart';

class PointStoreScreen extends StatefulWidget {
  const PointStoreScreen({super.key});

  @override
  State<PointStoreScreen> createState() => _PointStoreScreenState();
}

class _PointStoreScreenState extends State<PointStoreScreen> {
  int _currentPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final points = await PointService.getPoints();
    if (mounted) {
      setState(() {
        _currentPoints = points;
      });
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.lalezar()),
      backgroundColor: const Color(0xFFA5D6A7),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    ));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.lalezar()),
      backgroundColor: const Color(0xFFEF5350),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header (matching category style)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      AudioService.playClick();
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFF1A1A1A), width: 3),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, offset: Offset(0, 4))
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 24, color: Color(0xFF1A1A2E)),
                    ),
                  ),
                  Text('متجر مخمخة',
                      style: GoogleFonts.lalezar(
                          fontSize: 28, color: const Color(0xFF1A1A2E))),
                  const SizedBox(width: 48), // Balancing
                ],
              ),
            ),

            // Points Card (Giant and Bold)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: const EdgeInsets.all(30),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFFFCC33),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFF1A1A1A), width: 4),
                boxShadow: const [
                  BoxShadow(color: Color(0xFFE0BB00), offset: Offset(0, 10))
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.stars_rounded,
                          color: Colors.white, size: 40),
                      const SizedBox(width: 10),
                      Text('رصيدك الحالي',
                          style: GoogleFonts.lalezar(
                              fontSize: 22, color: Colors.white)),
                    ],
                  ),
                  Text('$_currentPoints',
                      style: GoogleFonts.lalezar(
                          fontSize: 80, color: Colors.white, height: 1.1)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const SizedBox(height: 20),

                  // ── قسم كسب النقاط ────────────────────────────────────
                  _sectionTitle('🎁 كسب نقاط'),
                  const SizedBox(height: 15),

                  // ── نقاط مجانية ──
                  _buildAdRewardItem(
                    title: 'نقاط مجانية 🎁',
                    subtitle: 'شاهد إعلاناً قصيراً واكسب 10 نقاط مجاناً',
                    icon: Icons.card_giftcard_rounded,
                    color: const Color(0xFF4CAF50),
                    onTap: () {
                      AdManagerService.showRewarded((points) {
                        _loadState();
                        _showSuccess('🎉 حصلت على $points نقطة مجانية!');
                      });
                    },
                  ),

                  // ── العرض الذهبي ──
                  _buildAdRewardItem(
                    title: 'العرض الذهبي ⭐',
                    subtitle: 'شاهد إعلاناً واحداً واكسب 15 نقطة دفعة واحدة',
                    icon: Icons.workspace_premium_rounded,
                    color: const Color(0xFFFF9800),
                    onTap: () {
                      AdManagerService.showRewardedInterstitial((points) {
                        _loadState();
                        _showSuccess('⭐ حصلت على $points نقطة ذهبية!');
                      });
                    },
                  ),

                  const SizedBox(height: 10),
                  _sectionTitle('قريباً... 🔒'),
                  const SizedBox(height: 15),
                  _buildShopItem(
                    title: 'تغيير لون الثيم',
                    subtitle: 'خصص ألوان اللعبة ذوقك',
                    cost: 200,
                    icon: Icons.palette_rounded,
                    color: Colors.grey.shade400,
                    onTap: () {},
                    isLocked: true,
                  ),
                ],
              ),
            ),

            // ── بانر إعلاني ────────────────────────────────────────
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style:
            GoogleFonts.lalezar(fontSize: 24, color: const Color(0xFF1A1A2E)));
  }

  Widget _buildAdRewardItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1A1A1A), width: 3),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.25), offset: const Offset(0, 6))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            AudioService.playClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(15),
                    border:
                        Border.all(color: const Color(0xFF1A1A1A), width: 2),
                  ),
                  child: Icon(icon, color: color, size: 30),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: GoogleFonts.lalezar(
                              fontSize: 17, color: const Color(0xFF1A1A2E))),
                      Text(subtitle,
                          style: GoogleFonts.lalezar(
                              fontSize: 13, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: const Color(0xFF1A1A1A), width: 2),
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShopItem({
    required String title,
    required String subtitle,
    required int cost,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isLocked = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1A1A1A), width: 3),
        boxShadow: [
          BoxShadow(
              color: isLocked ? Colors.grey.shade200 : color.withOpacity(0.2),
              offset: const Offset(0, 6))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLocked
              ? null
              : () {
                  AudioService.playClick();
                  onTap();
                },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isLocked
                        ? Colors.grey.shade100
                        : color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                    border:
                        Border.all(color: const Color(0xFF1A1A1A), width: 2),
                  ),
                  child: Icon(icon,
                      color: isLocked ? Colors.grey : color, size: 30),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: GoogleFonts.lalezar(
                              fontSize: 18,
                              color: isLocked
                                  ? Colors.grey
                                  : const Color(0xFF1A1A2E))),
                      Text(subtitle,
                          style: GoogleFonts.lalezar(
                              fontSize: 14, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isLocked ? Colors.grey : const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: const Color(0xFF1A1A1A), width: 2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars_rounded,
                          color: Color(0xFFFFCC33), size: 16),
                      const SizedBox(width: 5),
                      Text('$cost',
                          style: GoogleFonts.lalezar(
                              color: Colors.white, fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
