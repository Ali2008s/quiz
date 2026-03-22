import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/styled_widgets.dart';

class XOGameScreen extends StatefulWidget {
  const XOGameScreen({super.key});

  @override
  State<XOGameScreen> createState() => _XOGameScreenState();
}

class _XOGameScreenState extends State<XOGameScreen> {
  List<String> _board = List.generate(9, (index) => '');
  bool _xTurn = true;
  int _scoreX = 0;
  int _scoreO = 0;
  bool _isMicOn = true;

  void _onTap(int index) {
    if (_board[index] == '') {
      setState(() {
        _board[index] = _xTurn ? 'X' : 'O';
        _xTurn = !_xTurn;
        _checkWinner();
      });
    }
  }

  void _checkWinner() {
    List<List<int>> winLines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // Columns
      [0, 4, 8], [2, 4, 6]             // Diagonals
    ];

    for (var line in winLines) {
      if (_board[line[0]] != '' &&
          _board[line[0]] == _board[line[1]] &&
          _board[line[0]] == _board[line[2]]) {
        _showWinDialog(_board[line[0]]);
        return;
      }
    }

    if (!_board.contains('')) {
      _showWinDialog('Draw');
    }
  }

  void _showWinDialog(String winner) {
    if (winner == 'X') _scoreX++;
    if (winner == 'O') _scoreO++;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomDialog(
        title: winner == 'Draw' ? 'تعادل!' : 'فوز!',
        message: winner == 'Draw' ? 'لا يوجد رابح في هذه الجولة' : 'مبروك للاعب $winner!',
        actions: [
          DialogButton(
            text: 'إعادة اللعب',
            color: const Color(0xFFA5D6A7),
            onTap: () {
              Navigator.pop(context);
              _resetBoard();
            },
          ),
          DialogButton(
            text: 'خروج',
            color: const Color(0xFFEF5350),
            onTap: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _resetBoard() {
    setState(() {
      _board = List.generate(9, (index) => '');
      _xTurn = true;
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
            _buildGrid(),
            const SizedBox(height: 40),
            _buildControls(),
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
          GestureDetector(
            onTap: () => Navigator.pop(context),
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
          Text(
            'XO - أونلاين',
            style: GoogleFonts.lalezar(fontSize: 28, color: const Color(0xFF1A1A2E)),
          ),
          GestureDetector(
            onTap: () => setState(() => _isMicOn = !_isMicOn),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isMicOn ? const Color(0xFFA5D6A7) : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
              ),
              child: Icon(_isMicOn ? Icons.mic : Icons.mic_off, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _playerScore('اللاعب X', _scoreX, const Color(0xFF64B5F6), _xTurn),
        _playerScore('اللاعب O', _scoreO, const Color(0xFFFFCC33), !_xTurn),
      ],
    );
  }

  Widget _playerScore(String name, int score, Color color, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(isActive ? 1 : 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1A1A1A), width: isActive ? 3 : 1),
      ),
      child: Column(
        children: [
          Text(name, style: GoogleFonts.lalezar(fontSize: 18, color: Colors.white)),
          Text('$score', style: GoogleFonts.lalezar(fontSize: 28, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1A1A1A), width: 4),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _onTap(index),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _board[index],
                  style: GoogleFonts.lalezar(
                    fontSize: 48,
                    color: _board[index] == 'X' ? const Color(0xFF64B5F6) : const Color(0xFFFFCC33),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildControls() {
    return Column(
      children: [
        if (_isMicOn)
          Container(
            padding: const EdgeInsets.all(15),
             decoration: BoxDecoration(
               color: const Color(0xFFA5D6A7).withOpacity(0.2),
               shape: BoxShape.circle,
             ),
             child: const Icon(Icons.spatial_audio_off, color: Color(0xFFA5D6A7), size: 40),
          ),
          const SizedBox(height: 10),
          Text(
            _isMicOn ? 'صوتك مسموع للفريق الآخر' : 'المايك مكتوم',
            style: GoogleFonts.lalezar(fontSize: 14, color: Colors.grey),
          ),
      ],
    );
  }
}
