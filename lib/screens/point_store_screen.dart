import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/services/point_service.dart';
import '../data/services/audio_service.dart';
import '../data/services/ad_manager_service.dart';
import '../widgets/styled_widgets.dart';

class PointStoreScreen extends StatefulWidget {
  const PointStoreScreen({super.key});

  @override
  State<PointStoreScreen> createState() => _PointStoreScreenState();
}

class _PointStoreScreenState extends State<PointStoreScreen> {
  int _currentPoints = 0;
  DateTime _adFreeUntil = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final points = await PointService.getPoints();
    final adFreeDate = await PointService.getAdFreeUntil();
    if (mounted) {
      setState(() {
        _currentPoints = points;
        _adFreeUntil = adFreeDate;
      });
    }
  }

  Future<void> _buyAdFreeTime(int minutes, int cost) async {
    final success = await PointService.spendPoints(cost);
    if (success) {
      await PointService.buyAdFreeTime(minutes);
      AudioService.playWin();
      _showSuccess('تم الشراء بنجاح! استمتع بوقت بدون إعلانات.');
      _loadState();
    } else {
      AudioService.playWrong();
      _showError('نقاطك غير كافية! إلعب أكثر لتجمع النقاط.');
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
    bool isAdFree = _adFreeUntil.isAfter(DateTime.now());

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
                        border: Border.all(color: const Color(0xFF1A1A1A), width: 3),
                        boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(0, 4))],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 24, color: Color(0xFF1A1A2E)),
                    ),
                  ),
                  Text('متجر مخمخة', style: GoogleFonts.lalezar(fontSize: 28, color: const Color(0xFF1A1A2E))),
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
                boxShadow: const [BoxShadow(color: Color(0xFFE0BB00), offset: Offset(0, 10))],
              ),
              child: Column(
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.stars_rounded, color: Colors.white, size: 40),
                      const SizedBox(width: 10),
                      Text('رصيدك الحالي', style: GoogleFonts.lalezar(fontSize: 22, color: Colors.white)),
                    ],
                  ),
                  Text('$_currentPoints', style: GoogleFonts.lalezar(fontSize: 80, color: Colors.white, height: 1.1)),
                  if (isAdFree) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(15)),
                      child: Text('إعلانات متوقفة حتى: ${_formatTime(_adFreeUntil)}', 
                        style: GoogleFonts.lalezar(fontSize: 14, color: Colors.white)),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _sectionTitle('العروض الخاصة 🎁'),
                  const SizedBox(height: 15),
                  _buildShopItem(
                    title: 'نقاط مجانية 📺',
                    subtitle: 'شاهد إعلان واحصل على 10 نقاط',
                    cost: 0,
                    icon: Icons.play_circle_fill_rounded,
                    color: const Color(0xFFFFCC33),
                    onTap: () {
                      AdManagerService.showRewarded((points) {
                        _showSuccess('مبروك! حصلت على $points نقاط مجانية.');
                        _loadState();
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildShopItem(
                    title: 'عرض ذهبي 🏆',
                    subtitle: 'إعلان سريع بـ 15 نقطة',
                    cost: 0,
                    icon: Icons.bolt_rounded,
                    color: const Color(0xFFFFCC33),
                    onTap: () {
                      AdManagerService.showRewardedInterstitial((points) {
                        _showSuccess('مبروك! حصلت على $points نقاط مجانية (عرض ذهبي).');
                        _loadState();
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildShopItem(
                    title: 'ساعة بدون إعلانات',
                    subtitle: 'إلعب 60 دقيقة بلا انقطاع',
                    cost: 10,
                    icon: Icons.timer_rounded,
                    color: const Color(0xFF81D4FA),
                    onTap: () => _buyAdFreeTime(60, 10),
                  ),
                  _buildShopItem(
                    title: 'يوم كامل بدون إعلانات',
                    subtitle: '24 ساعة من المتعة الصافية',
                    cost: 50,
                    icon: Icons.bolt_rounded,
                    color: const Color(0xFFA5D6A7),
                    onTap: () => _buyAdFreeTime(1440, 50),
                  ),
                  const SizedBox(height: 20),
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
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: GoogleFonts.lalezar(fontSize: 24, color: const Color(0xFF1A1A2E)));
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
        boxShadow: [BoxShadow(color: isLocked ? Colors.grey.shade200 : color.withOpacity(0.2), offset: const Offset(0, 6))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLocked ? null : () {
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
                    color: isLocked ? Colors.grey.shade100 : color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
                  ),
                  child: Icon(icon, color: isLocked ? Colors.grey : color, size: 30),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GoogleFonts.lalezar(fontSize: 18, color: isLocked ? Colors.grey : const Color(0xFF1A1A2E))),
                      Text(subtitle, style: GoogleFonts.lalezar(fontSize: 14, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isLocked ? Colors.grey : const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: Color(0xFFFFCC33), size: 16),
                      const SizedBox(width: 5),
                      Text('$cost', style: GoogleFonts.lalezar(color: Colors.white, fontSize: 16)),
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
