import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/services/auth_service.dart';
import '../data/services/audio_service.dart';

class MheibesGameScreen extends StatefulWidget {
  const MheibesGameScreen({super.key});

  @override
  State<MheibesGameScreen> createState() => _MheibesGameScreenState();
}

class _MheibesGameScreenState extends State<MheibesGameScreen> {
  int _selectedPlayerIndex = -1; // -1 means none selected
  bool _isMyTurn = true;
  int _myScore = 12;
  int _opponentScore = 10;
  String _userName = 'أنت';

  Future<void> _loadUserName() async {
    final name = await AuthService.getUserName();
    if (name != null) {
      setState(() {
        _userName = name;
      });
    }
  }

  void _startGame() {}

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _startGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(),
                _buildTurnIndicator(),
                const SizedBox(height: 20),
                _buildTeamSection('فريق الخصم', true),
                const SizedBox(height: 30),
                _buildTeamSection('فريقك', false),
                const SizedBox(height: 40),
                _buildActionSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildScoreBadge('الخصم', _opponentScore, const Color(0xFFEF5350)),
          Text(
            'محيبس',
            style: GoogleFonts.lalezar(
              fontSize: 32,
              color: const Color(0xFFFFD700),
              letterSpacing: 1.2,
            ),
          ),
          _buildScoreBadge(_userName, _myScore, const Color(0xFF4CAF50)),
        ],
      ),
    );
  }

  Widget _buildScoreBadge(String label, int score, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.lalezar(fontSize: 12, color: Colors.white70),
          ),
          Text(
            '$score',
            style: GoogleFonts.lalezar(fontSize: 20, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTurnIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      decoration: BoxDecoration(
        color: _isMyTurn ? const Color(0xFFFF8C00) : Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          if (_isMyTurn)
            BoxShadow(
              color: const Color(0xFFFF8C00).withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Text(
        _isMyTurn ? 'دورك الآن' : 'دور الخصم...',
        style: GoogleFonts.lalezar(
          fontSize: 22,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTeamSection(String title, bool isOpponent) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            title,
            style: GoogleFonts.lalezar(
              fontSize: 18,
              color: isOpponent ? Colors.white54 : const Color(0xFFFFD700),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              _buildPlayerRow(isOpponent, 0),
              const SizedBox(height: 15),
              _buildPlayerRow(isOpponent, 5),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerRow(bool isOpponent, int startIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (index) {
        int playerIdx = startIndex + index;
        bool isSelected = !isOpponent && _selectedPlayerIndex == playerIdx;
        return _buildPlayerAvatar(isOpponent, playerIdx, isSelected);
      }),
    );
  }

  Widget _buildPlayerAvatar(bool isOpponent, int index, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (!isOpponent) {
          AudioService.playClick();
          setState(() {
            _selectedPlayerIndex = index;
          });
        }
      },
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFFFFD700) : Colors.white24,
                width: isSelected ? 4 : 2,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.6),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: CircleAvatar(
              backgroundColor: isOpponent ? Colors.grey.withOpacity(0.2) : const Color(0xFF0F3460),
              child: Icon(
                Icons.person,
                color: isOpponent ? Colors.white24 : Colors.white70,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${index + 1}',
            style: GoogleFonts.lalezar(
              fontSize: 12,
              color: isSelected ? const Color(0xFFFFD700) : Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40, left: 30, right: 30),
      child: GestureDetector(
        onTap: () {
          if (_selectedPlayerIndex != -1) {
            AudioService.playCorrect();
            // Handle player selection
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          height: 65,
          decoration: BoxDecoration(
            color: _selectedPlayerIndex != -1 ? const Color(0xFFFF8C00) : Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              if (_selectedPlayerIndex != -1)
                BoxShadow(
                  color: const Color(0xFFFF8C00).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
            ],
            border: Border.all(
              color: _selectedPlayerIndex != -1 ? const Color(0xFFFFD700) : Colors.white10,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              'اختر اللاعب',
              style: GoogleFonts.lalezar(
                fontSize: 24,
                color: _selectedPlayerIndex != -1 ? Colors.white : Colors.white24,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
