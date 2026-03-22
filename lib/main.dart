import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MakhmakhaApp());
}

class MakhmakhaApp extends StatelessWidget {
  const MakhmakhaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مخمخة',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // Using Lalezar for that playful Arabic vibe
        textTheme: GoogleFonts.lalezarTextTheme(),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFFCC33)),
      ),
      home: const SplashScreen(),
    );
  }
}
