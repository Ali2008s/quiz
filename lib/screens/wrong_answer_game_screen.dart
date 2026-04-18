import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/styled_widgets.dart';
import '../data/services/ai_service.dart';
import '../data/services/tts_service.dart';
import '../data/services/audio_service.dart';
import '../data/services/point_service.dart';

class WrongAnswerGameScreen extends StatefulWidget {
  final List<String> players;
  const WrongAnswerGameScreen({super.key, required this.players});

  @override
  State<WrongAnswerGameScreen> createState() => _WrongAnswerGameScreenState();
}

enum GameState { wheel, question, results }

class _WrongAnswerGameScreenState extends State<WrongAnswerGameScreen> with TickerProviderStateMixin {
  GameState _state = GameState.wheel;
  late AnimationController _wheelController;
  late Animation<double> _wheelAnimation;
  double _currentRotation = 0;
  String _selectedPlayer = '';
  String _currentQuestion = '';
  String? _nextAIQuestion;
  bool _isLoadingAI = false;
  final Map<String, int> _scores = {};
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    for (var p in widget.players) { _scores[p] = 0; }
    _wheelController = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _wheelAnimation = CurvedAnimation(parent: _wheelController, curve: Curves.fastOutSlowIn);
    _wheelController.addStatusListener((status) {
      if (status == AnimationStatus.completed) _onWheelStop();
    });
    _fetchNextQuestion();
  }

  Future<void> _fetchNextQuestion() async {
    if (_nextAIQuestion != null || _isLoadingAI) return;
    setState(() => _isLoadingAI = true);
    final q = await AIService.getWrongAnswerQuestion();
    if (mounted) {
      setState(() {
        _nextAIQuestion = q;
        _isLoadingAI = false;
      });
    }
  }

  void _spinWheel() {
    if (_wheelController.isAnimating) return;
    AudioService.playClick();
    _fetchNextQuestion();
    setState(() {
      double extraRounds = 4 + _random.nextInt(4).toDouble();
      double targetRotation = _currentRotation + (extraRounds * 2 * pi) + _random.nextDouble() * 2 * pi;
      _wheelAnimation = Tween<double>(begin: _currentRotation, end: targetRotation).animate(CurvedAnimation(parent: _wheelController, curve: Curves.fastOutSlowIn));
      _currentRotation = targetRotation % (2 * pi);
      _wheelController.reset(); _wheelController.forward();
    });
  }

  void _onWheelStop() async {
    double normalizedRotation = (2 * pi - (_currentRotation % (2 * pi))) % (2 * pi);
    double sectionAngle = (2 * pi) / widget.players.length;
    int index = (normalizedRotation / sectionAngle).floor() % widget.players.length;
    
    _selectedPlayer = widget.players[index];
    if (_nextAIQuestion == null) {
      setState(() {
        _currentQuestion = "لحظة، جاري جلب سؤال ذكي...";
        _state = GameState.question;
      });
      await _fetchNextQuestion();
      if (mounted && _nextAIQuestion != null) {
        setState(() {
          _currentQuestion = _nextAIQuestion!;
          _nextAIQuestion = null;
        });
      }
    } else {
      setState(() {
        _currentQuestion = _nextAIQuestion!;
        _nextAIQuestion = null;
        _state = GameState.question;
      });
      TTSService.speak(_currentQuestion);
    }
    _fetchNextQuestion();
  }

  void _showExitDialog() {
    showDialog(context: context, builder: (context) => CustomDialog(
      title: 'هل أنت متأكد؟',
      message: 'هل أنت متأكد أنك تريد الخروج من التحدي؟',
      actions: [
        DialogButton(text: 'نعم', color: const Color(0xFFA5D6A7), onTap: () { Navigator.pop(context); Navigator.popUntil(context, (route) => route.isFirst); }),
        DialogButton(text: 'لا', color: const Color(0xFFEF5350), onTap: () => Navigator.pop(context)),
      ],
    ));
  }

  @override
  void dispose() { _wheelController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return PopScope(canPop: false, onPopInvokedWithResult: (didPop, result) { if (didPop) return; _showExitDialog(); },
      child: Scaffold(backgroundColor: Colors.white, body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          GestureDetector(onTap: _showExitDialog, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFEF5350), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1A1A1A), width: 3)), child: const Icon(Icons.close, color: Colors.white, size: 20))),
        ])),
        const CategoryHeader(title: 'جاوب خطأ', imagePath: 'assets/images/check_cross.png', backgroundColor: Color(0xFFEF9A9A)),
        Expanded(child: SingleChildScrollView(child: _buildMainContent())),
      ])))
    );
  }

  Widget _buildMainContent() {
    switch (_state) {
      case GameState.wheel: return _buildWheelState();
      case GameState.question: return _buildQuestionState();
      case GameState.results: return _buildResultsState();
    }
  }

  Widget _buildWheelState() {
    return Column(children: [
      const SizedBox(height: 30),
      Stack(alignment: Alignment.topCenter, children: [
        AnimatedBuilder(animation: _wheelAnimation, builder: (context, child) {
          return Transform.rotate(angle: _wheelAnimation.value, child: CustomPaint(size: const Size(280, 280), painter: WrongAnswerWheelPainter(players: widget.players)));
        }),
        const Icon(Icons.arrow_drop_down, color: Color(0xFFEF9A9A), size: 48),
      ]),
      const SizedBox(height: 40),
      StyledNextButton(text: 'دوّر العجلة', onTap: _spinWheel),
      const SizedBox(height: 20),
      StyledNextButton(text: 'عرض النتيجة', onTap: () => setState(() => _state = GameState.results), color: const Color(0xFFFFCC33)),
      const SizedBox(height: 20),
    ]);
  }

  Widget _buildQuestionState() {
    return Column(children: [
      const SizedBox(height: 30),
      Container(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10), decoration: BoxDecoration(color: const Color(0xFFFFCC33), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1A1A1A), width: 3)), child: Text(_selectedPlayer, style: GoogleFonts.lalezar(fontSize: 24, color: const Color(0xFF1A1A2E)))),
      const SizedBox(height: 30),
      Container(margin: const EdgeInsets.symmetric(horizontal: 30), padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40), width: double.infinity,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: const Color(0xFFEF9A9A), width: 4)),
        child: Column(children: [
          if (_currentQuestion.startsWith("لحظة")) const Padding(padding: EdgeInsets.only(bottom: 20), child: CircularProgressIndicator(color: Color(0xFFEF9A9A))),
          Text(_currentQuestion, textAlign: TextAlign.center, style: GoogleFonts.lalezar(fontSize: 28, color: const Color(0xFF1A1A2E))),
          const SizedBox(height: 20),

        ])),
      const SizedBox(height: 40),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _actionBtn(Icons.close, const Color(0xFFEF9A9A), () { AudioService.playWrong(); setState(() => _state = GameState.wheel); }),
        const SizedBox(width: 40),
        _actionBtn(Icons.check, const Color(0xFFA5D6A7), () { 
          AudioService.playCorrect(); 
          _scores[_selectedPlayer] = (_scores[_selectedPlayer] ?? 0) + 1; 
          PointService.addPoints(2); // Add 2 points for correct wrong answer!
          setState(() => _state = GameState.wheel); 
        }),
      ]),
      const SizedBox(height: 40),
      StyledNextButton(text: 'عرض النتيجة', onTap: () => setState(() => _state = GameState.results), color: const Color(0xFFFFCC33)),
      const SizedBox(height: 20),
    ]);
  }

  Widget _buildResultsState() {
    var sortedPlayers = widget.players.toList()..sort((a, b) => (_scores[b] ?? 0).compareTo(_scores[a] ?? 0));
    return Column(children: [
      const SizedBox(height: 20),
      ...sortedPlayers.map((p) => Container(margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 8), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), decoration: BoxDecoration(color: const Color(0xFFFFCC33), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1A1A1A), width: 3)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(p, style: GoogleFonts.lalezar(fontSize: 22)), Text('${_scores[p]} نقطة', style: GoogleFonts.lalezar(fontSize: 22))]))).toList(),
      const SizedBox(height: 40),
      StyledNextButton(text: 'كمل اللعبة', onTap: () => setState(() => _state = GameState.wheel)),
      const SizedBox(height: 15),
      StyledNextButton(text: 'إنهاء الجولة', onTap: _showExitDialog, color: const Color(0xFFEF9A9A)),
      const SizedBox(height: 30),
    ]);
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF1A1A1A), width: 3)), child: Icon(icon, color: Colors.white, size: 36)));
  }
}

class WrongAnswerWheelPainter extends CustomPainter {
  final List<String> players;
  final List<Color> colors = [const Color(0xFFFFB74D), const Color(0xFFA5D6A7), const Color(0xFFFFD54F), const Color(0xFF81D4FA), const Color(0xFFF48FB1)];
  WrongAnswerWheelPainter({required this.players});
  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2; final Offset center = Offset(radius, radius); final double arcAngle = (2 * pi) / players.length;
    final Paint paint = Paint()..style = PaintingStyle.fill; final Paint borderPaint = Paint()..color = const Color(0xFF1A1A1A)..style = PaintingStyle.stroke..strokeWidth = 4;
    for (int i = 0; i < players.length; i++) {
      paint.color = colors[i % colors.length];
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), i * arcAngle, arcAngle, true, paint);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), i * arcAngle, arcAngle, true, borderPaint);
      _drawText(canvas, players[i], center, radius, i * arcAngle + arcAngle / 2);
    }
    canvas.drawCircle(center, 15, Paint()..color = Colors.white); canvas.drawCircle(center, 15, borderPaint); canvas.drawCircle(center, radius, borderPaint);
  }
  void _drawText(Canvas canvas, String text, Offset center, double radius, double angle) {
    canvas.save(); canvas.translate(center.dx, center.dy); canvas.rotate(angle);
    final tp = TextPainter(text: TextSpan(text: text, style: GoogleFonts.lalezar(fontSize: 16, color: const Color(0xFF1A1A2E), fontWeight: FontWeight.bold)), textDirection: TextDirection.rtl)..layout();
    tp.paint(canvas, Offset(radius * 0.4, -tp.height / 2)); canvas.restore();
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
