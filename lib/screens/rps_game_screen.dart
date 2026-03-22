import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/services/auth_service.dart';
import '../data/services/rps_game_service.dart';

class RPSGameScreen extends StatefulWidget {
  const RPSGameScreen({super.key});

  @override
  State<RPSGameScreen> createState() => _RPSGameScreenState();
}

class _RPSGameScreenState extends State<RPSGameScreen> {
  final RPSGameService _gameService = RPSGameService();
  String? _roomId;
  bool _isCreating = false;
  bool _isJoining = false;
  String? _playerName;
  StreamSubscription<RPSGameState?>? _gameSub;
  RPSGameState? _gameState;
  final TextEditingController _joinController = TextEditingController();
  final List<String> _choices = ['حجرة', 'ورقة', 'مقص'];

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final name = await AuthService.getUserName();
    if (mounted) setState(() => _playerName = name);
  }

  @override
  void dispose() {
    _gameSub?.cancel();
    _joinController.dispose();
    super.dispose();
  }

  void _createRoom() async {
    if (_playerName == null) return;
    setState(() => _isCreating = true);
    try {
      final id = await _gameService.createRoom(_playerName!);
      _listenToGame(id);
      setState(() => _roomId = id);
    } catch (e) {
      if (mounted) setState(() => _isCreating = false);
      _showError('خطأ في إنشاء الغرفة');
    }
  }

  void _joinRoom() async {
    final id = _joinController.text.trim();
    if (id.isEmpty || _playerName == null) return;
    setState(() => _isJoining = true);
    try {
      await _gameService.joinRoom(id, _playerName!);
      _listenToGame(id);
      setState(() => _roomId = id);
    } catch (e) {
      if (mounted) setState(() => _isJoining = false);
      _showError('الغرفة غير موجودة');
    }
  }

  void _listenToGame(String id) {
    _gameSub?.cancel();
    _gameSub = _gameService.gameStream(id).listen((state) {
      if (!mounted) return;
      if (state == null) {
        if (_roomId != null) _showRoomDeletedDialog();
        return;
      }
      setState(() {
        _gameState = state;
        _isCreating = false;
        _isJoining = false;
      });
    });
  }

  void _showRoomDeletedDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text('تنبيه!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lalezar(color: Colors.red)),
              content: Text('تم إغلاق الغرفة من قبل المضيف أو انتهت الجلسة.',
                  textAlign: TextAlign.center, style: GoogleFonts.lalezar()),
              actions: [
                Center(
                    child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _clearGameState();
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A1A2E)),
                        child: Text('تمام',
                            style: GoogleFonts.lalezar(color: Colors.white))))
              ],
            ));
  }

  void _clearGameState() {
    if (mounted) {
      setState(() {
        _roomId = null;
        _gameState = null;
        _isCreating = false;
        _isJoining = false;
      });
      _gameSub?.cancel();
    }
  }

  Future<void> _onExit() async {
    if (_roomId != null && _gameState != null) {
      if (_gameState!.player1Id == _playerName)
        await _gameService.deleteRoom(_roomId!);
    }
    _clearGameState();
  }

  void _onChoice(String choice) {
    if (_gameState == null || _roomId == null || _playerName == null) return;
    bool isP1 = _playerName == _gameState!.player1Id;
    if (isP1 && _gameState!.player1Choice != null) return;
    if (!isP1 && _gameState!.player2Choice != null) return;
    _gameService.makeChoice(_roomId!, _playerName!, choice, _gameState!);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: GoogleFonts.lalezar()),
        backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
                child: Opacity(
                    opacity: 0.05,
                    child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Wrap(
                            spacing: 40,
                            runSpacing: 40,
                            children: List.generate(
                                100,
                                (index) =>
                                    const Icon(Icons.front_hand, size: 40)))))),
            (_roomId == null || _gameState == null)
                ? _buildMenu()
                : _buildGame(),
          ],
        ),
      ),
    );
  }

  Widget _buildMenu() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader('حجرة ورقة مقص - أونلاين',
              onBack: () => Navigator.pop(context)),
          const SizedBox(height: 20),
          if (_playerName != null)
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                    color: const Color(0xFFA5D6A7).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFFA5D6A7))),
                child: Text('مرحباً بك يا $_playerName',
                    style:
                        GoogleFonts.lalezar(color: const Color(0xFF2E7D32)))),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                _actionButton(
                    title: 'إنشاء غرفة تحدي',
                    subtitle: 'ابدأ المواجهة وشارك الكود',
                    icon: Icons.rocket_launch_rounded,
                    color: const Color(0xFF81C784),
                    onTap: _createRoom,
                    isLoading: _isCreating),
                const SizedBox(height: 40),
                Text('أو أدخل كود صديقك',
                    style:
                        GoogleFonts.lalezar(color: Colors.grey, fontSize: 18)),
                const SizedBox(height: 15),
                TextField(
                  controller: _joinController,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lalezar(fontSize: 24, letterSpacing: 4),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4)
                  ],
                  decoration: InputDecoration(
                      hintText: 'أدخل 4 أرقام',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(vertical: 20),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide:
                              const BorderSide(color: Colors.grey, width: 2)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                              color: Color(0xFF81C784), width: 3))),
                ),
                const SizedBox(height: 25),
                _actionButton(
                    title: 'دخول المواجهة',
                    icon: Icons.sports_esports_rounded,
                    color: const Color(0xFFFFB74D),
                    onTap: _joinRoom,
                    isLoading: _isJoining),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
      {required String title,
      String? subtitle,
      required IconData icon,
      required Color color,
      required VoidCallback onTap,
      bool isLoading = false}) {
    return GestureDetector(
        onTap: isLoading ? null : onTap,
        child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF1A1A1A), width: 3),
                boxShadow: [
                  BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5))
                ]),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (isLoading)
                const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 3))
              else
                Icon(icon, color: Colors.white, size: 28),
              const SizedBox(width: 15),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style:
                        GoogleFonts.lalezar(fontSize: 22, color: Colors.white)),
                if (subtitle != null)
                  Text(subtitle,
                      style: GoogleFonts.lalezar(
                          fontSize: 12, color: Colors.white.withOpacity(0.8)))
              ])
            ])));
  }

  Widget _buildHeader(String title, {required VoidCallback onBack}) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
              onTap: onBack,
              child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: const Color(0xFF1A1A1A), width: 2)),
                  child:
                      const Icon(Icons.arrow_back_ios_new_rounded, size: 20))),
          Text(title,
              style: GoogleFonts.lalezar(
                  fontSize: 28, color: const Color(0xFF1A1A2E))),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildGame() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader('مواجهة مباشرة', onBack: _onExit),
          if (_gameState!.player2Id == null) _buildRoomHeader(),
          const SizedBox(height: 20),
          _buildScoreBoard(),
          const SizedBox(height: 40),
          _buildArena(),
          const SizedBox(height: 40),
          _buildChoicePanel(),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildRoomHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFFD700), width: 2)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('كود الغرفة:',
              style: GoogleFonts.lalezar(fontSize: 12, color: Colors.white70)),
          Text(_roomId!,
              style: GoogleFonts.lalezar(
                  fontSize: 28,
                  color: const Color(0xFFFFD700),
                  letterSpacing: 4))
        ]),
        ElevatedButton(
            onPressed: () => Clipboard.setData(ClipboardData(text: _roomId!)),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 10)),
            child: Text('نسخ', style: GoogleFonts.lalezar()))
      ]),
    );
  }

  Widget _buildScoreBoard() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      _playerScore(_gameState!.player1Id, _gameState!.player1Score,
          const Color(0xFF81D4FA)),
      const Icon(Icons.bolt_rounded, size: 40, color: Colors.orange),
      _playerScore(_gameState!.player2Id ?? 'بانتظار المنافس...',
          _gameState!.player2Score, const Color(0xFFFFB74D))
    ]);
  }

  Widget _playerScore(String name, int score, Color color) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(width: 3)),
        child: Column(children: [
          Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lalezar(fontSize: 14, color: Colors.white)),
          Text('$score',
              style: GoogleFonts.lalezar(fontSize: 28, color: Colors.white))
        ]));
  }

  Widget _buildArena() {
    final isP1 = _playerName == _gameState!.player1Id;
    final myChoice =
        isP1 ? _gameState!.player1Choice : _gameState!.player2Choice;
    final oppChoice =
        isP1 ? _gameState!.player2Choice : _gameState!.player1Choice;
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _arenaChoice(myChoice, 'أنت', const Color(0xFF81D4FA), true),
      Text('VS',
          style:
              GoogleFonts.lalezar(fontSize: 48, color: Colors.grey.shade300)),
      _arenaChoice(oppChoice, 'الخصم', const Color(0xFFFFB74D), false)
    ]);
  }

  Widget _arenaChoice(String? choice, String label, Color color, bool isMe) {
    IconData icon = Icons.question_mark;
    if (choice != null) {
      if (choice == 'حجرة')
        icon = Icons.back_hand;
      else if (choice == 'ورقة')
        icon = Icons.front_hand;
      else if (choice == 'مقص') icon = Icons.content_cut;
    } else if (!isMe) icon = Icons.hourglass_bottom;
    return Column(children: [
      Container(
          width: 110,
          height: 110,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color, width: 3)),
          child: Icon(icon, size: 55, color: color)),
      const SizedBox(height: 10),
      Text(choice ?? (isMe ? 'اختر حركتك' : 'يختار...'),
          style: GoogleFonts.lalezar(fontSize: 18, color: color))
    ]);
  }

  Widget _buildChoicePanel() {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _choices.map((c) => _choiceBtn(c)).toList());
  }

  Widget _choiceBtn(String choice) {
    return GestureDetector(
        onTap: () => _onChoice(choice),
        child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(width: 3),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 4))
                ]),
            child: Column(children: [
              Icon(
                  choice == 'حجرة'
                      ? Icons.back_hand
                      : (choice == 'ورقة'
                          ? Icons.front_hand
                          : Icons.content_cut),
                  size: 45,
                  color: const Color(0xFF1A1A2E)),
              const SizedBox(height: 8),
              Text(choice, style: GoogleFonts.lalezar(fontSize: 18))
            ])));
  }
}
