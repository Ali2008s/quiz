import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/styled_widgets.dart';
import '../data/game_data.dart';

class NotAWordGameScreen extends StatefulWidget {
  final int rounds;
  final int timePerRound;
  final String team1Name;
  final String team2Name;
  final List<String> categories;

  const NotAWordGameScreen({
    super.key, 
    required this.rounds, 
    required this.timePerRound,
    required this.team1Name,
    required this.team2Name,
    required this.categories,
  });

  @override
  State<NotAWordGameScreen> createState() => _NotAWordGameScreenState();
}

enum GameState { setup, playing, gameOver }

class _NotAWordGameScreenState extends State<NotAWordGameScreen> {
  GameState _state = GameState.setup;
  int _currentRound = 1;
  int _currentTeam = 1; // 1 or 2
  int _score1 = 0;
  int _score2 = 0;
  int _timeLeft = 0;
  Timer? _timer;
  String _currentPhrase = '';
  final List<String> _usedPhrases = [];
  late List<String> _availablePhrases;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.timePerRound;
    _initializePhrases();
  }

  void _initializePhrases() {
    _availablePhrases = [];
    final allPhrases = GameData.questions['ولا كلمة'] as Map<String, List<String>>;
    for (var cat in widget.categories) {
       if (allPhrases.containsKey(cat)) {
          _availablePhrases.addAll(allPhrases[cat]!);
       }
    }
    if (_availablePhrases.isEmpty) {
       _availablePhrases = ['لا توجد كلمات متاحة'];
    }
  }

  void _startRound() {
    setState(() {
      _state = GameState.playing;
      _timeLeft = widget.timePerRound;
      _nextPhrase();
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _endTurn();
      }
    });
  }

  void _nextPhrase() {
    List<String> unused = _availablePhrases.where((p) => !_usedPhrases.contains(p)).toList();
    
    if (unused.isEmpty) {
      _usedPhrases.clear();
      unused = List.from(_availablePhrases);
    }

    setState(() {
      _currentPhrase = unused[_random.nextInt(unused.length)];
      _usedPhrases.add(_currentPhrase);
    });
  }

  void _endTurn() {
    _timer?.cancel();
    setState(() {
      if (_currentTeam == 1) {
        _currentTeam = 2;
        _state = GameState.setup;
      } else {
        if (_currentRound < widget.rounds) {
          _currentRound++;
          _currentTeam = 1;
          _state = GameState.setup;
        } else {
          _state = GameState.gameOver;
        }
      }
    });
  }

  void _addPoint() {
    setState(() {
      if (_currentTeam == 1) _score1++;
      else _score2++;
      _nextPhrase();
    });
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: 'هل أنت متأكد؟',
        message: 'هل أنت متأكد أنك تريد الخروج من اللعبة؟',
        actions: [
          DialogButton(
            text: 'نعم',
            color: const Color(0xFFA5D6A7),
            onTap: () {
              _timer?.cancel();
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
                title: 'ولا كلمة',
                imagePath: 'assets/images/silent.png',
                backgroundColor: Color(0xFFA5D6A7),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_state == GameState.setup) return _buildSetupState();
    if (_state == GameState.playing) return _buildPlayingState();
    return _buildGameOverState();
  }

  Widget _buildSetupState() {
    String currentTeamName = _currentTeam == 1 ? widget.team1Name : widget.team2Name;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 50),
        Text(
          'الجولة $_currentRound',
          style: GoogleFonts.lalezar(fontSize: 48, color: const Color(0xFF1A1A2E)),
        ),
        const SizedBox(height: 20),
        Text(
          'دور فريق: $currentTeamName',
          style: GoogleFonts.lalezar(fontSize: 32, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 50),
        StyledNextButton(text: 'ابدأ الآن', onTap: _startRound),
      ],
    );
  }

  Widget _buildPlayingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer, color: Color(0xFFEF5350), size: 30),
            const SizedBox(width: 10),
            Text(
              '$_timeLeft',
              style: GoogleFonts.lalezar(fontSize: 48, color: const Color(0xFFEF5350)),
            ),
          ],
        ),
        const SizedBox(height: 30),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 30),
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFA5D6A7), width: 4),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Text(
            _currentPhrase,
            textAlign: TextAlign.center,
            style: GoogleFonts.lalezar(fontSize: 36, color: const Color(0xFF1A1A2E)),
          ),
        ),
        const SizedBox(height: 40),
        Row(
           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
           children: [
             _actionBtn(Icons.skip_next, const Color(0xFF81D4FA), _nextPhrase),
             _actionBtn(Icons.add, const Color(0xFFA5D6A7), _addPoint),
           ],
        ),
      ],
    );
  }

  Widget _buildGameOverState() {
    String winner = _score1 > _score2 ? widget.team1Name : (_score1 < _score2 ? widget.team2Name : 'تعادل!');
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 30),
        Text('انتهت اللعبة!', style: GoogleFonts.lalezar(fontSize: 48, color: const Color(0xFF1A1A2E))),
        const SizedBox(height: 20),
        Text('الفائز: $winner', style: GoogleFonts.lalezar(fontSize: 36, color: const Color(0xFFA5D6A7))),
        const SizedBox(height: 40),
        _scoreRow(widget.team1Name, _score1, const Color(0xFF81D4FA)),
        _scoreRow(widget.team2Name, _score2, const Color(0xFFF48FB1)),
        const SizedBox(height: 50),
        StyledNextButton(text: 'الرئيسية', onTap: () => Navigator.popUntil(context, (route) => route.isFirst)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _scoreRow(String label, int score, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1A1A1A), width: 3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.lalezar(fontSize: 24)),
          Text('$score', style: GoogleFonts.lalezar(fontSize: 24)),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF1A1A2E), width: 3),
        ),
        child: Icon(icon, color: Colors.white, size: 36),
      ),
    );
  }
}
