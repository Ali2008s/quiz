import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/services/auth_service.dart';
import '../data/services/domino_game_service.dart';
import '../data/services/audio_service.dart';
import '../data/services/point_service.dart';
import '../data/services/ad_manager_service.dart';
import 'game_win_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  RealtimeChannel? _presence;
  Timer? _dcTimer;

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
    AudioService.pauseBgm();
  }

  @override
  void dispose() {
    if (_roomId != null &&
        _gameState != null &&
        _gameState!.player1Id == _playerName) {
      _gameService.deleteRoom(_roomId!);
    }
    _gameSub?.cancel();
    _pollTimer?.cancel();
    _dcTimer?.cancel();
    if (_presence != null) {
      Supabase.instance.client.removeChannel(_presence!);
    }
    _joinController.dispose();
    AudioService.resumeBgm();
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
              color: Color(0xFF1E2A38),
              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20)]),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 50,
                    height: 6,
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 20),
                Text(_vsAI ? 'إعدادات اللعب الفردي' : 'إعدادات اللعب الجماعي',
                    style:
                        GoogleFonts.lalezar(fontSize: 32, color: Colors.white)),
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
                              () =>
                                  setModalState(() => _difficulty = 'medium'))),
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
                    const Color(0xFF4CAF50), () {
                  AudioService.playClick();
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
                  GoogleFonts.lalezar(fontSize: 18, color: Colors.white70))));

  Widget _setupCard(String t, IconData i, bool s, VoidCallback o) {
    return GestureDetector(
      onTap: () {
        AudioService.playClick();
        o();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: s
              ? const Color(0xFF4CAF50).withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: s ? const Color(0xFF4CAF50) : Colors.white24, width: 2),
          boxShadow: s
              ? const [
                  BoxShadow(
                      color: Color(0xFF4CAF50),
                      blurRadius: 10,
                      spreadRadius: -5)
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(i,
                color: s ? const Color(0xFF4CAF50) : Colors.white70, size: 28),
            const SizedBox(height: 8),
            Text(t,
                style: GoogleFonts.lalezar(
                    color: s ? Colors.white : Colors.white70, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(String t, IconData i, Color c, VoidCallback o) {
    return GestureDetector(
      onTap: () {
        AudioService.playClick();
        o();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black45, offset: Offset(0, 4), blurRadius: 6)
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

  void _setupPresence(String id) {
    if (_presence != null) {
      Supabase.instance.client.removeChannel(_presence!);
    }
    _presence = Supabase.instance.client.channel('domino_pr_$id');
    _presence!.onPresenceSync((payload) {
      if (!mounted || _gameState == null || _vsAI) return;

      bool isFull = true;
      if (_gameState!.maxPlayers >= 2 && _gameState!.player2Id == null)
        isFull = false;
      if (_gameState!.maxPlayers >= 3 && _gameState!.player3Id == null)
        isFull = false;
      if (_gameState!.maxPlayers >= 4 && _gameState!.player4Id == null)
        isFull = false;

      if (!isFull) return;

      final List<dynamic> stateList = _presence!.presenceState();
      final Set<String> users =
          stateList.map((p) => p.payload['u'].toString()).toSet();

      List<String> expected = [_gameState!.player1Id];
      if (_gameState!.player2Id != null &&
          !_gameState!.player2Id!.contains('ذكاء'))
        expected.add(_gameState!.player2Id!);
      if (_gameState!.player3Id != null &&
          !_gameState!.player3Id!.contains('ذكاء'))
        expected.add(_gameState!.player3Id!);
      if (_gameState!.player4Id != null &&
          !_gameState!.player4Id!.contains('ذكاء'))
        expected.add(_gameState!.player4Id!);

      bool missing = false;
      for (var p in expected) {
        if (p != _playerName && !users.contains(p)) missing = true;
      }

      if (missing) {
        if (!(_dcTimer?.isActive ?? false)) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('تم فصل اتصال الخصم! الانتظار 10 ثواني...',
                  style: GoogleFonts.lalezar()),
              backgroundColor: Colors.orange));
          _dcTimer = Timer(const Duration(seconds: 10), () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('تم إغلاق الغرفة لعدم عودة الخصم.',
                      style: GoogleFonts.lalezar()),
                  backgroundColor: Colors.red));
              _gameService.deleteRoom(id);
            }
          });
        }
      } else {
        if (_dcTimer?.isActive ?? false) {
          _dcTimer?.cancel();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('عاد الخصم للعب! ✅', style: GoogleFonts.lalezar()),
              backgroundColor: Colors.green));
        }
      }
    }).subscribe((status, [e]) async {
      if (status == 'SUBSCRIBED' && _playerName != null)
        await _presence!.track({'u': _playerName});
    });
  }

  void _listenToGame(String id) {
    _gameSub?.cancel();
    _pollTimer?.cancel();
    _setupPresence(id);

    // Web Fallback/Sync mechanism - polls every 1.5s and detects board changes too
    _pollTimer =
        Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
      if (_roomId == null) return;
      final state = await _gameService.getGameData(_roomId!);
      if (state != null) {
        bool needsUpdate = state.currentTurn != _gameState?.currentTurn ||
            state.player2Id != _gameState?.player2Id ||
            state.player3Id != _gameState?.player3Id ||
            state.player4Id != _gameState?.player4Id ||
            state.winner != _gameState?.winner ||
            state.board.length != _gameState?.board.length;

        if (needsUpdate) {
          if (mounted) setState(() => _gameState = state);
          if (state.winner != null)
            _handleWinner(state.winner!);
          else
            _checkAIMove(state);
        }
      } else {
        if (mounted && _roomId != null && _gameState != null) {
          _pollTimer?.cancel();
          _showRoomDeletedDialog();
        }
      }
    });

    _gameSub = _gameService.gameStream(id).listen((state) {
      if (!mounted) return;
      if (state == null) {
        if (_roomId != null && _gameState != null) {
          _pollTimer?.cancel();
          _showRoomDeletedDialog();
        }
        return;
      }
      setState(() {
        _gameState = state;
        _isCreating = false;
        _isJoining = false;
      });
      if (state.winner != null) _handleWinner(state.winner!);
      _checkAIMove(state);
    }, onError: (e) {
      debugPrint('Domino Game Stream Error: $e');
    });
  }

  void _checkAIMove(DominoGameState state) async {
    if (state.winner != null) return;
    final turn = state.currentTurn;
    String? currentPId;
    if (turn == 'player2')
      currentPId = state.player2Id;
    else if (turn == 'player3')
      currentPId = state.player3Id;
    else if (turn == 'player4') currentPId = state.player4Id;

    bool isAI = currentPId != null &&
        (currentPId == 'ذكاء اصطناعي 🤖' || currentPId.contains('ذكاء'));
    if (isAI) {
      await Future.delayed(const Duration(milliseconds: 1000));
      _performAIMove(state);
    }
  }

  void _performAIMove(DominoGameState state) {
    final turn = state.currentTurn;
    List<DominoPiece> hand = [];
    if (turn == 'player2')
      hand = state.player2Hand;
    else if (turn == 'player3')
      hand = state.player3Hand;
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

    if (move != null)
      _gameService.makeMove(state.roomId, move, atEnd, state);
    else
      _gameService.passTurn(state.roomId, state);
  }

  void _handleWinner(String winner) {
    if (winner != 'ذكاء اصطناعي 🤖' &&
        winner != 'الخصم' &&
        !winner.contains('الفريق الثاني')) {
      PointService.addPoints(5);
    }
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => GameWinScreen(
                  winnerName: winner,
                  pointsEarned: 5,
                  onPlayAgain: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const DominoGameScreen())),
                  onExit: () =>
                      Navigator.popUntil(context, (route) => route.isFirst),
                )));
  }

  void _showRoomDeletedDialog() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF1E2A38),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Colors.white24, width: 2)),
                title: Text('تنبيه!',
                    style: GoogleFonts.lalezar(color: Colors.redAccent)),
                content: Text('انتهت الجلسة أو تم حذف الغرفة.',
                    style: GoogleFonts.lalezar(color: Colors.white)),
                actions: [
                  TextButton(
                      onPressed: () {
                        AdManagerService.showInterstitial(onAdClosed: () {
                          Navigator.popUntil(context, (route) => route.isFirst);
                        });
                      },
                      child: Text('تمام',
                          style: GoogleFonts.lalezar(
                              color: Colors.orange, fontSize: 18)))
                ]));
  }

  @override
  Widget build(BuildContext context) {
    bool isFull = true;
    if (_gameState != null) {
      if (_gameState!.maxPlayers >= 2 && _gameState!.player2Id == null)
        isFull = false;
      if (_gameState!.maxPlayers >= 3 && _gameState!.player3Id == null)
        isFull = false;
      if (_gameState!.maxPlayers >= 4 && _gameState!.player4Id == null)
        isFull = false;
    }
    if (_roomId != null && _gameState != null && !isFull)
      return _waitingScreen();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: (_roomId == null || _gameState == null)
            ? _buildMenu()
            : _buildGame(),
      ),
    );
  }

  Widget _waitingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            _header(
                'بانتظار المنافسين...', Icons.people_outline, Colors.orange),
            const SizedBox(height: 30),
            Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(32),
                    border:
                        Border.all(color: const Color(0xFF1A1A1A), width: 2),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          spreadRadius: 2)
                    ]),
                child: Column(children: [
                  if (!_vsAI) ...[
                    Text('كود الغرفة: ${_roomId}',
                        style: GoogleFonts.lalezar(
                            fontSize: 32, color: const Color(0xFF1A1A2E))),
                    const SizedBox(height: 10),
                  ],
                  Text('بانتظار اكمال العدد (${_gameState!.maxPlayers})',
                      style: GoogleFonts.lalezar(
                          color: Colors.grey.shade700, fontSize: 18)),
                  const SizedBox(height: 30),
                  const CircularProgressIndicator(color: Colors.orange)
                ])),
            const SizedBox(height: 40),
            _actionBtn('إلغاء و خروج', Icons.close, Colors.redAccent,
                () => Navigator.pop(context)),
          ]),
        ),
      ),
    );
  }

  Widget _buildMenu() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          const SizedBox(height: 30),
          _header('لعبة الدومينو', Icons.extension_rounded,
              const Color(0xFF1A1A2E)),
          const SizedBox(height: 40),
          _menuBox('اللعب الجماعي', 'أدخل الغرفة ونافس أساطير الدومينو',
              const Color(0xFF64B5F6), Icons.public, () {
            setState(() => _vsAI = false);
            _showGameSetup();
          }),
          const SizedBox(height: 20),
          _menuBox('اللعب الفردي', 'تحدَّ الذكاء الاصطناعي وحدد الصعوبة',
              const Color(0xFFFF8A65), Icons.android_rounded, () {
            setState(() {
              _vsAI = true;
              _playerCount = 2;
            });
            _showGameSetup();
          }),
          const SizedBox(height: 40),
          _joinCardUI(),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _menuBox(String t, String s, Color c, IconData i, VoidCallback o) {
    return GestureDetector(
      onTap: () {
        AudioService.playClick();
        o();
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.grey.shade300, width: 2),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12, offset: Offset(0, 8), blurRadius: 10)
            ]),
        child: Row(children: [
          Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
              child: Icon(i, color: c, size: 30)),
          const SizedBox(width: 20),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(t,
                    style: GoogleFonts.lalezar(
                        fontSize: 24,
                        color: Colors.white,
                        shadows: const [
                          Shadow(
                              color: Colors.black45,
                              offset: Offset(0, 1),
                              blurRadius: 2)
                        ])),
                Text(s,
                    style: GoogleFonts.lalezar(
                        fontSize: 14, color: Colors.white.withOpacity(0.9)))
              ]))
        ]),
      ),
    );
  }

  Widget _joinCardUI() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white24, width: 2)),
      child: Row(children: [
        Expanded(
            child: TextField(
                controller: _joinController,
                textAlign: TextAlign.center,
                style: GoogleFonts.lalezar(fontSize: 20, color: Colors.white),
                decoration: const InputDecoration(
                    hintText: 'كود الغرفة',
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none))),
        ElevatedButton(
            onPressed: _joinRoom,
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                elevation: 5,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15))),
            child:
                Text('دخول', style: GoogleFonts.lalezar(color: Colors.white))),
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
        Icon(i, color: c, size: 40, shadows: const [
          Shadow(color: Colors.black45, offset: Offset(0, 2), blurRadius: 4)
        ]),
        const SizedBox(width: 15),
        Text(t,
            style: GoogleFonts.lalezar(
                fontSize: 36,
                color: Colors.white,
                shadows: const [
                  Shadow(
                      color: Colors.black45,
                      offset: Offset(0, 2),
                      blurRadius: 4)
                ]))
      ]);

  Widget _buildGame() {
    String myRole = _getMyRole();

    final myHand = _getMyHand(myRole);
    bool isMyTurn = _gameState!.currentTurn == myRole;

    String topRole = _gameState!.maxPlayers == 2
        ? _getLeftRole(myRole)
        : _getPartnerRole(myRole);

    return Column(children: [
      _topArea(topRole),
      Expanded(
          child: Row(children: [
        if (_gameState!.maxPlayers == 4) _sideArea(_getLeftRole(myRole)),
        Expanded(child: _boardUI()),
        if (_gameState!.maxPlayers == 4) _sideArea(_getRightRole(myRole)),
      ])),
      _controlsUI(myHand, isMyTurn),
    ]);
  }

  Widget _topArea(String role) {
    int count = _getCount(role);
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 5),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _playerBadge(_getName(role), count,
            isTurn: _gameState!.currentTurn == role),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 2,
          runSpacing: 4,
          children:
              List.generate(count, (index) => _hiddenTile(vertical: true)),
        )
      ]),
    );
  }

  Widget _sideArea(String role) {
    int count = _getCount(role);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        _playerBadgeSide(_getName(role), count,
            isTurn: _gameState!.currentTurn == role),
        const SizedBox(height: 12),
        Column(
          mainAxisSize: MainAxisSize.min,
          children:
              List.generate(count, (index) => _hiddenTile(vertical: false)),
        )
      ]),
    );
  }

  Widget _hiddenTile({bool vertical = true}) {
    final w = vertical ? 28.0 : 42.0;
    final h = vertical ? 42.0 : 28.0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[400]!, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black26, offset: Offset(1, 2), blurRadius: 3)
        ],
      ),
      child: Center(
        child: Container(
          width: vertical ? 12.0 : 18.0,
          height: vertical ? 18.0 : 12.0,
          decoration: BoxDecoration(
              color: Colors.grey[300],
              border: Border.all(color: Colors.grey[400]!, width: 1),
              borderRadius: BorderRadius.circular(3)),
        ),
      ),
    );
  }

  Widget _playerBadge(String n, int c, {bool isTurn = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(top: 10, bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: isTurn
            ? const LinearGradient(
                colors: [Color(0xFFFFB75E), Color(0xFFED8F03)])
            : LinearGradient(colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05)
              ]),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
            color: isTurn ? Colors.amberAccent : Colors.white24,
            width: isTurn ? 2 : 1),
        boxShadow: isTurn
            ? [
                const BoxShadow(
                    color: Colors.amber, blurRadius: 15, spreadRadius: 2)
              ]
            : [],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(n.contains('ذكاء') ? Icons.android : Icons.person,
            size: 22, color: isTurn ? Colors.white : Colors.white70),
        const SizedBox(width: 8),
        Text(n,
            style: GoogleFonts.lalezar(
                fontSize: 16, color: isTurn ? Colors.white : Colors.white70)),
        if (isTurn)
          const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.local_fire_department,
                  color: Colors.white, size: 20)),
        const SizedBox(width: 15),
        _countB(c, isTurn)
      ]),
    );
  }

  Widget _playerBadgeSide(String n, int c, {bool isTurn = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        gradient: isTurn
            ? const LinearGradient(
                colors: [Color(0xFFFFB75E), Color(0xFFED8F03)])
            : LinearGradient(colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05)
              ]),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
            color: isTurn ? Colors.amberAccent : Colors.white24,
            width: isTurn ? 2 : 1),
        boxShadow: isTurn
            ? [
                const BoxShadow(
                    color: Colors.amber, blurRadius: 15, spreadRadius: 2)
              ]
            : [],
      ),
      child: RotatedBox(
          quarterTurns: 1,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (isTurn)
              const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.local_fire_department,
                      color: Colors.white, size: 18)),
            Icon(n.contains('ذكاء') ? Icons.android : Icons.person,
                size: 18, color: isTurn ? Colors.white : Colors.white70),
            const SizedBox(width: 6),
            Text(n,
                style: GoogleFonts.lalezar(
                    fontSize: 14,
                    color: isTurn ? Colors.white : Colors.white70)),
            const SizedBox(width: 10),
            _countB(c, isTurn)
          ])),
    );
  }

  Widget _countB(int c, bool isTurn) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: isTurn ? Colors.white24 : Colors.black45,
          borderRadius: BorderRadius.circular(12)),
      child: Text('$c',
          style: const TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)));

  Widget _boardUI() {
    bool isMyTurn = _gameState!.currentTurn == _getMyRole();
    bool canPlay = isMyTurn && _gameState!.winner == null;

    return Container(
        margin: const EdgeInsets.all(12),
        width: double.infinity,
        decoration: BoxDecoration(
            color: const Color(0xFF0F2027),
            image: DecorationImage(
              image: const NetworkImage(
                  'https://www.transparenttextures.com/patterns/dark-matter.png'),
              opacity: 0.1,
              repeat: ImageRepeat.repeat,
            ),
            borderRadius: BorderRadius.circular(35),
            border: Border.all(color: Colors.white10, width: 2),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5),
              const BoxShadow(
                  color: Colors.black26, offset: Offset(0, 10), blurRadius: 20),
            ]),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Elegant Watermark
            Text(
              'MAKHM AKHA',
              style: GoogleFonts.lalezar(
                fontSize: 100,
                color: Colors.white.withOpacity(0.03),
                letterSpacing: 10,
              ),
            ),
            Positioned.fill(
              child: InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(1200),
                minScale: 0.2,
                maxScale: 2.5,
                constrained: false,
                child: Padding(
                  padding: const EdgeInsets.all(200),
                  child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: _buildBoardItems(canPlay)),
                ),
              ),
            ),
          ],
        ));
  }

  List<Widget> _buildBoardItems(bool canPlay) {
    if (_gameState == null) return [];
    List<Widget> items = [];
    if (_gameState!.board.isEmpty) {
      if (canPlay) items.add(_buildTarget(true));
    } else {
      if (canPlay) items.add(_buildTarget(false));
      for (var p in _gameState!.board) {
        items.add(_AnimatedPiece(piece: p, vertical: p.side1 == p.side2));
      }
      if (canPlay) items.add(_buildTarget(true));
    }
    return items;
  }

  Widget _buildTarget(bool isEnd) {
    return DragTarget<DominoPiece>(
        onWillAccept: (piece) {
          if (piece == null) return false;
          if (_gameState!.board.isEmpty) return true;
          int targetVal = isEnd
              ? _gameState!.board.last.side2
              : _gameState!.board.first.side1;
          return piece.side1 == targetVal || piece.side2 == targetVal;
        },
        onAccept: (piece) => _onDropPiece(piece, isEnd),
        builder: (context, candidateData, rejectedData) {
          bool isHovered = candidateData.isNotEmpty;
          // Use a Stack with AnimatedOpacity to avoid circle+borderRadius tween crash
          return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: isHovered ? 85 : 70,
              height: isHovered ? 85 : 70,
              decoration: BoxDecoration(
                // No borderRadius here since shape is circle
                color: isHovered
                    ? Colors.amber.withOpacity(0.3)
                    : Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(
                    color: isHovered ? Colors.amberAccent : Colors.white24,
                    width: isHovered ? 3 : 1.5,
                    style: BorderStyle.solid),
                boxShadow: isHovered
                    ? [
                        BoxShadow(
                            color: Colors.amberAccent.withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 5)
                      ]
                    : [],
              ),
              child: Center(
                child: Icon(Icons.add_rounded,
                    color: isHovered ? Colors.amberAccent : Colors.white30,
                    size: isHovered ? 40 : 30),
              ));
        });
  }

  Widget _controlsUI(List<DominoPiece> hand, bool t) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
          color: const Color(0xFF1C2833),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 25, spreadRadius: 5)
          ],
          border: Border(
              top: BorderSide(
                  color: t ? Colors.amberAccent : Colors.white12, width: 3))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(t ? 'دورك يا بطل 🔥' : 'انتظر دورك...',
                style: GoogleFonts.lalezar(
                    fontSize: 18, color: t ? Colors.amber : Colors.grey)),
            if (!_vsAI)
              Text('كود الغرفة: ${_roomId}',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.bold))
          ]),
          const SizedBox(height: 15),
          SizedBox(
            height: 110,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Row(
                children: hand
                    .map((p) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: t
                              ? Draggable<DominoPiece>(
                                  data: p,
                                  feedback: Transform.scale(
                                    scale: 1.2,
                                    child: _dominoTile(p,
                                        isInteractive: true, vertical: true),
                                  ),
                                  childWhenDragging: Opacity(
                                      opacity: 0.3,
                                      child: _dominoTile(p,
                                          isInteractive: false,
                                          vertical: true)),
                                  onDragStarted: () => AudioService.playClick(),
                                  child: MouseRegion(
                                      cursor: SystemMouseCursors.grab,
                                      child: _dominoTile(p,
                                          isInteractive: true, vertical: true)))
                              : _dominoTile(p,
                                  isInteractive: false, vertical: true),
                        ))
                    .toList(),
              ),
            ),
          ),
          if (t) ...[
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: () => _gameService.passTurn(_roomId!, _gameState!),
              icon: const Icon(Icons.skip_next, color: Colors.white),
              label: Text('تمرير الدور',
                  style:
                      GoogleFonts.lalezar(color: Colors.white, fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C),
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
                elevation: 5,
              ),
            )
          ],
        ],
      ),
    );
  }

  void _onDropPiece(DominoPiece piece, bool isEnd) {
    AudioService.playClick();
    _move(piece, isEnd);
  }

  void _move(DominoPiece p, bool e) async {
    try {
      if (_roomId != null && _gameState != null) {
        await _gameService.makeMove(_roomId!, p, e, _gameState!);
      }
    } catch (err) {
      _showError('خطأ تقني: $err');
    }
  }

  List<DominoPiece> _getMyHand(String r) {
    if (_gameState == null) return [];
    if (r == 'player1') return _gameState!.player1Hand;
    if (r == 'player2') return _gameState!.player2Hand;
    if (r == 'player3') return _gameState!.player3Hand;
    return _gameState!.player4Hand;
  }

  String _getMyRole() {
    final myName = _playerName?.trim();
    if (myName == _gameState?.player2Id?.trim()) return 'player2';
    if (myName == _gameState?.player3Id?.trim()) return 'player3';
    if (myName == _gameState?.player4Id?.trim()) return 'player4';
    return 'player1';
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

  String _getName(String r) {
    if (_gameState == null) return '...';
    if (r == 'player1') return _gameState!.player1Id;
    if (r == 'player2') return _gameState!.player2Id ?? 'لاعب 2';
    if (r == 'player3') return _gameState!.player3Id ?? 'لاعب 3';
    return _gameState!.player4Id ?? 'لاعب 4';
  }

  int _getCount(String r) {
    if (_gameState == null) return 0;
    if (r == 'player1') return _gameState!.player1Hand.length;
    if (r == 'player2') return _gameState!.player2Hand.length;
    if (r == 'player3') return _gameState!.player3Hand.length;
    return _gameState!.player4Hand.length;
  }

  void _showError(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(m, style: GoogleFonts.lalezar()),
          backgroundColor: Colors.red));
    }
  }
}

// --- Premium Tile UI (Accessible to Animations) ---
Widget _dominoTile(DominoPiece p,
    {bool small = false, bool isInteractive = false, bool vertical = false}) {
  final size = small ? 42.0 : 54.0;
  final double w = vertical ? size : size * 2;
  final double h = vertical ? size * 2 : size;

  return AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: const Color(0xFFF9F9FB),
      borderRadius: BorderRadius.circular(6),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          offset: const Offset(2, 4),
          blurRadius: 4,
        ),
        BoxShadow(
          color: Colors.white.withOpacity(0.8),
          offset: const Offset(-1, -1),
          blurRadius: 2,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          offset: const Offset(1, 1),
          blurRadius: 2,
        ),
      ],
      border: Border.all(
          color: isInteractive ? Colors.amberAccent : Colors.black12,
          width: isInteractive ? 3 : 1),
    ),
    child: Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.9),
                Colors.grey[200]!.withOpacity(0.9),
              ],
            ),
          ),
        ),
        vertical
            ? Column(children: [
                Expanded(child: _dotsEntry(p.side1, small)),
                Container(
                    height: 2,
                    color: Colors.black26,
                    margin: const EdgeInsets.symmetric(horizontal: 6)),
                Expanded(child: _dotsEntry(p.side2, small))
              ])
            : Row(children: [
                Expanded(child: _dotsEntry(p.side1, small)),
                Container(
                    width: 2,
                    color: Colors.black26,
                    margin: const EdgeInsets.symmetric(vertical: 6)),
                Expanded(child: _dotsEntry(p.side2, small))
              ]),
      ],
    ),
  );
}

Widget _dotsEntry(int v, bool s) => v == 0
    ? const SizedBox()
    : Center(child: _DotsRenderer(value: v, small: s));

// --- Animated Piece for Board ---
class _AnimatedPiece extends StatefulWidget {
  final DominoPiece piece;
  final bool vertical;
  const _AnimatedPiece({required this.piece, this.vertical = false});

  @override
  State<_AnimatedPiece> createState() => _AnimatedPieceState();
}

class _AnimatedPieceState extends State<_AnimatedPiece>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _scaleAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.bounceOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: _dominoTile(widget.piece, small: true, vertical: widget.vertical),
    );
  }
}

class _DotsRenderer extends StatelessWidget {
  final int value;
  final bool small;
  const _DotsRenderer({required this.value, required this.small});
  @override
  Widget build(BuildContext context) {
    final dotSize = small ? 6.0 : 8.5;
    final patterns = [
      [4],
      [0, 8],
      [0, 4, 8],
      [0, 2, 6, 8],
      [0, 2, 4, 6, 8],
      [0, 3, 6, 2, 5, 8]
    ];
    if (value == 0) return const SizedBox();
    final pattern = patterns[value - 1];
    return SizedBox(
        width: small ? 30 : 45,
        height: small ? 30 : 45,
        child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3),
            itemCount: 9,
            itemBuilder: (context, index) => pattern.contains(index)
                ? Center(
                    child: Container(
                        width: dotSize,
                        height: dotSize,
                        decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.95),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.white.withOpacity(0.4),
                                  offset: const Offset(-1, -1),
                                  blurRadius: 1),
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.8),
                                  offset: const Offset(1, 1),
                                  blurRadius: 1),
                            ])))
                : const SizedBox()));
  }
}
