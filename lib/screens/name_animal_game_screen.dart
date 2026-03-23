import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/styled_widgets.dart';
import '../data/services/audio_service.dart';

class NameAnimalGameScreen extends StatefulWidget {
  const NameAnimalGameScreen({super.key});

  @override
  State<NameAnimalGameScreen> createState() => _NameAnimalGameScreenState();
}

class _NameAnimalGameScreenState extends State<NameAnimalGameScreen> {
  final List<String> _letters = [
    'أ', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ', 'د', 'ر', 'ز', 'س', 'ش',
    'ص', 'ض', 'ط', 'ظ', 'ع', 'غ', 'ف', 'ق', 'ك', 'ل', 'م', 'ن', 'هـ', 'و', 'ي'
  ];
  
  String _currentLetter = '?';
  Timer? _timer;
  int _secondsRemaining = 60;
  bool _isRunning = false;

  void _generateRandomLetter() {
    setState(() {
      _currentLetter = _letters[Random().nextInt(_letters.length)];
      _secondsRemaining = 60;
      _isRunning = false;
      _timer?.cancel();
    });
    HapticFeedback.mediumImpact();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          setState(() => _secondsRemaining--);
        } else {
          timer.cancel();
          setState(() => _isRunning = false);
          HapticFeedback.heavyImpact();
          AudioService.playWin(); // Play win sound when timer ends!
           showDialog(
            context: context,
            builder: (context) => CustomDialog(
              title: 'انتهى الوقت!',
              message: 'نزلوا الأقلام وحسبوا النقاط!',
              actions: [
                DialogButton(
                  text: 'موافق',
                  color: const Color(0xFFA5D6A7),
                  onTap: () => Navigator.pop(context),
                )
              ],
            )
          );
        }
      });
    }
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
                title: 'حرف واسم',
                imagePath: 'assets/images/logo.png', // Temporary, will use generated one if quote resets
                backgroundColor: Color(0xFFA5D6A7),
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
                              'الحرف المختار:',
                              style: GoogleFonts.lalezar(fontSize: 24, color: Colors.grey),
                            ),
                            const SizedBox(height: 10),
                            Container(
                               width: 120,
                               height: 120,
                               decoration: BoxDecoration(
                                  color: const Color(0xFFFFCC33),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: const Color(0xFF1A1A1A), width: 4),
                               ),
                               child: Center(
                                 child: Text(
                                   _currentLetter,
                                   style: GoogleFonts.lalezar(fontSize: 80, color: const Color(0xFF1A1A2E), height: 1.0),
                                 ),
                               ),
                            ),
                            const SizedBox(height: 30),
                            
                            // Timer display
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                              decoration: BoxDecoration(
                                color: _secondsRemaining <= 10 ? const Color(0xFFEF5350) : const Color(0xFF3DD9EB),
                                borderRadius: BorderRadius.circular(40),
                                border: Border.all(color: const Color(0xFF1A1A1A), width: 3),
                              ),
                              child: Text(
                                _secondsRemaining.toString().padLeft(2, '0'),
                                style: GoogleFonts.lalezar(fontSize: 48, color: Colors.white, height: 1.1),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'اسم - حيوان - نبات - جماد - بلد',
                              style: GoogleFonts.lalezar(fontSize: 18, color: const Color(0xFF1A1A2E)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                   children: [
                       StyledNextButton(
                          text: 'حرف جديد',
                          onTap: _generateRandomLetter,
                          color: const Color(0xFFFFB74D),
                       ),
                   ],
                )
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: StyledNextButton(
                          text: _isRunning ? 'إيقاف الوقت' : 'بدء الوقت',
                          onTap: _currentLetter == '?' ? () {} : _toggleTimer,
                          color: _currentLetter == '?' ? Colors.grey : const Color(0xFFA5D6A7),
                       ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
