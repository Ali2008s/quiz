import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/styled_widgets.dart';
import 'confessions_game_screen.dart';
import 'challenge_game_screen.dart';
import 'spy_game_screen.dart';
import 'wrong_answer_game_screen.dart';
import 'who_is_game_screen.dart';
import 'proverb_game_screen.dart';

class SetupPlayersScreen extends StatefulWidget {
  final String title;
  final String imagePath;
  final Color backgroundColor;

  const SetupPlayersScreen({
    super.key,
    required this.title,
    required this.imagePath,
    required this.backgroundColor,
  });

  @override
  State<SetupPlayersScreen> createState() => _SetupPlayersScreenState();
}

class _SetupPlayersScreenState extends State<SetupPlayersScreen> {
  final List<TextEditingController> _controllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  int _setupPhase = 0; // 0: Players, 1: Time (Spy only)
  int _spyTimeLimit = 60;
  bool _hasTimeLimit = true;

  void _addPlayer() {
    setState(() {
      _controllers.add(TextEditingController());
    });
  }

  void _removePlayer(int index) {
    if (_controllers.length > 2) {
      setState(() {
        _controllers[index].dispose();
        _controllers.removeAt(index);
      });
    }
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
              Navigator.pop(context); // Exit screen
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

  void _onNextPressed() {
    if (_setupPhase == 0) {
      bool hasEmptyNames = _controllers.any((c) => c.text.trim().isEmpty);
      if (hasEmptyNames) {
        showDialog(
          context: context,
          builder: (context) => CustomDialog(
            title: 'خطأ',
            message: 'يجب إدخال أسماء جميع اللاعبين للمتابعة!',
            actions: [
              DialogButton(
                text: 'إغلاق',
                color: const Color(0xFFEF5350),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      } else {
        if (widget.title == 'الجاسوس') {
          setState(() {
            _setupPhase = 1;
          });
        } else {
          _proceedToGame();
        }
      }
    } else {
      _proceedToGame();
    }
  }

  void _proceedToGame() {
    List<String> names = _controllers.map((c) => c.text.trim()).toList();
    Widget gameScreen;
    
    if (widget.title == 'إعترافات') {
      gameScreen = ConfessionsGameScreen(players: names);
    } else if (widget.title == 'تحدي الأوامر') {
      gameScreen = ChallengeGameScreen(
        title: widget.title,
        players: names,
        backgroundColor: widget.backgroundColor,
        imagePath: widget.imagePath,
        heroTag: 'hero_game_challenge',
      );
    } else if (widget.title == 'جاوب خطأ') {
      gameScreen = WrongAnswerGameScreen(players: names);
    } else if (widget.title == 'الجاسوس') {
      gameScreen = SpyGameScreen(
        players: names,
        timeLimitSeconds: _hasTimeLimit ? _spyTimeLimit : 0,
      );
    } else if (widget.title == 'من هو؟') {
      gameScreen = WhoIsGameScreen(players: names);
    } else if (widget.title == 'كمل المثل') {
      gameScreen = ProverbGameScreen(players: names);
    } else {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => gameScreen),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_setupPhase > 0) {
          setState(() => _setupPhase--);
        } else {
          _showExitDialog();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                           if (_setupPhase > 0) {
                            setState(() => _setupPhase--);
                          } else {
                            _showExitDialog();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF5350),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF1A1A1A), width: 3),
                          ),
                          child: Icon(_setupPhase > 0 ? Icons.arrow_forward : Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      CategoryHeader(
                        title: widget.title,
                        imagePath: widget.imagePath,
                        backgroundColor: widget.backgroundColor,
                        heroTag: 'hero_setup_${widget.title}',
                      ),
                      const SizedBox(height: 30),
                      if (_setupPhase == 0) _buildPlayersPhase() else _buildTimePhase(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: StyledNextButton(text: 'التالي', onTap: _onNextPressed),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayersPhase() {
    return Column(
      children: [
        Center(
          child: Text(
            'أدخل أسماء اللاعبين',
            style: GoogleFonts.lalezar(fontSize: 28, color: Colors.grey.shade700),
          ),
        ),
        const SizedBox(height: 10),
        ..._controllers.asMap().entries.map((entry) {
          int idx = entry.key;
          return CustomTextField(
            hint: 'اسم اللاعب ${idx + 1}',
            controller: _controllers[idx],
            hasRemove: _controllers.length > 2,
            onDelete: () => _removePlayer(idx),
            fillColor: widget.title == 'الجاسوس' ? const Color(0xFFFFB74D) : null,
          );
        }).toList(),
        Center(
          child: GestureDetector(
            onTap: _addPlayer,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 20),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF81D4FA),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF1A1A1A), width: 3),
              ),
              child: const Icon(Icons.add, color: Color(0xFF1A1A2E), size: 36),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePhase() {
     int minutes = _spyTimeLimit ~/ 60;
     int seconds = _spyTimeLimit % 60;
     String timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Column(
      children: [
        const SizedBox(height: 50),
        Text(
          'المدة',
          style: GoogleFonts.lalezar(fontSize: 28, color: const Color(0xFF1A1A2E)),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFF1A1A1A), width: 3),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _timeBtn(Icons.remove, const Color(0xFFEF9A9A), () {
                if (_spyTimeLimit > 30) setState(() => _spyTimeLimit -= 30);
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  timeStr,
                  style: GoogleFonts.lalezar(fontSize: 32, color: const Color(0xFF1A1A2E)),
                ),
              ),
              _timeBtn(Icons.add, const Color(0xFFA5D6A7), () {
                setState(() => _spyTimeLimit += 30);
              }),
            ],
          ),
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'حد الوقت',
              style: GoogleFonts.lalezar(fontSize: 24, color: const Color(0xFF1A1A2E)),
            ),
            const SizedBox(width: 15),
            Checkbox(
              value: _hasTimeLimit,
              activeColor: const Color(0xFFEF9A9A),
              onChanged: (val) => setState(() => _hasTimeLimit = val ?? true),
            ),
          ],
        ),
      ],
    );
  }

  Widget _timeBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}
