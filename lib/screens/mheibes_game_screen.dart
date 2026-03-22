import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/styled_widgets.dart';

class MheibesGameScreen extends StatefulWidget {
  const MheibesGameScreen({super.key});

  @override
  State<MheibesGameScreen> createState() => _MheibesGameScreenState();
}

class _MheibesGameScreenState extends State<MheibesGameScreen> {
  int _handWithRing = -1; // -1 means concealed
  int _selectedHand = -1;
  bool _revealed = false;
  int _score1 = 0;
  int _score2 = 0;
  bool _isMicOn = true;
  final Random _random = Random();

  void _startGame() {
    setState(() {
      _handWithRing = _random.nextInt(6); // 6 hands per team
      _selectedHand = -1;
      _revealed = false;
    });
  }

  void _onHandTap(int index) {
    if (_revealed) return;
    setState(() {
      _selectedHand = index;
      _revealed = true;
      if (_selectedHand == _handWithRing) {
        _score2++; // Current turn score
      } else {
        _score1++;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _startGame();
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
            Text(
              _revealed ? (_selectedHand == _handWithRing ? 'لقيته! عاشت إيدك' : 'للأسف، مو بهاي الإيد') : 'وين المحيبس؟ اختر إيد واحدة',
              style: GoogleFonts.lalezar(fontSize: 24, color: const Color(0xFFEF5350)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(child: _buildHandsGrid()),
            const SizedBox(height: 20),
            if (_revealed) 
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                child: StyledNextButton(text: 'جولة جديدة', onTap: _startGame),
              ),
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
            'لعبة المحيبس',
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
        _scoreItem('فريقنا', _score1, const Color(0xFF81D4FA)),
        _scoreItem('فريقهم', _score2, const Color(0xFFFFB74D)),
      ],
    );
  }

  Widget _scoreItem(String team, int score, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1A1A1A), width: 3),
      ),
      child: Row(
        children: [
          Text('$score', style: GoogleFonts.lalezar(fontSize: 24, color: Colors.white)),
          const SizedBox(width: 10),
          Text(team, style: GoogleFonts.lalezar(fontSize: 18, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildHandsGrid() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        itemCount: 6,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
           crossAxisCount: 2,
           childAspectRatio: 1.2,
           crossAxisSpacing: 15,
           mainAxisSpacing: 15,
        ),
        itemBuilder: (context, index) {
          bool hasRing = index == _handWithRing;
          bool isSelected = index == _selectedHand;
          return _handWidget(index, hasRing, isSelected);
        },
      ),
    );
  }

  Widget _handWidget(int index, bool hasRing, bool isSelected) {
    IconData icon;
    Color color = Colors.white;
    
    if (!_revealed) {
      icon = Icons.front_hand;
      color = const Color(0xFFFFCC80);
    } else {
       if (hasRing) {
         icon = Icons.ring_volume; // Use ring icon placeholder
         color = const Color(0xFFFFD700);
       } else {
         icon = Icons.pan_tool;
         color = Colors.grey.shade300;
       }
    }

    return GestureDetector(
      onTap: () => _onHandTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFFEF5350) : const Color(0xFF1A1A1A),
            width: isSelected ? 4 : 2,
          ),
          boxShadow: [
             if (isSelected) const BoxShadow(color: Color(0xFFEF5350), blurRadius: 10),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Icon(icon, size: 48, color: isSelected ? const Color(0xFFEF5350) : const Color(0xFF1A1A2E)),
               const SizedBox(height: 5),
               if (_revealed && hasRing) Text('لقيته!', style: GoogleFonts.lalezar(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
