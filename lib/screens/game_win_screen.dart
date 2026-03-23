import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import '../data/services/audio_service.dart';
import '../data/services/ad_manager_service.dart';
import '../widgets/styled_widgets.dart';

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
      backgroundColor: const Color(0xFF1A1A2E),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Background decoration
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset('assets/images/logo.png', repeat: ImageRepeat.repeat, scale: 4),
            ),
          ),
          
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              // Winner Trophy Icon (using icon for now)
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFCC33), width: 4),
                ),
                child: const Icon(Icons.emoji_events_rounded, size: 100, color: Color(0xFFFFCC33)),
              ),
              const SizedBox(height: 30),
              Text(
                'مبروك الفوز!',
                style: GoogleFonts.lalezar(fontSize: 42, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                widget.winnerName,
                textAlign: TextAlign.center,
                style: GoogleFonts.lalezar(fontSize: 32, color: const Color(0xFFFFCC33)),
              ),
              const SizedBox(height: 30),
              // Points earned ticket
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars_rounded, color: Colors.white, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      '+${widget.pointsEarned} نقطة',
                      style: GoogleFonts.lalezar(fontSize: 24, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    StyledNextButton(
                      text: 'إعادة اللعب',
                      onTap: widget.onPlayAgain,
                      color: const Color(0xFFFFCC33),
                    ),
                    const SizedBox(height: 20),
                    StyledNextButton(
                      text: 'الرجوع للقائمة',
                      onTap: widget.onExit,
                      color: const Color(0xFFEF5350),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Confetti!
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2, // down
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
