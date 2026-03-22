import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/styled_widgets.dart';

class RPSGameScreen extends StatefulWidget {
  const RPSGameScreen({super.key});

  @override
  State<RPSGameScreen> createState() => _RPSGameScreenState();
}

class _RPSGameScreenState extends State<RPSGameScreen> {
  String _playerChoice = '';
  String _opponentChoice = '';
  String _result = 'اختر حركتك!';
  int _score1 = 0;
  int _score2 = 0;
  bool _isMicOn = true;
  final Random _random = Random();

  final List<String> _choices = ['حجرة', 'ورقة', 'مقص'];

  void _onChoice(String choice) {
    setState(() {
      _playerChoice = choice;
      _opponentChoice = _choices[_random.nextInt(3)];
      _determineWinner();
    });
  }

  void _determineWinner() {
    if (_playerChoice == _opponentChoice) {
      _result = 'تعادل!';
    } else if (
        (_playerChoice == 'حجرة' && _opponentChoice == 'مقص') ||
        (_playerChoice == 'ورقة' && _opponentChoice == 'حجرة') ||
        (_playerChoice == 'مقص' && _opponentChoice == 'ورقة')
    ) {
      _result = 'أنت فزت! 🎉';
      _score1++;
    } else {
      _result = 'الخصم فاز! 🤖';
      _score2++;
    }
  }

  void _reset() {
    setState(() {
      _playerChoice = '';
      _opponentChoice = '';
      _result = 'اختر حركتك!';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildScoreBoard(),
            const SizedBox(height: 30),
            _buildArena(),
            const SizedBox(height: 40),
            Text(_result, style: GoogleFonts.lalezar(fontSize: 32, color: const Color(0xFFEF5350))),
            const Spacer(),
            _buildChoicePanel(),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFEF5350), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1A1A1A), width: 3)), child: const Icon(Icons.close, color: Colors.white, size: 20))),
          Text('حجرة ورقة مقص', style: GoogleFonts.lalezar(fontSize: 28, color: const Color(0xFF1A1A2E))),
           GestureDetector(onTap: () => setState(() => _isMicOn = !_isMicOn), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _isMicOn ? const Color(0xFFA5D6A7) : Colors.grey, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF1A1A1A), width: 2)), child: Icon(_isMicOn ? Icons.mic : Icons.mic_off, color: Colors.white, size: 24))),
        ],
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_playerScore('أنت', _score1, const Color(0xFF81D4FA)), _playerScore('الخصم', _score2, const Color(0xFFFFB74D))]);
  }

  Widget _playerScore(String label, int score, Color color) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF1A1A1A), width: 3)), child: Column(children: [Text(label, style: GoogleFonts.lalezar(fontSize: 18, color: Colors.white)), Text('$score', style: GoogleFonts.lalezar(fontSize: 32, color: Colors.white))]));
  }

  Widget _buildArena() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _arenaChoice(_playerChoice, 'أنت', const Color(0xFF81D4FA)),
        const SizedBox(width: 20),
        Text('VS', style: GoogleFonts.lalezar(fontSize: 48, color: Colors.grey.shade300)),
        const SizedBox(width: 20),
        _arenaChoice(_opponentChoice, 'الخصم', const Color(0xFFFFB74D)),
      ],
    );
  }

  Widget _arenaChoice(String choice, String label, Color color) {
    IconData icon;
    if (choice == 'حجرة') icon = Icons.back_hand; // Placeholder for rock
    else if (choice == 'ورقة') icon = Icons.front_hand;
    else if (choice == 'مقص') icon = Icons.content_cut;
    else icon = Icons.question_mark;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 120, height: 120,
          decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(32), border: Border.all(color: color, width: 4)),
          child: Icon(icon, size: 60, color: color),
        ),
        const SizedBox(height: 10),
        Text(choice.isEmpty ? label : choice, style: GoogleFonts.lalezar(fontSize: 20, color: color)),
      ],
    );
  }

  Widget _buildChoicePanel() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _choices.map((c) => _choiceBtn(c)).toList(),
    );
  }

  Widget _choiceBtn(String choice) {
    return GestureDetector(
      onTap: () => _onChoice(choice),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: const Color(0xFF1A1A1A), width: 3), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 4))]),
        child: Column(
          children: [
             Icon(choice == 'حجرة' ? Icons.back_hand : (choice == 'ورقة' ? Icons.front_hand : Icons.content_cut), size: 40, color: const Color(0xFF1A1A2E)),
             const SizedBox(height: 5),
             Text(choice, style: GoogleFonts.lalezar(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
