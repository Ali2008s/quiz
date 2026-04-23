import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/services/auth_service.dart';
import '../data/services/xo_game_service.dart';
import '../data/services/bluetooth_xo_service.dart';
import '../data/services/audio_service.dart';
import '../data/services/point_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/services/ad_manager_service.dart';
import 'game_win_screen.dart';

// ─── ألوان ثيم XO ────────────────────────────────────────────────────
const Color _kBg = Color(0xFF0D0D1A);
const Color _kBg2 = Color(0xFF1A0A2E);
const Color _kPurple = Color(0xFF6C3FD1);
const Color _kCyan = Color(0xFF00D4FF);
const Color _kPink = Color(0xFFFF3CAC);
const Color _kGold = Color(0xFFFFD700);
const Color _kX = Color(0xFF00D4FF);
const Color _kO = Color(0xFFFF3CAC);

class XOGameScreen extends StatefulWidget {
  const XOGameScreen({super.key});

  @override
  State<XOGameScreen> createState() => _XOGameScreenState();
}

class _XOGameScreenState extends State<XOGameScreen>
    with TickerProviderStateMixin {
  final XOGameService _gameService = XOGameService();
  final BluetoothXOService _btService = BluetoothXOService();

  String? _roomId;
  bool _isCreating = false;
  bool _isJoining = false;
  String? _playerName;
  String? _playerAvatar;
  StreamSubscription<XOGameState?>? _gameSub;
  StreamSubscription<LocalXOState?>? _btGameSub;
  XOGameState? _gameState;
  LocalXOState? _btGameState;
  final TextEditingController _joinController = TextEditingController();
  bool _isAutoJoining = false;
  RealtimeChannel? _presence;
  Timer? _dcTimer;
  Timer? _pollTimer;

  // وضع الاتصال
  bool _isBluetoothMode = false;

  // أنيميشن الخلايا
  late List<AnimationController> _cellControllers;
  late List<Animation<double>> _cellScaleAnims;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _winLineCtrl;
  late AnimationController _glowCtrl;

  List<int>? _winLine;

  void _autoJoin() async {
    if (_playerName == null) return;
    setState(() => _isAutoJoining = true);
    try {
      final roomId = await _gameService.findRandomRoom(_playerName!);
      if (roomId != null) {
        _listenToGame(roomId);
        setState(() => _roomId = roomId);
      } else {
        final id = await _gameService.createRoom(_playerName!);
        _listenToGame(id);
        setState(() => _roomId = id);
      }
    } catch (e) {
      _showError('خطأ في الانضمام التلقائي');
    } finally {
      if (mounted) setState(() => _isAutoJoining = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _initPlayer();

    // أنيميشن خلايا اللعب
    _cellControllers = List.generate(
      9,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );
    _cellScaleAnims = _cellControllers
        .map((c) => Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: c, curve: Curves.elasticOut),
            ))
        .toList();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _winLineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  Future<void> _initPlayer() async {
    final name = await AuthService.getUserName();
    final avatar = await AuthService.getUserAvatar();
    if (mounted) {
      setState(() {
        _playerName = name;
        _playerAvatar = avatar;
      });
    }
  }

  @override
  void dispose() {
    if (_roomId != null &&
        _gameState != null &&
        _gameState!.player1Id == _playerName) {
      _gameService.deleteRoom(_roomId!);
    }
    if (_roomId != null &&
        _btGameState != null &&
        _btGameState!.player1Id == _playerName) {
      _btService.deleteRoom(_roomId!);
    }
    _gameSub?.cancel();
    _btGameSub?.cancel();
    _dcTimer?.cancel();
    _pollTimer?.cancel();
    if (_presence != null) {
      Supabase.instance.client.removeChannel(_presence!);
    }
    _joinController.dispose();
    for (var c in _cellControllers) c.dispose();
    _pulseCtrl.dispose();
    _winLineCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  // ─── إنشاء الغرفة ─────────────────────────────────────────────────
  void _createRoom() async {
    if (_playerName == null) return;
    setState(() => _isCreating = true);
    try {
      String id;
      if (_isBluetoothMode) {
        id = await _btService.createLocalRoom(_playerName!);
        _listenToBtGame(id);
      } else {
        id = await _gameService.createRoom(_playerName!);
        _listenToGame(id);
      }
      setState(() => _roomId = id);
    } catch (e) {
      if (mounted) setState(() => _isCreating = false);
      _showError('خطأ في إنشاء الغرفة');
    }
  }

  // ─── الانضمام لغرفة ───────────────────────────────────────────────
  void _joinRoom() async {
    final id = _joinController.text.trim();
    if (id.isEmpty || _playerName == null) return;
    setState(() => _isJoining = true);
    try {
      if (_isBluetoothMode) {
        await _btService.joinLocalRoom(id, _playerName!);
        _listenToBtGame(id);
      } else {
        await _gameService.joinRoom(id, _playerName!);
        _listenToGame(id);
      }
      setState(() => _roomId = id);
    } catch (e) {
      if (mounted) setState(() => _isJoining = false);
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ─── مجرى الإنترنت ────────────────────────────────────────────────
  void _setupPresence(String id) {
    if (_presence != null) {
      Supabase.instance.client.removeChannel(_presence!);
    }
    _presence = Supabase.instance.client.channel('xo_pr_$id');
    _presence!.onPresenceSync((payload) {
      if (!mounted || _gameState == null) return;
      final List<dynamic> pState = _presence!.presenceState();
      final users = pState.map((p) => p.payload['u'].toString()).toSet();
      if (_gameState!.player2Id == null && users.length > 1) {
        _gameService.getRoom(id).then((state) {
          if (mounted && state != null && state.player2Id != null) {
            setState(() => _gameState = state);
          }
        });
      }
      if (_gameState!.player2Id == null) return;
      String opponent = _playerName == _gameState!.player1Id
          ? _gameState!.player2Id!
          : _gameState!.player1Id;
      if (!users.contains(opponent)) {
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
    if (!_isBluetoothMode) _setupPresence(id);

    _pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_roomId == null) return;
      final state = await _gameService.getRoom(_roomId!);
      if (state != null) {
        bool needsUpdate = state.currentTurn != _gameState?.currentTurn ||
            state.player2Id != _gameState?.player2Id ||
            state.winner != _gameState?.winner;
        if (!needsUpdate && _gameState != null) {
          for (int i = 0; i < 9; i++) {
            if (state.board[i] != _gameState!.board[i]) {
              needsUpdate = true;
              break;
            }
          }
        }
        if (needsUpdate) {
          if (mounted) setState(() => _gameState = state);
          if (state.winner != null) _showWinnerDialog(state.winner!);
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
        if (_roomId != null) _showRoomDeletedDialog();
        return;
      }

      // أنيميت الخلية الجديدة
      for (int i = 0; i < 9; i++) {
        if ((_gameState?.board[i] ?? '') == '' && state.board[i] != '') {
          _cellControllers[i].forward(from: 0);
        }
      }

      setState(() {
        _gameState = state;
        _isCreating = false;
        _isJoining = false;
      });

      if (state.winner != null) {
        _winLine = _findWinLine(state.board);
        _winLineCtrl.forward(from: 0);
        if (state.winner == _playerName) {
          AudioService.playWin();
          PointService.recordWin();
        } else {
          AudioService.playWrong();
        }
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) _showWinnerDialog(state.winner!);
        });
      }
    }, onError: (e) {
      debugPrint('XO Game Stream Error: $e');
    });
  }

  // ─── مجرى البلوتوث/المحلي ─────────────────────────────────────────
  void _listenToBtGame(String id) {
    _btGameSub?.cancel();
    _pollTimer?.cancel();

    _pollTimer =
        Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
      if (_roomId == null) return;
      final state = await _btService.getRoom(_roomId!);
      if (state != null) {
        bool needsUpdate = state.currentTurn != _btGameState?.currentTurn ||
            state.player2Id != _btGameState?.player2Id ||
            state.winner != _btGameState?.winner;
        if (!needsUpdate && _btGameState != null) {
          for (int i = 0; i < 9; i++) {
            if (state.board[i] != _btGameState!.board[i]) {
              needsUpdate = true;
              break;
            }
          }
        }
        if (needsUpdate) {
          if (mounted) setState(() => _btGameState = state);
          if (state.winner != null) _showBtWinnerDialog(state.winner!);
        }
      } else {
        if (mounted && _roomId != null && _btGameState != null) {
          _pollTimer?.cancel();
          _showRoomDeletedDialog();
        }
      }
    });

    _btGameSub = _btService.gameStream(id).listen((state) {
      if (!mounted) return;
      if (state == null) {
        if (_roomId != null) _showRoomDeletedDialog();
        return;
      }

      for (int i = 0; i < 9; i++) {
        if ((_btGameState?.board[i] ?? '') == '' && state.board[i] != '') {
          _cellControllers[i].forward(from: 0);
        }
      }

      setState(() {
        _btGameState = state;
        _isCreating = false;
        _isJoining = false;
      });

      if (state.winner != null) {
        _winLine = _findBtWinLine(state.board);
        _winLineCtrl.forward(from: 0);
        if (state.winner == _playerName) {
          AudioService.playWin();
        } else {
          AudioService.playWrong();
        }
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) _showBtWinnerDialog(state.winner!);
        });
      }
    });
  }

  List<int>? _findWinLine(List<String> b) {
    const lines = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6]
    ];
    for (var l in lines) {
      if (b[l[0]] != '' && b[l[0]] == b[l[1]] && b[l[0]] == b[l[2]]) {
        return l;
      }
    }
    return null;
  }

  List<int>? _findBtWinLine(List<String> b) => _findWinLine(b);

  // ─── حركات اللعب ─────────────────────────────────────────────────
  void _onTapBoard(int index) {
    if (_isBluetoothMode) {
      _onTapBoardBt(index);
    } else {
      _onTapBoardOnline(index);
    }
  }

  void _onTapBoardOnline(int index) {
    if (_gameState == null || _gameState!.winner != null) return;
    if (_gameState!.player2Id == null) {
      _showError('انتظر حتى ينضم الخصم!');
      return;
    }
    if (_gameState!.board[index] != '') return;
    bool isMyTurn = (_gameState!.player1Id == _playerName &&
            _gameState!.currentTurn == 'player1') ||
        (_gameState!.player2Id == _playerName &&
            _gameState!.currentTurn == 'player2');
    if (!isMyTurn) return;
    final newBoard = List<String>.from(_gameState!.board);
    final mySymbol = _gameState!.player1Id == _playerName ? 'X' : 'O';
    newBoard[index] = mySymbol;
    final winner = _checkLocalWinner(
        newBoard, _gameState!.player1Id, _gameState!.player2Id);
    final myType = _gameState!.player1Id == _playerName ? 'player1' : 'player2';
    _cellControllers[index].forward(from: 0);
    AudioService.playClick();
    _gameService.makeMove(_roomId!, index, myType, newBoard, winner);
  }

  void _onTapBoardBt(int index) {
    if (_btGameState == null || _btGameState!.winner != null) return;
    if (_btGameState!.player2Id == null) {
      _showError('انتظر حتى ينضم الخصم!');
      return;
    }
    if (_btGameState!.board[index] != '') return;
    bool isMyTurn = (_btGameState!.player1Id == _playerName &&
            _btGameState!.currentTurn == 'player1') ||
        (_btGameState!.player2Id == _playerName &&
            _btGameState!.currentTurn == 'player2');
    if (!isMyTurn) return;
    final newBoard = List<String>.from(_btGameState!.board);
    final mySymbol = _btGameState!.player1Id == _playerName ? 'X' : 'O';
    newBoard[index] = mySymbol;
    final winner = _checkLocalWinner(
        newBoard, _btGameState!.player1Id, _btGameState!.player2Id);
    final myType =
        _btGameState!.player1Id == _playerName ? 'player1' : 'player2';
    _cellControllers[index].forward(from: 0);
    AudioService.playClick();
    _btService.makeMove(_roomId!, index, myType, newBoard, winner);
  }

  String? _checkLocalWinner(List<String> b, String p1, String? p2) {
    const lines = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6]
    ];
    for (var l in lines) {
      if (b[l[0]] != '' && b[l[0]] == b[l[1]] && b[l[0]] == b[l[2]]) {
        return b[l[0]] == 'X' ? p1 : p2;
      }
    }
    if (!b.contains('')) return 'draw';
    return null;
  }

  void _resetRoom() {
    if (_roomId != null) {
      if (_isBluetoothMode) {
        _btService.resetRoom(_roomId!);
      } else {
        _gameService.resetRoom(_roomId!);
      }
      _winLine = null;
      _winLineCtrl.reset();
      for (var c in _cellControllers) c.reset();
    }
  }

  // ─── الحوارات ─────────────────────────────────────────────────────
  void _showRoomDeletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A0A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: _kPink, width: 2),
        ),
        title: Text('تنبيه!',
            textAlign: TextAlign.center,
            style: GoogleFonts.lalezar(color: _kPink, fontSize: 26)),
        content: Text('تم إغلاق الغرفة من قبل المضيف أو انتهت الجلسة.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lalezar(color: Colors.white70)),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                AdManagerService.showInterstitial(
                    onAdClosed: () => _clearGameState());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPurple,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child:
                  Text('تمام', style: GoogleFonts.lalezar(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _clearGameState() {
    if (mounted) {
      setState(() {
        _roomId = null;
        _gameState = null;
        _btGameState = null;
        _isCreating = false;
        _isJoining = false;
        _winLine = null;
      });
      _gameSub?.cancel();
      _btGameSub?.cancel();
      _winLineCtrl.reset();
      for (var c in _cellControllers) c.reset();
    }
  }

  void _showWinnerDialog(String? winner) {
    if (winner != null && winner != 'draw') {
      bool isMe = winner == _playerName;
      if (isMe) PointService.addPoints(3);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GameWinScreen(
            winnerName: isMe ? 'أنت الفائز! 🏆' : winner,
            pointsEarned: isMe ? 3 : 0,
            onPlayAgain: () {
              Navigator.pop(context);
              _resetRoom();
            },
            onExit: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ),
      );
      return;
    }
    if (winner == 'draw') PointService.addPoints(1);
    _showDrawDialog();
  }

  void _showBtWinnerDialog(String? winner) {
    if (winner != null && winner != 'draw') {
      bool isMe = winner == _playerName;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GameWinScreen(
            winnerName: isMe ? 'أنت الفائز! 🏆' : winner,
            pointsEarned: isMe ? 3 : 0,
            onPlayAgain: () {
              Navigator.pop(context);
              _resetRoom();
            },
            onExit: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ),
      );
      return;
    }
    _showDrawDialog();
  }

  void _showDrawDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A0A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: _kGold, width: 2),
        ),
        title: Text('تعادل! 🤝',
            textAlign: TextAlign.center,
            style: GoogleFonts.lalezar(color: _kGold, fontSize: 28)),
        content: Text('لا يوجد فائز هذه المرة',
            textAlign: TextAlign.center,
            style: GoogleFonts.lalezar(color: Colors.white70, fontSize: 18)),
        actions: [
          Column(children: [
            _dialogBtn('إعادة اللعب', _kPurple, () {
              Navigator.pop(context);
              AdManagerService.showInterstitial(onAdClosed: () => _resetRoom());
            }),
            const SizedBox(height: 8),
            _dialogBtn('خروج', _kPink, () {
              AdManagerService.showInterstitial(
                  onAdClosed: () =>
                      Navigator.popUntil(context, (r) => r.isFirst));
            }),
          ]),
        ],
      ),
    );
  }

  Widget _dialogBtn(String t, Color c, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: c,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(t,
            style: GoogleFonts.lalezar(color: Colors.white, fontSize: 18)),
      ),
    );
  }

  Future<void> _onExit() async {
    if (_roomId != null) {
      if (_isBluetoothMode && _btGameState?.player1Id == _playerName) {
        await _btService.deleteRoom(_roomId!);
      } else if (!_isBluetoothMode && _gameState?.player1Id == _playerName) {
        await _gameService.deleteRoom(_roomId!);
      }
    }
    _clearGameState();
    _pollTimer?.cancel();
    if (_presence != null) {
      Supabase.instance.client.removeChannel(_presence!);
      _presence = null;
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.lalezar()),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ));
  }

  // ─── واجهة المستخدم ───────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isInGame =
        _roomId != null && (_gameState != null || _btGameState != null);

    return Scaffold(
      backgroundColor: _kBg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_kBg2, _kBg, Color(0xFF050515)],
          ),
        ),
        child: SafeArea(
          child: isInGame ? _buildGame() : _buildMenu(),
        ),
      ),
    );
  }

  // ─── قائمة اللعب ──────────────────────────────────────────────────
  Widget _buildMenu() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // ─ الرأس
            _buildMenuHeader(),

            const SizedBox(height: 24),

            // ─ بطاقة الاتصال WiFi/Bluetooth
            _buildConnectionModeCard(),

            const SizedBox(height: 24),

            // ─ أزرار اللعب
            if (_playerName != null) ...[
              _menuBtn(
                title: 'دخول تلقائي ⚡',
                subtitle: 'انضم لخصم على الفور!',
                icon: Icons.bolt_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF3CAC), Color(0xFF784BA0)],
                ),
                onTap: _isBluetoothMode
                    ? () => _showJoinDialog(btMode: true)
                    : _autoJoin,
                isLoading: _isAutoJoining,
              ),
              const SizedBox(height: 16),
              _menuBtn(
                title: 'إنشاء غرفة 🏠',
                subtitle: _isBluetoothMode
                    ? 'شارك الكود مع صديقك'
                    : 'العب مع من تختار',
                icon: Icons.add_box_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFF4776E6), Color(0xFF8E54E9)],
                ),
                onTap: _createRoom,
                isLoading: _isCreating,
              ),
              const SizedBox(height: 16),
              _menuBtn(
                title: 'الانضمام برمز 🔑',
                subtitle: 'أدخل كود الغرفة',
                icon: Icons.login_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00D4FF), Color(0xFF0096B3)],
                ),
                onTap: () => _showJoinDialog(),
                isLoading: _isJoining,
              ),
            ] else ...[
              const Center(
                child: CircularProgressIndicator(color: _kCyan),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            AudioService.playClick();
            Navigator.pop(context);
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15), width: 1.5),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                'XO أونلاين',
                style: GoogleFonts.lalezar(
                  fontSize: 30,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                        color: _kCyan.withValues(alpha: 0.8),
                        blurRadius: 12,
                        offset: const Offset(0, 0)),
                  ],
                ),
              ),
              if (_playerName != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_playerAvatar != null)
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: NetworkImage(_playerAvatar!),
                      ),
                    const SizedBox(width: 6),
                    Text(
                      'مرحباً $_playerName',
                      style: GoogleFonts.lalezar(
                          color: Colors.white60, fontSize: 14),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(width: 42),
      ],
    );
  }

  Widget _buildConnectionModeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.05),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings_input_antenna, color: _kCyan, size: 20),
              const SizedBox(width: 8),
              Text(
                'طريقة الاتصال',
                style: GoogleFonts.lalezar(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _modeCard(
                  icon: Icons.wifi_rounded,
                  label: 'إنترنت',
                  sublabel: 'العب مع أي شخص',
                  isSelected: !_isBluetoothMode,
                  color: _kCyan,
                  onTap: () => setState(() => _isBluetoothMode = false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _modeCard(
                  icon: Icons.bluetooth_connected_rounded,
                  label: 'محلي/Bluetooth',
                  sublabel: 'العب مع من بجانبك',
                  isSelected: _isBluetoothMode,
                  color: _kPurple,
                  onTap: () => setState(() => _isBluetoothMode = true),
                ),
              ),
            ],
          ),
          if (_isBluetoothMode) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _kPurple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: _kPurple.withValues(alpha: 0.4), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: _kPurple, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'أنشئ غرفة وشارك الكود مع صديقك القريب منك. كلاكما يستخدم نفس التطبيق.',
                      style: GoogleFonts.lalezar(
                          color: Colors.white60, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _modeCard({
    required IconData icon,
    required String label,
    required String sublabel,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        AudioService.playClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.3),
                    color.withValues(alpha: 0.1)
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.white38, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.lalezar(
                color: isSelected ? Colors.white : Colors.white38,
                fontSize: 15,
              ),
            ),
            Text(
              sublabel,
              textAlign: TextAlign.center,
              style: GoogleFonts.lalezar(
                color: isSelected ? color : Colors.white24,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuBtn({
    required String title,
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading
          ? null
          : () {
              AudioService.playClick();
              onTap();
            },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 3))
                  : Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lalezar(
                    fontSize: 22,
                    color: Colors.white,
                    shadows: const [
                      Shadow(color: Colors.black38, blurRadius: 4)
                    ],
                  ),
                ),
                Text(
                  subtitle,
                  style:
                      GoogleFonts.lalezar(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showJoinDialog({bool btMode = false}) {
    _joinController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A0A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: btMode ? _kPurple : _kCyan, width: 2),
        ),
        title: Text(
          btMode ? 'ادخل كود الغرفة المحلية' : 'ادخل كود الغرفة',
          textAlign: TextAlign.center,
          style: GoogleFonts.lalezar(
            color: btMode ? _kPurple : _kCyan,
            fontSize: 22,
          ),
        ),
        content: TextField(
          controller: _joinController,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          style: GoogleFonts.lalezar(
              fontSize: 28, color: Colors.white, letterSpacing: 4),
          decoration: InputDecoration(
            hintText: '0000',
            hintStyle: GoogleFonts.lalezar(
                color: Colors.white24, fontSize: 28, letterSpacing: 4),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: btMode ? _kPurple : _kCyan, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: btMode ? _kPurple : _kCyan, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2), width: 1.5),
            ),
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('إلغاء',
                      style: GoogleFonts.lalezar(color: Colors.white38)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _isBluetoothMode = btMode);
                    _joinRoom();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: btMode ? _kPurple : _kCyan,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('دخول',
                      style: GoogleFonts.lalezar(
                          color: Colors.white, fontSize: 18)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── شاشة اللعب ───────────────────────────────────────────────────
  Widget _buildGame() {
    final board = _isBluetoothMode
        ? (_btGameState?.board ?? List.filled(9, ''))
        : (_gameState?.board ?? List.filled(9, ''));
    final p1 =
        _isBluetoothMode ? _btGameState?.player1Id : _gameState?.player1Id;
    final p2 =
        _isBluetoothMode ? _btGameState?.player2Id : _gameState?.player2Id;
    final turn =
        _isBluetoothMode ? _btGameState?.currentTurn : _gameState?.currentTurn;
    final isWaiting = p2 == null;

    bool isMyTurn = (p1 == _playerName && turn == 'player1') ||
        (p2 == _playerName && turn == 'player2');

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 12),
          _buildGameHeader(isWaiting),
          const SizedBox(height: 12),
          if (isWaiting) _buildWaitingBanner(),
          _buildScoreBoard(p1, p2, turn),
          const SizedBox(height: 20),
          _buildGrid(board),
          const SizedBox(height: 20),
          _buildTurnIndicator(isMyTurn, isWaiting),
          const SizedBox(height: 20),
          if (_isBluetoothMode)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bluetooth_connected_rounded,
                    color: _kPurple, size: 18),
                const SizedBox(width: 6),
                Text('وضع محلي',
                    style: GoogleFonts.lalezar(color: _kPurple, fontSize: 14)),
              ],
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildGameHeader(bool isWaiting) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              AudioService.playClick();
              _onExit();
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15), width: 1.5),
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          Text(
            'XO - اللعب المباشر',
            style: GoogleFonts.lalezar(
              fontSize: 24,
              color: Colors.white,
              shadows: [
                Shadow(
                    color: _kCyan.withValues(alpha: 0.6),
                    blurRadius: 10,
                    offset: const Offset(0, 0)),
              ],
            ),
          ),
          if (!isWaiting && _roomId != null)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: _roomId!));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('تم نسخ الكود!', style: GoogleFonts.lalezar()),
                  backgroundColor: _kCyan.withValues(alpha: 0.8),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ));
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _kCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: _kCyan.withValues(alpha: 0.4), width: 1.5),
                ),
                child: Text(
                  _roomId!,
                  style: GoogleFonts.lalezar(
                      color: _kCyan, fontSize: 16, letterSpacing: 2),
                ),
              ),
            )
          else
            const SizedBox(width: 50),
        ],
      ),
    );
  }

  Widget _buildWaitingBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kGold.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(color: _kGold, strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'بانتظار الخصم...',
                  style: GoogleFonts.lalezar(color: _kGold, fontSize: 16),
                ),
                if (_roomId != null)
                  Text(
                    'كود الغرفة: $_roomId',
                    style: GoogleFonts.lalezar(
                        color: Colors.white60, fontSize: 13),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: _roomId ?? ''));
              AudioService.playClick();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _kGold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.copy_rounded, color: _kGold, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBoard(String? p1, String? p2, String? turn) {
    final isP1Turn = turn == 'player1';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
              child: _playerCard(
            name: p1 ?? '---',
            symbol: 'X',
            color: _kX,
            isActive: isP1Turn,
            isMe: p1 == _playerName,
            avatar: p1 == _playerName ? _playerAvatar : null,
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(
              'VS',
              style: GoogleFonts.lalezar(
                fontSize: 22,
                color: Colors.white30,
                letterSpacing: 2,
              ),
            ),
          ),
          Expanded(
              child: _playerCard(
            name: p2 ?? 'بانتظار...',
            symbol: 'O',
            color: _kO,
            isActive: !isP1Turn && p2 != null,
            isMe: p2 == _playerName,
            avatar: p2 == _playerName ? _playerAvatar : null,
          )),
        ],
      ),
    );
  }

  Widget _playerCard({
    required String name,
    required String symbol,
    required Color color,
    required bool isActive,
    required bool isMe,
    String? avatar,
  }) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) => Transform.scale(
        scale: isActive ? _pulseAnim.value : 1.0,
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.25),
                    color.withValues(alpha: 0.08)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
          color: isActive ? null : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color : Colors.white.withValues(alpha: 0.08),
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: Column(
          children: [
            if (avatar != null)
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(avatar),
              )
            else
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withValues(alpha: 0.2),
                child: Text(
                  symbol,
                  style: GoogleFonts.lalezar(
                      color: color, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              symbol,
              style: GoogleFonts.lalezar(
                fontSize: 28,
                color: color,
                shadows: [
                  Shadow(
                      color: color.withValues(alpha: 0.8),
                      blurRadius: 8,
                      offset: const Offset(0, 0)),
                ],
              ),
            ),
            Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lalezar(
                fontSize: 13,
                color: isActive ? Colors.white : Colors.white38,
              ),
            ),
            if (isMe)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'أنت',
                  style: GoogleFonts.lalezar(color: color, fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<String> board) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.1), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _kPurple.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 9,
            itemBuilder: (context, index) => _buildCell(index, board),
          ),
        ),
      ),
    );
  }

  Widget _buildCell(int index, List<String> board) {
    final val = board[index];
    final isWinCell = _winLine?.contains(index) ?? false;

    return GestureDetector(
      onTap: () => _onTapBoard(index),
      child: AnimatedBuilder(
        animation: _cellScaleAnims[index],
        builder: (context, child) => Transform.scale(
          scale: val.isEmpty ? 1.0 : _cellScaleAnims[index].value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: isWinCell
                ? LinearGradient(
                    colors: val == 'X'
                        ? [
                            _kX.withValues(alpha: 0.3),
                            _kX.withValues(alpha: 0.1)
                          ]
                        : [
                            _kO.withValues(alpha: 0.3),
                            _kO.withValues(alpha: 0.1)
                          ],
                  )
                : null,
            color: isWinCell
                ? null
                : (val.isEmpty
                    ? Colors.white.withValues(alpha: 0.06)
                    : (val == 'X'
                        ? _kX.withValues(alpha: 0.1)
                        : _kO.withValues(alpha: 0.1))),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isWinCell
                  ? (val == 'X' ? _kX : _kO)
                  : (val.isEmpty
                      ? Colors.white.withValues(alpha: 0.1)
                      : (val == 'X'
                          ? _kX.withValues(alpha: 0.4)
                          : _kO.withValues(alpha: 0.4))),
              width: isWinCell ? 2.5 : 1.5,
            ),
            boxShadow: isWinCell
                ? [
                    BoxShadow(
                      color: (val == 'X' ? _kX : _kO).withValues(alpha: 0.5),
                      blurRadius: 15,
                      spreadRadius: 2,
                    )
                  ]
                : [],
          ),
          child: Center(
            child: val.isEmpty
                ? null
                : Text(
                    val,
                    style: GoogleFonts.lalezar(
                      fontSize: 52,
                      color: val == 'X' ? _kX : _kO,
                      shadows: [
                        Shadow(
                          color:
                              (val == 'X' ? _kX : _kO).withValues(alpha: 0.8),
                          blurRadius: 14,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTurnIndicator(bool isMyTurn, bool isWaiting) {
    if (isWaiting) return const SizedBox();
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) => Transform.scale(
        scale: isMyTurn ? _pulseAnim.value : 1.0,
        child: child,
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          gradient: isMyTurn
              ? const LinearGradient(
                  colors: [_kPink, Color(0xFF784BA0)],
                )
              : null,
          color: isMyTurn ? null : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(24),
          boxShadow: isMyTurn
              ? [
                  BoxShadow(
                    color: _kPink.withValues(alpha: 0.4),
                    blurRadius: 15,
                    spreadRadius: 1,
                  )
                ]
              : [],
          border: Border.all(
            color: isMyTurn
                ? _kPink.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isMyTurn ? Icons.touch_app_rounded : Icons.hourglass_top_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              isMyTurn ? '🔥 دورك الآن يا بطل!' : '⏳ انتظر خصمك...',
              style: GoogleFonts.lalezar(
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
