import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/styled_widgets.dart';
import '../data/services/ai_service.dart';
import '../data/services/tts_service.dart';
import '../data/services/audio_service.dart';
import '../data/services/point_service.dart';
import 'game_win_screen.dart';

class WhoIsGameScreen extends StatefulWidget {
  final List<String> players;
  const WhoIsGameScreen({super.key, required this.players});

  @override
  State<WhoIsGameScreen> createState() => _WhoIsGameScreenState();
}

class _WhoIsGameScreenState extends State<WhoIsGameScreen> {
  String _currentQuestion = 'استعدوا...';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchNext();
  }

  Future<void> _fetchNext() async {
    if (_isLoading) return;
    AudioService.playClick();
    setState(() => _isLoading = true);
    final q = await AIService.getWhoIsQuestion();
    if (mounted) {
      setState(() {
        _currentQuestion = q ?? 'حدث خطأ، حاول ثانية!';
        _isLoading = false;
      });
      if (!isError(q)) TTSService.speak(_currentQuestion);
    }
  }

  bool isError(String? q) => q == null || q.contains('خطأ') || q.contains('نعتذر');

  void _showWinnerSelection() {
    AudioService.playClick();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('من هو الفائز؟', textAlign: TextAlign.center, style: GoogleFonts.lalezar(fontSize: 24)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.players.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(widget.players[index], textAlign: TextAlign.center, style: GoogleFonts.lalezar(fontSize: 20)),
                onTap: () {
                  Navigator.pop(context);
                  _awardPoints(widget.players[index]);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _awardPoints(String winnerName) {
    PointService.addPoints(5); // Reduced from 15 to 5
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameWinScreen(
          winnerName: winnerName,
          pointsEarned: 5,
          onPlayAgain: () {
            Navigator.pop(context);
            _fetchNext();
          },
          onExit: () => Navigator.popUntil(context, (route) => route.isFirst),
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: 'هل أنت متأكد؟',
        message: 'هل أنت متأكد أنك تريد الخروج؟',
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
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
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
                title: 'من هو؟',
                imagePath: 'assets/images/who_is.png',
                backgroundColor: Color(0xFFFFB74D),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFF1A1A1A), width: 4),
                          boxShadow: const [
                             BoxShadow(
                                color: Color(0xFFE0E0E0),
                                offset: Offset(0, 10),
                                blurRadius: 0,
                             ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'السؤال:',
                              style: GoogleFonts.lalezar(fontSize: 24, color: Colors.grey),
                            ),
                            const SizedBox(height: 20),
                            if (_isLoading)
                              const Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(color: Color(0xFF1A1A2E)),
                              )
                            else
                              Text(
                                _currentQuestion,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.lalezar(fontSize: 32, color: const Color(0xFF1A1A2E), height: 1.3),
                              ),
                            const SizedBox(height: 30),

                            const SizedBox(height: 30),
                            Text(
                              'عدوا لي الـ 3 وكلكم أشروا على الشخص المناسب! 😁',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lalezar(fontSize: 18, color: const Color(0xFFEF5350)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: StyledNextButton(
                        text: 'سؤال جديد',
                        onTap: _fetchNext,
                        color: const Color(0xFFBDBDBD),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: StyledNextButton(
                        text: 'إختر الفائز 🏆',
                        onTap: _showWinnerSelection,
                        color: const Color(0xFFFFB74D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
