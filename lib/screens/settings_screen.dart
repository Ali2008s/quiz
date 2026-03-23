import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/services/app_settings.dart';
import '../data/services/audio_service.dart';
import '../data/services/tts_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  bool _ttsEnabled = AppSettings.ttsEnabled;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _bounceAnimation = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _toggleTts() async {
    AudioService.playClick();
    final newVal = !_ttsEnabled;
    await AppSettings.setTtsEnabled(newVal);
    if (!newVal) TTSService.stop();
    setState(() => _ttsEnabled = newVal);
    HapticFeedback.lightImpact();
  }

  Future<void> _rateApp() async {
    HapticFeedback.lightImpact();
    AudioService.playClick();
    // Replace with your actual store URL
    const url = 'https://play.google.com/store/apps/details?id=com.yourapp.quiz';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _closeGame() {
    HapticFeedback.heavyImpact();
    AudioService.playClick();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildCloseConfirmDialog(),
    );
  }

  Widget _buildCloseConfirmDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFF1A1A1A), width: 4),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: Offset(0, 8),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'إغلاق اللعبة ؟',
              style: GoogleFonts.lalezar(
                  fontSize: 28, color: const Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 8),
            Text(
              'هل أنت متأكد من الخروج؟',
              style: GoogleFonts.lalezar(fontSize: 18, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _dialogBtn(
                  text: 'إلغاء',
                  color: const Color(0xFFACE6FE),
                  onTap: () => Navigator.pop(context),
                ),
                _dialogBtn(
                  text: 'خروج',
                  color: const Color(0xFFEF5350),
                  onTap: () => SystemNavigator.pop(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogBtn(
      {required String text,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1A1A1A), width: 3),
        ),
        child: Text(
          text,
          style: GoogleFonts.lalezar(
              fontSize: 20, color: const Color(0xFF1A1A2E)),
        ),
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
            // Subtle icon pattern background
            Positioned.fill(
              child: Opacity(
                opacity: 0.03,
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Wrap(
                    spacing: 50,
                    runSpacing: 50,
                    children: List.generate(
                      80,
                      (i) => Icon(
                        [
                          Icons.settings,
                          Icons.star,
                          Icons.volume_up,
                          Icons.close,
                        ][i % 4],
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Column(
              children: [
                // ── Top bar ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button
                      GestureDetector(
                        onTap: () {
                          AudioService.playClick();
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF5350),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: const Color(0xFF1A1A1A), width: 3),
                          ),
                          child: const Icon(Icons.arrow_forward_ios,
                              color: Colors.white, size: 20),
                        ),
                      ),
                      // Empty space right
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // ── Logo ──
                AnimatedBuilder(
                  animation: _bounceAnimation,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(0, _bounceAnimation.value),
                    child: child,
                  ),
                  child: Image.asset('assets/images/logo.png', height: 110),
                ),

                const SizedBox(height: 20),

                // ── Settings Card ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF3DD9EB),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                          color: const Color(0xFF1A1A1A), width: 4),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF1A9AAD),
                          offset: Offset(0, 6),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Card header
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: const Color(0xFF1A1A1A), width: 3),
                          ),
                          child: Text(
                            'الإعدادات',
                            style: GoogleFonts.lalezar(
                              fontSize: 26,
                              color: const Color(0xFF1A1A2E),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ── Rate App button ──
                        _SettingsButton(
                          label: 'تقييم التطبيق',
                          icon: const _StarsIcon(),
                          color: const Color(0xFFFFCC33),
                          shadowColor: const Color(0xFFCC9900),
                          onTap: _rateApp,
                        ),

                        const SizedBox(height: 10),

                        // ── TTS Toggle button ──
                        _SettingsButton(
                          label: _ttsEnabled
                              ? 'إيقاف صوت القراءة'
                              : 'تشغيل صوت القراءة',
                          icon: Icon(
                            _ttsEnabled
                                ? Icons.volume_up_rounded
                                : Icons.volume_off_rounded,
                            size: 30,
                            color: const Color(0xFF1A1A2E),
                          ),
                          color: _ttsEnabled
                              ? const Color(0xFFFFCC33)
                              : const Color(0xFFBDBDBD),
                          shadowColor: _ttsEnabled
                              ? const Color(0xFFCC9900)
                              : const Color(0xFF9E9E9E),
                          onTap: _toggleTts,
                        ),

                        const SizedBox(height: 10),

                        // ── Close Game button (red) ──
                        _SettingsButton(
                          label: 'إغلاق اللعبة',
                          icon: const _SandalsIcon(),
                          color: const Color(0xFFEF5350),
                          shadowColor: const Color(0xFFB71C1C),
                          onTap: _closeGame,
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable styled settings button ────────────────────────────────────────

class _SettingsButton extends StatefulWidget {
  final String label;
  final Widget icon;
  final Color color;
  final Color shadowColor;
  final VoidCallback onTap;

  const _SettingsButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.shadowColor,
    required this.onTap,
  });

  @override
  State<_SettingsButton> createState() => _SettingsButtonState();
}

class _SettingsButtonState extends State<_SettingsButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          transform: Matrix4.translationValues(
              0, _pressed ? 4 : 0, 0),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF1A1A1A), width: 3),
            boxShadow: _pressed
                ? []
                : [
                    BoxShadow(
                      color: widget.shadowColor,
                      offset: const Offset(0, 5),
                      blurRadius: 0,
                    ),
                  ],
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Icon box on the left (RTL = visually right)
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFF1A1A1A), width: 2),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: FittedBox(child: widget.icon),
                    ),
                  ),
                ),
                const Spacer(),
                // Label
                Text(
                  widget.label,
                  style: GoogleFonts.lalezar(
                    fontSize: 24,
                    color: const Color(0xFF1A1A2E),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Custom icon widgets ─────────────────────────────────────────────────────

class _StarsIcon extends StatelessWidget {
  const _StarsIcon();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (i) => const Icon(Icons.star_rounded,
            color: Color(0xFFFF9800), size: 14),
      ),
    );
  }
}

class _SandalsIcon extends StatelessWidget {
  const _SandalsIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.do_not_disturb_on_rounded,
        color: Color(0xFF1A1A2E), size: 28);
  }
}
