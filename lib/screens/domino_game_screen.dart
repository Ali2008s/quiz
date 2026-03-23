import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/services/auth_service.dart';
import '../data/services/domino_game_service.dart';
import '../data/services/audio_service.dart';
import 'game_win_screen.dart';

class DominoGameScreen extends StatefulWidget {
  const DominoGameScreen({super.key});

  @override
  State<DominoGameScreen> createState() => _DominoGameScreenState();
}

class _DominoGameScreenState extends State<DominoGameScreen> {
  final DominoGameService _gameService = DominoGameService();
  String? _roomId;
  bool _isCreating = false;
  bool _isJoining = false;
  String? _playerName;
  StreamSubscription<DominoGameState?>? _gameSub;
  Timer? _pollTimer;
  DominoGameState? _gameState;
  final TextEditingController _joinController = TextEditingController();

  // Settings
  int _playerCount = 2; // 2 or 4
  String _difficulty = 'medium';
  bool _vsAI = false;

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
    _pollTimer?.cancel();
    _joinController.dispose();
    super.dispose();
  }

  void _showGameSetup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 50,
                    height: 6,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 20),
                Text(_vsAI ? 'إعدادات اللعب الفردي' : 'إعدادات اللعب الجماعي',
                    style: GoogleFonts.lalezar(
                        fontSize: 32, color: const Color(0xFF1A1A2E))),
                const SizedBox(height: 15),
                if (!_vsAI) ...[
                  _sectionHeader('عدد اللاعبين'),
                  Row(
                    children: [
                      Expanded(
                          child: _setupCard(
                              'لاعبين (1 ضد 1)',
                              Icons.person,
                              _playerCount == 2,
                              () => setModalState(() => _playerCount = 2))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _setupCard(
                              '4 لاعبين (فرق)',
                              Icons.group,
                              _playerCount == 4,
                              () => setModalState(() => _playerCount = 4))),
                    ],
                  ),
                ] else ...[
                  _sectionHeader('صعوبة الذكاء الاصطناعي'),
                  Row(
                    children: [
                      Expanded(
                          child: _setupCard(
                              'سهل',
                              Icons.sentiment_satisfied,
                              _difficulty == 'easy',
                              () => setModalState(() => _difficulty = 'easy'))),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _setupCard(
                              'متوسط',
                              Icons.sentiment_neutral,
                              _difficulty == 'medium',
                              () => setModalState(() => _difficulty = 'medium'))),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _setupCard(
                              'صعب 🔥',
                              Icons.sentiment_very_dissatisfied,
                              _difficulty == 'hard',
                              () => setModalState(() => _difficulty = 'hard'))),
                    ],
                  ),
                ],
                const SizedBox(height: 32),
                _actionBtn('ابدأ اللعبة الآن', Icons.play_arrow_rounded,
                    const Color(0xFF66BB6A), () {
                  Navigator.pop(context);
                  _createRoom();
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String t) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
          alignment: Alignment.centerRight,
          child: Text(t,
              style:
                  GoogleFonts.lalezar(fontSize: 18, color: Colors.grey[600]))));

  Widget _setupCard(String t, IconData i, bool s, VoidCallback o) {
    return GestureDetector(
      onTap: o,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: s ? const Color(0xFF1A1A2E) : const Color(0xFFF5F5F7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: s ? const Color(0xFF1A1A2E) : Colors.transparent,
              width: 3),
        ),
        child: Column(
          children: [
            Icon(i, color: s ? Colors.white : Colors.grey[600], size: 28),
            const SizedBox(height: 8),
            Text(t,
                style: GoogleFonts.lalezar(
                    color: s ? Colors.white : Colors.grey[800], fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(String t, IconData i, Color c, VoidCallback o) {
    return GestureDetector(
      onTap: o,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF1A1A1A), width: 3),
            boxShadow: const [
              BoxShadow(color: Color(0xFF1A1A1A), offset: Offset(0, 4))
            ]),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(i, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Text(t, style: GoogleFonts.lalezar(fontSize: 24, color: Colors.white))
        ]),
      ),
    );
  }

  // --- Core Game Functions ---
  void _createRoom() async {
    if (_playerName == null) return;
    setState(() => _isCreating = true);
    try {
      final id = await _gameService.createRoom(_playerName!,
          maxPlayers: _playerCount, difficulty: _difficulty, vsAI: _vsAI);
      _listenToGame(id);
      setState(() => _roomId = id);
    } catch (e) {
      if (mounted) setState(() => _isCreating = false);
      _showError('خطأ: $e');
    }
  }

  void _listenToGame(String id) {
    _gameSub?.cancel();
    _pollTimer?.cancel();
    
    // Web Fallback: Poll every 2 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
       if (_roomId == null) return;
       final state = await _gameService.getGameData(_roomId!);
       if (state != null && state.currentTurn != _gameState?.currentTurn) {
         if (mounted) setState(() => _gameState = state);
         _checkAIMove(state);
       }
    });

    _gameSub = _gameService.gameStream(id).listen((state) {
      if (!mounted || state == null) return;
      setState(() {
        _gameState = state;
        _isCreating = false;
        _isJoining = false;
      });
      if (state.winner != null) _handleWinner(state.winner!);
      _checkAIMove(state);
    });
  }

  void _checkAIMove(DominoGameState state) async {
    if (state.winner != null) return;
    final turn = state.currentTurn;
    String? currentPId;
    if (turn == 'player2') currentPId = state.player2Id;
    else if (turn == 'player3') currentPId = state.player3Id;
    else if (turn == 'player4') currentPId = state.player4Id;

    bool isAI = currentPId != null && (currentPId == 'ذكاء اصطناعي 🤖' || currentPId.contains('ذكاء'));
    if (isAI) {
      await Future.delayed(const Duration(milliseconds: 1000));
      _performAIMove(state);
    }
  }

  void _performAIMove(DominoGameState state) {
    final turn = state.currentTurn;
    List<DominoPiece> hand = [];
    if (turn == 'player2') hand = state.player2Hand;
    else if (turn == 'player3') hand = state.player3Hand;
    else if (turn == 'player4') hand = state.player4Hand;

    if (hand.isEmpty) return;

    if (state.board.isEmpty) {
      _gameService.makeMove(state.roomId, hand.first, true, state);
      return;
    }

    int v1 = state.board.first.side1;
    int v2 = state.board.last.side2;
    DominoPiece? move;
    bool atEnd = true;

    for (var p in hand) {
      if (p.side1 == v2 || p.side2 == v2) {
        move = p;
        atEnd = true;
        break;
      }
      if (p.side1 == v1 || p.side2 == v1) {
        move = p;
        atEnd = false;
        break;
      }
    }

    if (move != null) _gameService.makeMove(state.roomId, move, atEnd, state);
    else _gameService.passTurn(state.roomId, state);
  }

  void _handleWinner(String winner) {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => GameWinScreen(
                  winnerName: winner,
                  pointsEarned: 5,
                  onPlayAgain: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DominoGameScreen())),
                  onExit: () => Navigator.popUntil(context, (route) => route.isFirst),
                )));
  }

  void _showRoomDeletedDialog() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(width: 3)),
                title: Text('تنبيه!', style: GoogleFonts.lalezar(color: Colors.red)),
                content: Text('انتهت الجلسة أو تم حذف الغرفة.', style: GoogleFonts.lalezar()),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                      child: Text('تمام', style: GoogleFonts.lalezar()))
                ]));
  }

  @override
  Widget build(BuildContext context) {
    bool isFull = true;
    if (_gameState != null) {
      if (_gameState!.maxPlayers >= 2 && _gameState!.player2Id == null) isFull = false;
      if (_gameState!.maxPlayers >= 3 && _gameState!.player3Id == null) isFull = false;
      if (_gameState!.maxPlayers >= 4 && _gameState!.player4Id == null) isFull = false;
    }
    if (_roomId != null && _gameState != null && !isFull) return _waitingScreen();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
          child: (_roomId == null || _gameState == null)
              ? _buildMenu()
              : _buildGame()),
    );
  }

  Widget _waitingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          _header('بانتظار المنافسين...', Icons.people_outline, Colors.orange),
          const SizedBox(height: 30),
          Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                  color: const Color(0xFFF5F5FA),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(width: 3)),
              child: Column(children: [
                if (!_vsAI) ...[
                  Text('كود الغرفة: ${_roomId}', style: GoogleFonts.lalezar(fontSize: 32)),
                  const SizedBox(height: 10),
                ],
                Text('بانتظار اكمال العدد (${_gameState!.maxPlayers})', style: GoogleFonts.lalezar(color: Colors.grey[600])),
                const SizedBox(height: 30),
                const CircularProgressIndicator(color: Color(0xFF1A1A2E))
              ])),
          const SizedBox(height: 40),
          _actionBtn('إلغاء و خروج', Icons.close, Colors.red[400]!, () => Navigator.pop(context)),
        ]),
      ),
    );
  }

  Widget _buildMenu() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(children: [
        const SizedBox(height: 30),
        _header('لعبة الدومينو', Icons.extension_rounded, const Color(0xFF1A1A2E)),
        const SizedBox(height: 40),
        _menuBox('اللعب الجماعي', 'أدخل الغرفة ونافس أساطير الدومينو', const Color(0xFF64B5F6), Icons.public, () {
          setState(() => _vsAI = false);
          _showGameSetup();
        }),
        const SizedBox(height: 20),
        _menuBox('اللعب الفردي', 'تحدَّ الذكاء الاصطناعي وحدد الصعوبة', const Color(0xFFFF8A65), Icons.android_rounded, () {
          setState(() {
            _vsAI = true;
            _playerCount = 2;
          });
          _showGameSetup();
        }),
        const Spacer(),
        _joinCardUI(),
        const SizedBox(height: 30),
      ]),
    );
  }

  Widget _menuBox(String t, String s, Color c, IconData i, VoidCallback o) {
    return GestureDetector(
      onTap: o,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFF1A1A1A), width: 3),
            boxShadow: const [BoxShadow(color: Color(0xFF1A1A1A), offset: Offset(0, 6))]),
        child: Row(children: [
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(width: 2)),
              child: Icon(i, color: c, size: 30)),
          const SizedBox(width: 20),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t, style: GoogleFonts.lalezar(fontSize: 24, color: Colors.white)),
                Text(s, style: GoogleFonts.lalezar(fontSize: 14, color: Colors.white.withOpacity(0.9)))
              ]))
        ]),
      ),
    );
  }

  Widget _joinCardUI() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFF5F5F7), borderRadius: BorderRadius.circular(24), border: Border.all(width: 3)),
      child: Row(children: [
        Expanded(child: TextField(controller: _joinController, textAlign: TextAlign.center, style: GoogleFonts.lalezar(fontSize: 20), decoration: const InputDecoration(hintText: 'كود الغرفة', border: InputBorder.none))),
        ElevatedButton(onPressed: _joinRoom, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A2E), padding: const EdgeInsets.symmetric(horizontal: 24), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: Text('دخول', style: GoogleFonts.lalezar(color: Colors.white))),
      ]),
    );
  }

  _joinRoom() async {
    try {
      await _gameService.joinRoom(_joinController.text.trim(), _playerName!);
      _listenToGame(_joinController.text.trim());
      setState(() => _roomId = _joinController.text.trim());
    } catch (e) {
      _showError(e.toString());
    }
  }

  Widget _header(String t, IconData i, Color c) =>
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(i, color: c, size: 40),
        const SizedBox(width: 15),
        Text(t, style: GoogleFonts.lalezar(fontSize: 36, color: const Color(0xFF1A1A2E)))
      ]);

  Widget _buildGame() {
    final myName = _playerName?.trim();
    String myRole = 'player1';
    if (myName == _gameState!.player2Id?.trim()) myRole = 'player2';
    else if (myName == _gameState!.player3Id?.trim()) myRole = 'player3';
    else if (myName == _gameState!.player4Id?.trim()) myRole = 'player4';

    final myHand = _getMyHand(myRole);
    bool isMyTurn = _gameState!.currentTurn == myRole;

    return Column(children: [
      if (_gameState!.maxPlayers == 4)
        _playerBadge(_getPartnerName(myRole), _getPartnerHandCount(myRole), isTurn: _gameState!.currentTurn == _getPartnerRole(myRole)),
      Expanded(
          child: Row(children: [
        _playerBadgeSide(_getLeftOpponentName(myRole), _getLeftOpponentHandCount(myRole), isTurn: _gameState!.currentTurn == _getLeftRole(myRole)),
        Expanded(child: _boardUI()),
        if (_gameState!.maxPlayers == 4)
          _playerBadgeSide(_getRightOpponentName(myRole), _getRightOpponentHandCount(myRole), isTurn: _gameState!.currentTurn == _getRightRole(myRole)),
      ])),
      _controlsUI(myHand, isMyTurn),
    ]);
  }

  Widget _playerBadge(String n, int c, {bool isTurn = false}) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(color: isTurn ? const Color(0xFFFFF9C4) : const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(20), border: Border.all(color: isTurn ? const Color(0xFFFFCC33) : const Color(0xFF1A1A1A), width: 3)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(n.contains('ذكاء') ? Icons.android : Icons.person, size: 20),
        const SizedBox(width: 8),
        Text(n, style: GoogleFonts.lalezar(fontSize: 14)),
        const SizedBox(width: 15),
        _countB(c)
      ]),
    );
  }

  Widget _playerBadgeSide(String n, int c, {bool isTurn = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: isTurn ? const Color(0xFFFFF9C4) : const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(20), border: Border.all(color: isTurn ? const Color(0xFFFFCC33) : const Color(0xFF1A1A1A), width: 3)),
      child: RotatedBox(quarterTurns: 1, child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(n, style: GoogleFonts.lalezar(fontSize: 12)),
            const SizedBox(width: 10),
            _countB(c)
          ])),
    );
  }

  Widget _countB(int c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(8)),
      child: Text('$c', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)));

  Widget _boardUI() => Container(
      margin: const EdgeInsets.all(10),
      width: double.infinity,
      decoration: BoxDecoration(color: const Color(0xFFEDF2F4), borderRadius: BorderRadius.circular(30), border: Border.all(width: 3), boxShadow: const [BoxShadow(color: Color(0xFF1A1A1A), offset: Offset(0, 4))]),
      child: SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.all(30), child: Row(mainAxisSize: MainAxisSize.min, children: _gameState!.board.map((p) => _tile(p, small: true)).toList())));

  Widget _controlsUI(List<DominoPiece> hand, bool t) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      decoration: BoxDecoration(color: t ? const Color(0xFFE8F5E9) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(40)), border: const Border(top: BorderSide(width: 4))),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(t ? 'دورك يا بطل 🔥' : 'انتظر دورك...', style: GoogleFonts.lalezar(fontSize: 22, color: t ? Colors.green[800] : Colors.grey)),
          if (!_vsAI) Text('كود: ${_roomId}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))
        ]),
        const SizedBox(height: 15),
        // Wrap for pieces
        Wrap(
          spacing: 2,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: hand.map((p) => GestureDetector(onTap: t ? () => _onPieceTap(p) : null, child: _tile(p))).toList(),
        ),
        const SizedBox(height: 20),
        if (t) ElevatedButton(onPressed: () => _gameService.passTurn(_roomId!, _gameState!), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[700], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(width: 2))), child: Text('تمرير الدور', style: GoogleFonts.lalezar(color: Colors.white, fontSize: 18))),
      ]),
    );
  }

  void _onPieceTap(DominoPiece p) {
    if (_gameState?.board.isEmpty ?? true) {
      _move(p, true);
    } else {
      _showMoveChoice(p);
    }
  }

  void _showMoveChoice(DominoPiece p) {
    final v1 = _gameState!.board.first.side1;
    final v2 = _gameState!.board.last.side2;
    bool canStart = p.side1 == v1 || p.side2 == v1;
    bool canEnd = p.side1 == v2 || p.side2 == v2;

    if (!canStart && !canEnd) {
      _showError('هذه القطعة لا تطابق أي طرف!');
      return;
    }

    if (canStart && canEnd) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(width: 3)),
                  title: Text('وين تخلي القطعة؟', textAlign: TextAlign.center, style: GoogleFonts.lalezar()),
                  actions: [
                    _dialogBtn('البداية', () { Navigator.pop(context); _move(p, false); }),
                    _dialogBtn('النهاية', () { Navigator.pop(context); _move(p, true); }),
                  ]));
    } else {
      _move(p, canEnd);
    }
  }

  Widget _dialogBtn(String t, VoidCallback o) => ElevatedButton(onPressed: o, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A2E)), child: Text(t, style: GoogleFonts.lalezar(color: Colors.white)));

  void _move(DominoPiece p, bool e) async {
    try {
      await _gameService.makeMove(_roomId!, p, e, _gameState!);
    } catch (err) {
      _showError('خطأ تقني: $err');
    }
  }

  Widget _tile(DominoPiece p, {bool small = false}) {
    final size = small ? 35.0 : 52.0;
    return Container(
      margin: const EdgeInsets.all(3), width: size, height: size * 2,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(width: small ? 2 : 3), boxShadow: [BoxShadow(color: const Color(0xFF1A1A1A).withOpacity(0.5), offset: const Offset(2, 2))]),
      child: Column(children: [
        Expanded(child: _dots(p.side1, small)),
        Container(height: small ? 2 : 3, color: const Color(0xFF1A1A1A)),
        Expanded(child: _dots(p.side2, small))
      ]),
    );
  }

  Widget _dots(int v, bool s) => v == 0 ? const SizedBox() : Center(child: _DotsRenderer(value: v, small: s));

  List<DominoPiece> _getMyHand(String r) {
    if (r == 'player1') return _gameState!.player1Hand;
    if (r == 'player2') return _gameState!.player2Hand;
    if (r == 'player3') return _gameState!.player3Hand;
    return _gameState!.player4Hand;
  }

  String _getPartnerRole(String r) {
    if (r == 'player1') return 'player3';
    if (r == 'player2') return 'player4';
    if (r == 'player3') return 'player1';
    return 'player2';
  }

  String _getLeftRole(String r) {
    if (r == 'player1') return 'player2';
    if (r == 'player2') return 'player3';
    if (r == 'player3') return 'player4';
    return 'player1';
  }

  String _getRightRole(String r) {
    if (r == 'player1') return 'player4';
    if (r == 'player2') return 'player1';
    if (r == 'player3') return 'player2';
    return 'player3';
  }

  String _getPartnerName(String r) => _getName(_getPartnerRole(r));
  String _getLeftOpponentName(String r) => _getName(_getLeftRole(r));
  String _getRightOpponentName(String r) => _getName(_getRightRole(r));
  int _getPartnerHandCount(String r) => _getCount(_getPartnerRole(r));
  int _getLeftOpponentHandCount(String r) => _getCount(_getLeftRole(r));
  int _getRightOpponentHandCount(String r) => _getCount(_getRightRole(r));
  String _getName(String r) {
    if (r == 'player1') return _gameState!.player1Id;
    if (r == 'player2') return _gameState!.player2Id ?? 'لاعب 2';
    if (r == 'player3') return _gameState!.player3Id ?? 'لاعب 3';
    return _gameState!.player4Id ?? 'لاعب 4';
  }

  int _getCount(String r) {
    if (r == 'player1') return _gameState!.player1Hand.length;
    if (r == 'player2') return _gameState!.player2Hand.length;
    if (r == 'player3') return _gameState!.player3Hand.length;
    return _gameState!.player4Hand.length;
  }

  void _showError(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m, style: GoogleFonts.lalezar()), backgroundColor: Colors.red));
}

class _DotsRenderer extends StatelessWidget {
  final int value;
  final bool small;
  const _DotsRenderer({required this.value, required this.small});
  @override
  Widget build(BuildContext context) {
    final dotSize = small ? 4.0 : 5.8;
    final patterns = [[4], [0, 8], [0, 4, 8], [0, 2, 6, 8], [0, 2, 4, 6, 8], [0, 3, 6, 2, 5, 8]];
    final pattern = patterns[value - 1];
    return SizedBox(width: small ? 24 : 36, height: small ? 24 : 36,
        child: GridView.builder(physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
            itemCount: 9, itemBuilder: (context, index) => pattern.contains(index) ? Center(child: Container(width: dotSize, height: dotSize, decoration: const BoxDecoration(color: Color(0xFF1A1A1A), shape: BoxShape.circle))) : const SizedBox()));
  }
}
