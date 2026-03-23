import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import '../data/services/audio_service.dart';
import '../data/services/ad_manager_service.dart';

class GameWinScreen extends StatefulWidget {
  final String winnerName;
  final int pointsEarned;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  const GameWinScreen({
    super.key,
    required this.winnerName,
    required this.pointsEarned,
    required this.onPlayAgain,
    required this.onExit,
  });

  @override
  State<GameWinScreen> createState() => _GameWinScreenState();
}

class _GameWinScreenState extends State<GameWinScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
    _confettiController.play();
    AudioService.playWin();
    
    // Show Interstitial Ad when winning (frequency managed inside service or here)
    Future.delayed(const Duration(milliseconds: 500), () {
      AdManagerService.showInterstitial();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background icon pattern (matching LocalGamesScreen)
          Positioned.fill(
            child: IgnorePointer(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Wrap(
                  spacing: 45,
                  runSpacing: 45,
                  children: List.generate(
                    120,
                    (i) => Icon(
                      [
                        Icons.fingerprint,
                        Icons.theater_comedy,
                        Icons.casino,
                        Icons.history_edu,
                        Icons.visibility,
                        Icons.extension_rounded,
                      ][i % 6],
                      size: 35,
                      color: const Color(0xFF1A1A2E).withOpacity(0.05),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Main Win Card (Using the light blue from the app)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFACE6FE),
                        borderRadius: BorderRadius.circular(36),
                        border: Border.all(color: const Color(0xFF1A1A1A), width: 4),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xFF81D4FA),
                            offset: Offset(0, 8),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Trophy Header
                          Transform.translate(
                            offset: const Offset(0, -35),
                            child: Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF1A1A1A), width: 4),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    offset: Offset(0, 6),
                                    blurRadius: 4,
                                  )
                                ],
                              ),
                              child: const Icon(
                                Icons.emoji_events_rounded,
                                size: 80,
                                color: Color(0xFFFFCC33),
                              ),
                            ),
                          ),
                          
                          Transform.translate(
                            offset: const Offset(0, -15),
                            child: Column(
                              children: [
                                Text(
                                  'مبروك الفوز!',
                                  style: GoogleFonts.lalezar(
                                    fontSize: 52,
                                    color: Colors.white,
                                    shadows: [
                                      const Shadow(
                                        color: Color(0xFF1A1A1A),
                                        offset: Offset(3, 3),
                                        blurRadius: 0,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1A2E),
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(color: const Color(0xFFFFCC33), width: 3),
                                  ),
                                  child: Text(
                                    widget.winnerName,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.lalezar(
                                      fontSize: 34,
                                      color: const Color(0xFFFFCC33),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 25),
                          
                          // Points Earned Ticket (Using the green from the app)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 30),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFA5D6A7),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: const Color(0xFF1A1A1A), width: 3),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0xFF2E7D32),
                                  offset: Offset(0, 4),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.stars_rounded, color: Colors.white, size: 36),
                                const SizedBox(width: 14),
                                Text(
                                  '+${widget.pointsEarned} نقطة',
                                  style: GoogleFonts.lalezar(
                                    fontSize: 32,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 35),
                          
                          // Action Buttons
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 25),
                            child: Column(
                              children: [
                                _WinButton(
                                  text: 'إعادة اللعب',
                                  onTap: widget.onPlayAgain,
                                  color: const Color(0xFFFFCC33),
                                  shadowColor: const Color(0xFFCC9900),
                                ),
                                const SizedBox(height: 18),
                                _WinButton(
                                  text: 'الرجوع للقائمة',
                                  onTap: widget.onExit,
                                  color: const Color(0xFFEF5350),
                                  shadowColor: const Color(0xFFB71C1C),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Confetti!
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2,
            maxBlastForce: 5,
            minBlastForce: 2,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.1,
            shouldLoop: false,
            colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.yellow],
          ),
        ],
      ),
    );
  }
}

// ── Internal Button for Win Screen ───────────────────────────────────────────

class _WinButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final Color color;
  final Color shadowColor;

  const _WinButton({
    required this.text,
    required this.onTap,
    required this.color,
    required this.shadowColor,
  });

  @override
  State<_WinButton> createState() => _WinButtonState();
}

class _WinButtonState extends State<_WinButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        AudioService.playClick();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        transform: Matrix4.translationValues(0, _pressed ? 4 : 0, 0),
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
        child: Text(
          widget.text,
          textAlign: TextAlign.center,
          style: GoogleFonts.lalezar(
            fontSize: 28,
            color: const Color(0xFF1A1A2E),
          ),
        ),
      ),
    );
  }
}
