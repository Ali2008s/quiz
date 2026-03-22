import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/styled_widgets.dart';
import 'not_a_word_game_screen.dart';

class NotAWordSetupScreen extends StatefulWidget {
  const NotAWordSetupScreen({super.key});

  @override
  State<NotAWordSetupScreen> createState() => _NotAWordSetupScreenState();
}

class _NotAWordSetupScreenState extends State<NotAWordSetupScreen> {
  int _phase = 1;
  int _rounds = 2;
  int _timeSeconds = 60;

  final TextEditingController _team1Controller = TextEditingController(
    // text: 'اسم الفريق الأول',
  );
  final TextEditingController _team2Controller = TextEditingController(
    // text: 'اسم الفريق الثاني',
  );

  Map<String, bool> _categories = {
    'أمثال': true,
    'مسلسلات': false,
    'مسرحيات': false,
  };

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: 'هل أنت متأكد؟',
        message: 'هل أنت متأكد أنك تريد الخروج من التحدى؟',
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
    if (_phase == 1) {
      setState(() => _phase = 2);
    } else {
      _proceedToGame();
    }
  }

  void _proceedToGame() {
    List<String> selectedCategories = _categories.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار فئة واحدة على الأقل')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotAWordGameScreen(
          rounds: _rounds,
          timePerRound: _timeSeconds,
          team1Name: _team1Controller.text,
          team2Name: _team2Controller.text,
          categories: selectedCategories,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_phase == 2) {
          setState(() => _phase = 1);
        } else {
          _showExitDialog();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
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
                          border: Border.all(
                            color: const Color(0xFF1A1A1A),
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const CategoryHeader(
                        title: 'ولا كلمة',
                        imagePath: 'assets/images/silent.png',
                        backgroundColor: Color(0xFFA5D6A7),
                      ),
                      const SizedBox(height: 50),
                      if (_phase == 1) _buildPhase1() else _buildPhase2(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(30),
                child: StyledNextButton(text: 'التالي', onTap: _onNextPressed),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhase1() {
    String timeStr =
        '${(_timeSeconds ~/ 60).toString().padLeft(1, '0')}:${(_timeSeconds % 60).toString().padLeft(2, '0')}';

    return Column(
      children: [
        _buildCounter(
          'عدد الجولات',
          '$_rounds',
          (val) {
            setState(() => _rounds = val.clamp(1, 10));
          },
          step: 1,
          currentVal: _rounds,
        ),
        const SizedBox(height: 40),
        _buildCounter(
          'الوقت لكل جولة',
          timeStr,
          (val) {},
          isTime: true,
          currentVal: _timeSeconds,
        ),
      ],
    );
  }

  Widget _buildPhase2() {
    return Column(
      children: [
        CustomTextField(
          controller: _team1Controller,
          hint: 'اسم الفريق الأول',
          fillColor: const Color(0xFFFFCC33),
        ),
        const SizedBox(height: 15),
        CustomTextField(
          controller: _team2Controller,
          hint: 'اسم الفريق الثاني',
          fillColor: const Color(0xFFB39DDB),
        ),
        const SizedBox(height: 50),
        Text(
          'اختر الفئة',
          style: GoogleFonts.lalezar(
            fontSize: 28,
            color: const Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 20),
        ..._categories.keys.map((cat) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    cat,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.lalezar(
                      fontSize: 24,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                ),
                const SizedBox(width: 30),
                GestureDetector(
                  onTap: () =>
                      setState(() => _categories[cat] = !_categories[cat]!),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _categories[cat]!
                          ? const Color(0xFFEF9A9A)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF1A1A1A),
                        width: 3,
                      ),
                    ),
                    child: _categories[cat]!
                        ? const Icon(Icons.check, color: Colors.white, size: 28)
                        : null,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCounter(
    String title,
    dynamic label,
    Function(int) onUpdate, {
    int step = 1,
    bool isTime = false,
    required int currentVal,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.lalezar(
            fontSize: 28,
            color: const Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _roundBtn(Icons.remove, const Color(0xFFEF9A9A), () {
              if (isTime) {
                if (_timeSeconds > 30) setState(() => _timeSeconds -= 30);
              } else {
                if (_rounds > 1) setState(() => _rounds -= 1);
              }
            }),
            const SizedBox(width: 40),
            Text(
              '$label',
              style: GoogleFonts.lalezar(
                fontSize: 36,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(width: 40),
            _roundBtn(Icons.add, const Color(0xFFA5D6A7), () {
              if (isTime) {
                setState(() => _timeSeconds += 30);
              } else {
                setState(() => _rounds += 1);
              }
            }),
          ],
        ),
      ],
    );
  }

  Widget _roundBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF1A1A1A), width: 3),
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}
