import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('Initializing Supabase...');
    await Supabase.initialize(
      url: 'https://hvbkywxobyfotoivkmyj.supabase.co',
      anonKey: 'sb_publishable_akp4yHQ77CxbvqskJouY4A_2NiZQFS3',
    );
    debugPrint('Supabase initialized successfully');
  } catch (e) {
    debugPrint('Initialization error: $e');
  }
  runApp(const MakhmakhaApp());
}

class MakhmakhaApp extends StatelessWidget {
  const MakhmakhaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مخمخة',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        scrollbars: true,
      ),
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Lalezar',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFFCC33)),
      ),
      home: const SplashScreen(),
    );
  }
}
