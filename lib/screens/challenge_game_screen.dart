import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/styled_widgets.dart';
import '../data/services/ai_service.dart';
import '../data/services/tts_service.dart';
import '../data/services/audio_service.dart';

class ChallengeGameScreen extends StatefulWidget {
  final String title;
  final List<String> players;
  final Color backgroundColor;
  final String imagePath;
  final String heroTag;

  const ChallengeGameScreen({
    super.key,
    required this.title,
    required this.players,
    required this.backgroundColor,
    required this.imagePath,
    required this.heroTag,
  });

  @override
  State<ChallengeGameScreen> createState() => _ChallengeGameScreenState();
}

enum GameState { wheel, task }

class _ChallengeGameScreenState extends State<ChallengeGameScreen> with TickerProviderStateMixin {
  GameState _state = GameState.wheel;
  late AnimationController _wheelController;
  late Animation<double> _wheelAnimation;
  double _currentRotation = 0;
  String _selectedPlayer = '';
  String _currentTask = '';
  String? _nextAITask;
  bool _isLoadingAI = false;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _wheelController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _wheelAnimation = CurvedAnimation(
      parent: _wheelController,
      curve: Curves.fastOutSlowIn,
    );

    _wheelController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onWheelStop();
      }
    });

    _fetchNextTask(); // initial fetch
  }

  Future<void> _fetchNextTask() async {
    if (_nextAITask != null || _isLoadingAI) return;
    setState(() => _isLoadingAI = true);
    final task = await AIService.getChallenge();
    if (mounted) {
      setState(() {
        _nextAITask = task;
        _isLoadingAI = false;
      });
    }
  }

  void _spinWheel() {
    if (_wheelController.isAnimating) return;
    AudioService.playClick();
    _fetchNextTask();
    
    setState(() {
      double extraRounds = 4 + _random.nextInt(4).toDouble();
      double targetRotation = _currentRotation + (extraRounds * 2 * pi) + _random.nextDouble() * 2 * pi;
      _wheelAnimation = Tween<double>(begin: _currentRotation, end: targetRotation).animate(
        CurvedAnimation(parent: _wheelController, curve: Curves.fastOutSlowIn),
      );
      _currentRotation = targetRotation % (2 * pi);
      _wheelController.reset();
      _wheelController.forward();
    });
  }

  void _onWheelStop() async {
    double normalizedRotation = (2 * pi - (_currentRotation % (2 * pi))) % (2 * pi);
    double sectionAngle = (2 * pi) / widget.players.length;
    int index = (normalizedRotation / sectionAngle).floor() % widget.players.length;
    
    // If AI task isn't ready, wait a bit or use a fallback (not needed if we fetch early)
    if (_nextAITask == null) {
      setState(() {
        _selectedPlayer = widget.players[index];
        _currentTask = "لحظة، جاري جلب تحدي ذكي...";
        _state = GameState.task;
      });
      // Try fetching again to be safe
      await _fetchNextTask();
      if (mounted && _nextAITask != null) {
        setState(() {
          _currentTask = _nextAITask!;
          _nextAITask = null;
        });
      }
    } else {
      setState(() {
        _selectedPlayer = widget.players[index];
        _currentTask = _nextAITask!;
        _nextAITask = null;
        _state = GameState.task;
      });
      TTSService.speak(_currentTask);
    }
    // Pre-fetch for next round
    _fetchNextTask();
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: 'هل أنت متأكد؟',
        message: 'هل أنت متأكد أنك تريد الخروج من التحدي؟',
        actions: [
          DialogButton(
            text: 'نعم',
            color: const Color(0xFFA5D6A7),
            onTap: () {
              Navigator.pop(context); 
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
          DialogButton(
            text: 'لا',
            color: const Color(0xFFEF5350),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _wheelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitDialog();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: _showExitDialog,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF5350),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF1A1A1A), width: 3),
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              CategoryHeader(
                title: widget.title,
                imagePath: widget.imagePath.replaceAll('_icon', ''),
                backgroundColor: widget.backgroundColor,
                heroTag: widget.heroTag,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: _state == GameState.wheel ? _buildWheelState() : _buildTaskState(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWheelState() {
    return Column(
      children: [
        const SizedBox(height: 30),
        Stack(
          alignment: Alignment.topCenter,
          children: [
            AnimatedBuilder(
              animation: _wheelAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _wheelAnimation.value,
                  child: CustomPaint(
                    size: const Size(280, 280),
                    painter: SimpleWheelPainter(players: widget.players),
                  ),
                );
              },
            ),
            Transform.translate(
              offset: const Offset(0, -10),
              child: Icon(Icons.arrow_drop_down, color: widget.backgroundColor, size: 48),
            ),
          ],
        ),
        const SizedBox(height: 50),
        StyledNextButton(text: 'دوّر العجلة', onTap: _spinWheel),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTaskState() {
    return Column(
      children: [
        const SizedBox(height: 30),
        Stack(
          alignment: Alignment.topCenter,
          children: [
             Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD54F),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1A1A1A), width: 3),
              ),
              child: Text(
                _selectedPlayer,
                style: GoogleFonts.lalezar(fontSize: 24, color: const Color(0xFF1A1A2E)),
              ),
            ),
            Container(
              width: 12, height: 12,
              decoration: BoxDecoration(color: const Color(0xFF1A1A1A), shape: BoxShape.circle, border: Border.all(color: const Color(0xFFFFD54F), width: 2)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 30),
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFF1A1A2E).withOpacity(0.8), width: 4),
          ),
          child: Column(
            children: [
              if (_currentTask.startsWith("لحظة")) 
                const Padding(padding: EdgeInsets.only(bottom: 20), child: CircularProgressIndicator(color: Color(0xFF1A1A2E))),
              Text(
                _currentTask,
                textAlign: TextAlign.center,
                style: GoogleFonts.lalezar(fontSize: 28, color: const Color(0xFF1A1A2E)),
              ),
              const SizedBox(height: 20),
              if (!_currentTask.startsWith("لحظة"))
                GestureDetector(
                  onTap: () => TTSService.speak(_currentTask),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD54F),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
                    ),
                    child: const Icon(Icons.volume_up_rounded, color: Color(0xFF1A1A2E), size: 30),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 50),
        StyledNextButton(
          text: 'التالي',
          onTap: () => setState(() => _state = GameState.wheel),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class SimpleWheelPainter extends CustomPainter {
  final List<String> players;
  final List<Color> colors = [
    const Color(0xFFFFB74D),
    const Color(0xFFA5D6A7),
    const Color(0xFFFFD54F),
    const Color(0xFF81D4FA),
    const Color(0xFFF48FB1),
  ];

  SimpleWheelPainter({required this.players});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    final double arcAngle = (2 * pi) / players.length;
    final Paint paint = Paint()..style = PaintingStyle.fill;
    final Paint borderPaint = Paint()..color = const Color(0xFF1A1A1A)..style = PaintingStyle.stroke..strokeWidth = 4;
    for (int i = 0; i < players.length; i++) {
      paint.color = colors[i % colors.length];
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), i * arcAngle, arcAngle, true, paint);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), i * arcAngle, arcAngle, true, borderPaint);
      _drawText(canvas, players[i], center, radius, i * arcAngle + arcAngle / 2);
    }
    canvas.drawCircle(center, 15, Paint()..color = Colors.white);
    canvas.drawCircle(center, 15, borderPaint);
    canvas.drawCircle(center, radius, borderPaint);
  }

  void _drawText(Canvas canvas, String text, Offset center, double radius, double angle) {
    canvas.save(); canvas.translate(center.dx, center.dy); canvas.rotate(angle);
    final tp = TextPainter(text: TextSpan(text: text, style: GoogleFonts.lalezar(fontSize: 14, color: const Color(0xFF1A1A2E), fontWeight: FontWeight.bold)), textDirection: TextDirection.rtl)..layout();
    tp.paint(canvas, Offset(radius * 0.4, -tp.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
