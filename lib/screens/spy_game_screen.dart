import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/styled_widgets.dart';
import '../data/services/ai_service.dart';
import '../data/services/tts_service.dart';
import '../data/services/audio_service.dart';

class SpyGameScreen extends StatefulWidget {
  final List<String> players;
  final int timeLimitSeconds;

  const SpyGameScreen({super.key, required this.players, this.timeLimitSeconds = 60});

  @override
  State<SpyGameScreen> createState() => _SpyGameScreenState();
}

enum SpyState { loading, viewing, discussing, paused, revealed }

class _SpyGameScreenState extends State<SpyGameScreen> {
  SpyState _state = SpyState.loading;
  int _currentPlayerIndex = 0;
  String _currentPlace = '';
  late int _spyIndex;
  bool _isWordVisible = false;
  final Random _random = Random();
  int _timeLeft = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.timeLimitSeconds;
    _resetGame();
  }

  Future<void> _resetGame() async {
    setState(() {
      _state = SpyState.loading;
      _timer?.cancel();
    });
    
    final place = await AIService.getSpyTopic();
    if (mounted) {
      setState(() {
        _currentPlace = place ?? "سوق الشورجة"; 
        _spyIndex = _random.nextInt(widget.players.length);
        _currentPlayerIndex = 0;
        _isWordVisible = false;
        _timeLeft = widget.timeLimitSeconds;
        _state = SpyState.viewing;
      });
    }
  }

  void _nextPlayer() {
    setState(() {
      if (_currentPlayerIndex < widget.players.length - 1) {
        _currentPlayerIndex++;
        _isWordVisible = false;
      } else {
        _state = SpyState.discussing;
        if (widget.timeLimitSeconds > 0) _startTimer();
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) setState(() => _timeLeft--);
      else {
        _timer?.cancel();
        setState(() => _state = SpyState.revealed);
      }
    });
  }

  void _pauseTimer() { _timer?.cancel(); setState(() => _state = SpyState.paused); }
  void _resumeTimer() { setState(() => _state = SpyState.discussing); _startTimer(); }

  void _showExitDialog() {
    _timer?.cancel();
    showDialog(context: context, builder: (context) => CustomDialog(
      title: 'هل أنت متأكد؟',
      message: 'هل أنت متأكد أنك تريد الخروج من التحدي؟',
      actions: [
        DialogButton(text: 'نعم', color: const Color(0xFFA5D6A7), onTap: () { Navigator.pop(context); Navigator.popUntil(context, (route) => route.isFirst); }),
        DialogButton(text: 'لا', color: const Color(0xFFEF5350), onTap: () { Navigator.pop(context); if (_state == SpyState.discussing) _startTimer(); }),
      ],
    ));
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return PopScope(canPop: false, onPopInvokedWithResult: (didPop, result) { if (didPop) return; _showExitDialog(); },
      child: Scaffold(backgroundColor: Colors.white, body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          GestureDetector(onTap: _showExitDialog, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFEF5350), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1A1A1A), width: 3)), child: const Icon(Icons.close, color: Colors.white, size: 20))),
        ])),
        const CategoryHeader(title: 'الجاسوس', imagePath: 'assets/images/spy.png', backgroundColor: Color(0xFFB39DDB)),
        Expanded(child: SingleChildScrollView(child: _state == SpyState.loading ? const Center(child: CircularProgressIndicator()) : _buildMainContent())),
      ])))
    );
  }

  Widget _buildMainContent() {
    switch (_state) {
      case SpyState.viewing: return _buildViewingState();
      case SpyState.discussing: return _buildDiscussingState();
      case SpyState.paused: return _buildPausedState();
      case SpyState.revealed: return _buildRevealedState();
      default: return const SizedBox();
    }
  }

  Widget _buildViewingState() {
    String name = widget.players[_currentPlayerIndex];
    bool isSpy = _currentPlayerIndex == _spyIndex;
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const SizedBox(height: 30),
        Text('لاعب: $name', style: GoogleFonts.lalezar(fontSize: 28, color: const Color(0xFF1A1A2E))),
        const SizedBox(height: 20),
        SwipeToRevealCard(
          key: ValueKey(_currentPlayerIndex),
          frontCard: _buildRoleCard(name),
          revealedContent: _buildRevealedWord(isSpy, _currentPlace),
          onRevealed: () {
            setState(() => _isWordVisible = true);
            TTSService.speak(isSpy ? 'أنت الجاسوس' : _currentPlace);
          },
        ),
        const SizedBox(height: 30),
        if (_isWordVisible)
          StyledNextButton(text: 'التالي', onTap: _nextPlayer),
        const SizedBox(height: 20),
    ]);
  }

  Widget _buildRevealedWord(bool isSpy, String place) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(isSpy ? 'أنت هو:\n الجاسوس 🕵️‍♂️' : 'المكان هو:\n $place', textAlign: TextAlign.center, style: GoogleFonts.lalezar(fontSize: 34, color: const Color(0xFF1A1A2E))),
        const SizedBox(height: 20),

      ],
    );
  }

  Widget _buildDiscussingState() {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const SizedBox(height: 50),
      _buildCircularTimer(),
      const SizedBox(height: 60),
      StyledNextButton(text: 'إيقاف مؤقت', onTap: _pauseTimer, color: const Color(0xFFEF9A9A)),
      const SizedBox(height: 20),
    ]);
  }

  Widget _buildPausedState() {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const SizedBox(height: 50),
      _buildCircularTimer(),
      const SizedBox(height: 60),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        DialogButton(text: 'إنهاء اللعبة', color: const Color(0xFFEF9A9A), onTap: _showExitDialog),
        DialogButton(text: 'متابعة اللعب', color: const Color(0xFFA5D6A7), onTap: _resumeTimer),
      ]),
      const SizedBox(height: 20),
    ]);
  }

  Widget _buildRevealedState() {
    String spyName = widget.players[_spyIndex];
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const SizedBox(height: 30),
      _buildRoleCard(spyName, isResult: true),
      const SizedBox(height: 20),
      Text('الجاسوس كان:\n $spyName', textAlign: TextAlign.center, style: GoogleFonts.lalezar(fontSize: 32, color: const Color(0xFF1A1A2E))),
      const SizedBox(height: 40),
      StyledNextButton(text: 'إعادة اللعب', onTap: _resetGame),
      const SizedBox(height: 20),
    ]);
  }

  Widget _buildRoleCard(String playerName, {bool isResult = false}) {
    return Container(margin: const EdgeInsets.symmetric(horizontal: 40), width: double.infinity, height: 260, decoration: BoxDecoration(color: const Color(0xFF5C6BC0), borderRadius: BorderRadius.circular(32), border: Border.all(color: const Color(0xFF1A1A1A), width: 4), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 10))]),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Image.asset('assets/images/spy.png', height: 90),
        const SizedBox(height: 15),
        if (!isResult) ...[
           Text('إسحب للأعلى\nلكشف دورك', textAlign: TextAlign.center, style: GoogleFonts.lalezar(fontSize: 32, color: const Color(0xFF69F0AE), height: 1.2)),
           const SizedBox(height: 15),
           const Icon(Icons.keyboard_double_arrow_up_rounded, size: 48, color: Color(0xFF03A9F4)),
        ]
      ]));
  }

  Widget _buildCircularTimer() {
    double progress = widget.timeLimitSeconds > 0 ? _timeLeft / widget.timeLimitSeconds : 1.0;
    int minutes = _timeLeft ~/ 60; int seconds = _timeLeft % 60; String timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    return SizedBox(width: 200, height: 200, child: Stack(alignment: Alignment.center, children: [CustomPaint(size: const Size(200, 200), painter: TimerPainter(progress: progress)), Text(timeStr, style: GoogleFonts.lalezar(fontSize: 48, color: const Color(0xFF1A1A2E)))]));
  }
}

class TimerPainter extends CustomPainter {
  final double progress;
  TimerPainter({required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2; final Offset center = Offset(radius, radius); final Rect rect = Rect.fromCircle(center: center, radius: radius);
    final Paint activePaint = Paint()..color = const Color(0xFFEF9A9A)..style = PaintingStyle.stroke..strokeWidth = 10..strokeCap = StrokeCap.round;
    final Paint segmentPaint = Paint()..color = const Color(0xFFA5D6A7)..style = PaintingStyle.stroke..strokeWidth = 10;
    const int segments = 60;
    for (int i = 0; i < segments; i++) { double angle = (2 * pi / segments) * i - pi / 2; canvas.drawArc(rect, angle + 0.02, (2 * pi / segments) - 0.04, false, segmentPaint); }
    if (progress < 1.0) { double sweepAngle = -2 * pi * (1 - progress); canvas.drawArc(rect, -pi / 2, sweepAngle, false, activePaint); }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SwipeToRevealCard extends StatefulWidget {
  final Widget frontCard;
  final Widget revealedContent;
  final VoidCallback onRevealed;

  const SwipeToRevealCard({
    super.key,
    required this.frontCard,
    required this.revealedContent,
    required this.onRevealed,
  });

  @override
  State<SwipeToRevealCard> createState() => _SwipeToRevealCardState();
}

class _SwipeToRevealCardState extends State<SwipeToRevealCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragOffset = 0;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_revealed) return;
    setState(() {
      _dragOffset += details.primaryDelta!;
      if (_dragOffset > 0) _dragOffset = 0; // Only swipe up
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_revealed) return;
    // If swiped enough, reveal the word FOREVER but SNAP BACK the card
    if (_dragOffset < -150 || details.primaryVelocity! < -800) {
      _revealed = true;
      widget.onRevealed();
    }
    // Always snap back the card to the bottom
    setState(() => _dragOffset = 0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The front card (Draggable)
        GestureDetector(
          onVerticalDragUpdate: _onPanUpdate,
          onVerticalDragEnd: _onPanEnd,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            transform: Matrix4.translationValues(0, _dragOffset, 0),
            child: widget.frontCard,
          ),
        ),
        // The revealed content is BELOW the card and only takes space when revealed
        if (_revealed)
          FadeInUp(
            duration: const Duration(milliseconds: 400),
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: widget.revealedContent,
            ),
          ),
      ],
    );
  }
}

class FadeInUp extends StatefulWidget {
  final Widget child;
  final Duration duration;
  const FadeInUp({super.key, required this.child, required this.duration});
  @override
  State<FadeInUp> createState() => _FadeInUpState();
}

class _FadeInUpState extends State<FadeInUp> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _offsetAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacityAnimation, child: SlideTransition(position: _offsetAnimation, child: widget.child));
  }
}
