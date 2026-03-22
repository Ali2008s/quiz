import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/styled_widgets.dart';
import '../data/game_data.dart';

class SpyGameScreen extends StatefulWidget {
  final List<String> players;
  final int timeLimitSeconds;

  const SpyGameScreen({
    super.key, 
    required this.players,
    this.timeLimitSeconds = 60,
  });

  @override
  State<SpyGameScreen> createState() => _SpyGameScreenState();
}

enum SpyState { viewing, discussing, paused, revealed }

class _SpyGameScreenState extends State<SpyGameScreen> {
  SpyState _state = SpyState.viewing;
  int _currentPlayerIndex = 0;
  late String _currentPlace;
  late int _spyIndex;
  bool _isWordVisible = false;
  final Random _random = Random();
  
  // Timer related
  int _timeLeft = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.timeLimitSeconds;
    _resetGame();
  }

  void _resetGame() {
    setState(() {
      _currentPlace = GameData.questions['الجاسوس']![_random.nextInt(GameData.questions['الجاسوس']!.length)];
      if (_currentPlace.contains('(')) {
        _currentPlace = _currentPlace.substring(_currentPlace.indexOf('(') + 1, _currentPlace.indexOf(')'));
      }
      _spyIndex = _random.nextInt(widget.players.length);
      _currentPlayerIndex = 0;
      _state = SpyState.viewing;
      _isWordVisible = false;
      _timeLeft = widget.timeLimitSeconds;
      _timer?.cancel();
    });
  }

  void _nextPlayer() {
    setState(() {
      if (_currentPlayerIndex < widget.players.length - 1) {
        _currentPlayerIndex++;
        _isWordVisible = false;
      } else {
        _state = SpyState.discussing;
        if (widget.timeLimitSeconds > 0) {
          _startTimer();
        }
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _timer?.cancel();
        setState(() => _state = SpyState.revealed);
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _state = SpyState.paused);
  }

  void _resumeTimer() {
    setState(() => _state = SpyState.discussing);
    _startTimer();
  }

  void _showExitDialog() {
    _timer?.cancel();
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
            onTap: () {
              Navigator.pop(context);
              if (_state == SpyState.discussing) _startTimer();
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
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
              const CategoryHeader(
                title: 'الجاسوس',
                imagePath: 'assets/images/spy.png',
                backgroundColor: Color(0xFFB39DDB),
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
      case SpyState.viewing: return _buildViewingState();
      case SpyState.discussing: return _buildDiscussingState();
      case SpyState.paused: return _buildPausedState();
      case SpyState.revealed: return _buildRevealedState();
    }
  }

  Widget _buildViewingState() {
    String name = widget.players[_currentPlayerIndex];
    bool isSpy = _currentPlayerIndex == _spyIndex;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 30),
        _buildRoleCard(onSwipeUp: () => setState(() => _isWordVisible = true)),
        const SizedBox(height: 20),
        if (_isWordVisible) ...[
          Text(
            isSpy ? 'المحتال هو:\n $name' : 'المكان هو:\n $_currentPlace',
            textAlign: TextAlign.center,
            style: GoogleFonts.lalezar(fontSize: 28, color: const Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 20),
          StyledNextButton(text: 'التالي', onTap: _nextPlayer),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _buildDiscussingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 50),
        _buildCircularTimer(),
        const SizedBox(height: 60),
        StyledNextButton(text: 'إيقاف مؤقت', onTap: _pauseTimer, color: const Color(0xFFEF9A9A)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPausedState() {
     return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 50),
        _buildCircularTimer(),
        const SizedBox(height: 60),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
             DialogButton(text: 'إنهاء اللعبة', color: const Color(0xFFEF9A9A), onTap: _showExitDialog),
             DialogButton(text: 'متابعة اللعب', color: const Color(0xFFA5D6A7), onTap: _resumeTimer),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildRevealedState() {
    String spyName = widget.players[_spyIndex];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 30),
        _buildRoleCard(),
        const SizedBox(height: 20),
        Text(
          'المحتال هو:\n $spyName',
          textAlign: TextAlign.center,
          style: GoogleFonts.lalezar(fontSize: 32, color: const Color(0xFF1A1A2E)),
        ),
        const SizedBox(height: 40),
        StyledNextButton(text: 'إعادة اللعب', onTap: _resetGame),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildRoleCard({VoidCallback? onSwipeUp}) {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (onSwipeUp != null && details.primaryVelocity != null && details.primaryVelocity! < -300) {
           onSwipeUp();
        }
      },
      // Fallback for mouse/click systems if dragging is difficult
      onTap: onSwipeUp,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(
          color: const Color(0xFF5C6BC0),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/spy.png', height: 100),
            const SizedBox(height: 10),
            Text(
              'للكشف\nعن الجاسوس',
              textAlign: TextAlign.center,
              style: GoogleFonts.lalezar(fontSize: 38, color: const Color(0xFF69F0AE), height: 1.1),
            ),
            const SizedBox(height: 10),
            Text(
              'إسحب للأعلى أو اضغط', // Updated hint
              style: GoogleFonts.lalezar(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 5),
            const Icon(Icons.arrow_upward, size: 36, color: Color(0xFF03A9F4)),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularTimer() {
    double progress = widget.timeLimitSeconds > 0 ? _timeLeft / widget.timeLimitSeconds : 1.0;
    int minutes = _timeLeft ~/ 60;
    int seconds = _timeLeft % 60;
    String timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(200, 200),
            painter: TimerPainter(progress: progress),
          ),
          Text(
            timeStr,
            style: GoogleFonts.lalezar(fontSize: 48, color: const Color(0xFF1A1A2E)),
          ),
        ],
      ),
    );
  }
}

class TimerPainter extends CustomPainter {
  final double progress;

  TimerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    
    final Paint activePaint = Paint()
      ..color = const Color(0xFFEF9A9A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final Paint segmentPaint = Paint()
      ..color = const Color(0xFFA5D6A7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    const int segments = 60;
    for (int i = 0; i < segments; i++) {
       double angle = (2 * pi / segments) * i - pi / 2;
       canvas.drawArc(rect, angle + 0.02, (2 * pi / segments) - 0.04, false, segmentPaint);
    }

    if (progress < 1.0) {
       double sweepAngle = -2 * pi * (1 - progress);
       canvas.drawArc(rect, -pi / 2, sweepAngle, false, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
