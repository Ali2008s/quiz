import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/styled_widgets.dart';
import '../data/game_data.dart';

class ConfessionsGameScreen extends StatefulWidget {
  final List<String> players;

  const ConfessionsGameScreen({super.key, required this.players});

  @override
  State<ConfessionsGameScreen> createState() => _ConfessionsGameScreenState();
}

enum GameState { wheel, question, fingerprint }

class _ConfessionsGameScreenState extends State<ConfessionsGameScreen> with TickerProviderStateMixin {
  GameState _state = GameState.wheel;
  late AnimationController _wheelController;
  late Animation<double> _wheelAnimation;
  double _currentRotation = 0;
  String _selectedPlayer = '';
  String _currentQuestion = '';
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _wheelController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
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
  }

  void _spinWheel() {
    if (_wheelController.isAnimating) return;

    setState(() {
      double extraRounds = 5 + _random.nextInt(5).toDouble();
      double targetRotation = _currentRotation + (extraRounds * 2 * pi) + _random.nextDouble() * 2 * pi;
      
      _wheelAnimation = Tween<double>(
        begin: _currentRotation,
        end: targetRotation,
      ).animate(CurvedAnimation(
        parent: _wheelController,
        curve: Curves.fastOutSlowIn,
      ));
      
      _currentRotation = targetRotation % (2 * pi);
      _wheelController.reset();
      _wheelController.forward();
    });
  }

  void _onWheelStop() {
    double normalizedRotation = (2 * pi - (_currentRotation % (2 * pi))) % (2 * pi);
    double sectionAngle = (2 * pi) / widget.players.length;
    int index = (normalizedRotation / sectionAngle).floor() % widget.players.length;
    
    setState(() {
      _selectedPlayer = widget.players[index];
      _currentQuestion = GameData.questions['إعترافات']![_random.nextInt(GameData.questions['إعترافات']!.length)];
      _state = GameState.question;
    });
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
              Navigator.pop(context); // Close dialog
              Navigator.popUntil(context, (route) => route.isFirst); // Go to Home
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
              // Header
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
              
              const CategoryHeader(
                title: 'إعترافات', 
                imagePath: 'assets/images/fingerprint.png',
                backgroundColor: Color(0xFFFFD54F),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  child: _buildMainContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_state) {
      case GameState.wheel:
        return _buildWheelState();
      case GameState.question:
        return _buildQuestionState();
      case GameState.fingerprint:
        return _buildFingerprintState();
    }
  }

  Widget _buildWheelState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
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
                    size: const Size(300, 300),
                    painter: WheelPainter(players: widget.players),
                  ),
                );
              },
            ),
            // The needle pointing down
            Transform.translate(
              offset: const Offset(0, -10), 
              child: const Icon(Icons.location_on, color: Color(0xFFEF5350), size: 40),
            ),
          ],
        ),
        const SizedBox(height: 40),
        StyledNextButton(text: 'دوّر العجلة', onTap: _spinWheel),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildQuestionState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Container(
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
        const SizedBox(height: 30),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 30),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF1A1A1A), width: 4),
          ),
          child: Text(
            _currentQuestion,
            textAlign: TextAlign.center,
            style: GoogleFonts.lalezar(fontSize: 28, color: const Color(0xFF1A1A2E)),
          ),
        ),
        const SizedBox(height: 50),
        StyledNextButton(
          text: 'صح أم خطأ؟',
          onTap: () => setState(() => _state = GameState.fingerprint),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildFingerprintState() {
    bool isTrue = _random.nextBool();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Text(
          'كاشف الحقيقة',
          style: GoogleFonts.lalezar(fontSize: 32, color: const Color(0xFF1A1A2E)),
        ),
        const SizedBox(height: 40),
        GestureDetector(
          onLongPressStart: (_) {
            // Animation/Haptic feedback simulation
          },
          onLongPressEnd: (_) {
            showDialog(
              context: context,
              builder: (context) => CustomDialog(
                title: isTrue ? 'صادق! ✅' : 'كاذب! ❌',
                message: isTrue ? 'هذا اللاعب يقول الحقيقة' : 'هذا اللاعب يحتاج أن يكون أكثر صراحة!',
                actions: [
                  DialogButton(
                    text: 'موافق',
                    color: isTrue ? const Color(0xFFA5D6A7) : const Color(0xFFEF5350),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _state = GameState.wheel);
                    },
                  ),
                ],
              ),
            );
          },
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF1A1A1A), width: 3),
                ),
                child: Image.asset('assets/images/fingerprint.png', height: 120),
              ),
              const SizedBox(height: 20),
              Text(
                'ضع إصبعك',
                style: GoogleFonts.lalezar(fontSize: 24, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}

class WheelPainter extends CustomPainter {
  final List<String> players;
  final List<Color> colors = [
    const Color(0xFFFFB74D),
    const Color(0xFFA5D6A7),
    const Color(0xFFFFD54F),
    const Color(0xFF81D4FA),
    const Color(0xFFF48FB1),
  ];

  WheelPainter({required this.players});

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
      
      // Draw Player Names
      _drawText(canvas, players[i], center, radius, i * arcAngle + arcAngle / 2);
    }

    // Inner circle decoration
    canvas.drawCircle(center, 20, Paint()..color = Colors.white);
    canvas.drawCircle(center, 20, borderPaint);
    
    // Outer border
    canvas.drawCircle(center, radius, borderPaint);
  }

  void _drawText(Canvas canvas, String text, Offset center, double radius, double angle) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.lalezar(fontSize: 18, color: const Color(0xFF1A1A2E), fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.rtl,
    )..layout();

    textPainter.paint(canvas, Offset(radius * 0.4, -textPainter.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
