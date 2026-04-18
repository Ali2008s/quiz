import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/services/auth_service.dart';
import '../data/services/xo_game_service.dart';
import '../data/services/audio_service.dart';
import '../data/services/point_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'game_win_screen.dart';

class XOGameScreen extends StatefulWidget {
  const XOGameScreen({super.key});

  @override
  State<XOGameScreen> createState() => _XOGameScreenState();
}

class _XOGameScreenState extends State<XOGameScreen> {
  final XOGameService _gameService = XOGameService();
  String? _roomId;
  bool _isCreating = false;
  bool _isJoining = false;
  String? _playerName;
  StreamSubscription<XOGameState?>? _gameSub;
  XOGameState? _gameState;
  final TextEditingController _joinController = TextEditingController();
  bool _isAutoJoining = false;
  RealtimeChannel? _presence;
  Timer? _dcTimer;

  void _autoJoin() async {
    if (_playerName == null) return;
    setState(() => _isAutoJoining = true);
    try {
      final roomId = await _gameService.findRandomRoom(_playerName!);
      if (roomId != null) {
        _listenToGame(roomId);
        setState(() => _roomId = roomId);
      } else {
        // Create new room if none found
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
  }

  Future<void> _initPlayer() async {
    final name = await AuthService.getUserName();
    if (mounted) setState(() => _playerName = name);
  }

  @override
  void dispose() {
    _gameSub?.cancel();
    _dcTimer?.cancel();
    _presence?.unsubscribe();
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

  void _setupPresence(String id) {
    _presence?.unsubscribe();
    _presence = Supabase.instance.client.channel('xo_pr_$id');
    _presence!.onPresenceSync((payload) {
      if (!mounted || _gameState == null) return;
      
      final List<dynamic> pState = _presence!.presenceState();
      final users = pState.map((p) => p.payload['u'].toString()).toSet();
      
      // If someone new joined but DB hasn't updated our stream yet, force a fetch
      if (_gameState!.player2Id == null && users.length > 1) {
        _gameService.getRoom(id).then((state) {
          if (mounted && state != null && state.player2Id != null) {
            setState(() => _gameState = state);
          }
        });
      }

      if (_gameState!.player2Id == null) return;
      
      String opponent = _playerName == _gameState!.player1Id ? _gameState!.player2Id! : _gameState!.player1Id;
      
      if (!users.contains(opponent)) {
        if (!(_dcTimer?.isActive ?? false)) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم فصل اتصال الخصم! الانتظار 10 ثواني...', style: GoogleFonts.lalezar()), backgroundColor: Colors.orange));
          _dcTimer = Timer(const Duration(seconds: 10), () {
            if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إغلاق الغرفة لعدم عودة الخصم.', style: GoogleFonts.lalezar()), backgroundColor: Colors.red));
               _gameService.deleteRoom(id);
            }
          });
        }
      } else {
        if (_dcTimer?.isActive ?? false) {
           _dcTimer?.cancel();
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('عاد الخصم للعب! ✅', style: GoogleFonts.lalezar()), backgroundColor: Colors.green));
        }
      }
    }).subscribe((status, [e]) async {
      if (status == 'SUBSCRIBED' && _playerName != null) await _presence!.track({'u': _playerName});
    });
  }

  void _listenToGame(String id) {
    _gameSub?.cancel();
    _setupPresence(id);
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
      if (state.winner != null) {
        if (state.winner == _playerName) {
          AudioService.playWin();
          PointService.recordWin(); // Record win for leaderboard
        } else {
          AudioService.playWrong();
        }
        _showWinnerDialog(state.winner!);
      }
    });
  }

  void _showRoomDeletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('تنبيه!', textAlign: TextAlign.center, style: GoogleFonts.lalezar(color: Colors.red)),
        content: Text('تم إغلاق الغرفة من قبل المضيف أو انتهت الجلسة.', textAlign: TextAlign.center, style: GoogleFonts.lalezar()),
        actions: [
          Center(child: ElevatedButton(onPressed: () { Navigator.pop(context); _clearGameState(); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A2E)), child: Text('تمام', style: GoogleFonts.lalezar(color: Colors.white)))),
        ],
      ),
    );
  }

  void _clearGameState() {
    if (mounted) {
      setState(() { _roomId = null; _gameState = null; _isCreating = false; _isJoining = false; });
      _gameSub?.cancel();
    }
  }

  Future<void> _onExit() async {
    if (_roomId != null && _gameState != null) {
      if (_gameState!.player1Id == _playerName) { await _gameService.deleteRoom(_roomId!); }
    }
    _clearGameState();
  }

  void _onTapBoard(int index) {
    if (_gameState == null || _gameState!.winner != null) return;
    if (_gameState!.player2Id == null) {
      _showError('انتظر حتى ينضم الخصم!');
      return;
    }
    if (_gameState!.board[index] != '') return;
    bool isMyTurn = (_gameState!.player1Id == _playerName && _gameState!.currentTurn == 'player1') || (_gameState!.player2Id == _playerName && _gameState!.currentTurn == 'player2');
    if (!isMyTurn) return;
    final newBoard = List<String>.from(_gameState!.board);
    final mySymbol = _gameState!.player1Id == _playerName ? 'X' : 'O';
    newBoard[index] = mySymbol;
    final winner = _checkLocalWinner(newBoard);
    final myType = _gameState!.player1Id == _playerName ? 'player1' : 'player2';
    AudioService.playClick();
    _gameService.makeMove(_roomId!, index, myType, newBoard, winner);
  }

  String? _checkLocalWinner(List<String> b) {
    const lines = [[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]];
    for (var l in lines) {
      if (b[l[0]] != '' && b[l[0]] == b[l[1]] && b[l[0]] == b[l[2]]) {
        return b[l[0]] == 'X' ? _gameState!.player1Id : _gameState!.player2Id;
      }
    }
    if (!b.contains('')) return 'draw';
    return null;
  }

  void _resetRoom() {
    if (_roomId != null) {
      _gameService.resetRoom(_roomId!);
    }
  }

  void _showWinnerDialog(String? winner) {
    if (winner != null && winner != 'draw') {
      bool isMe = winner == _playerName;
      if (isMe) {
        PointService.addPoints(3); // Reduced from 10 to 3
      }
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GameWinScreen(
            winnerName: isMe ? "أنت الفائز! 🏆" : winner,
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

    if (winner == 'draw') {
        PointService.addPoints(1); // 1 point for draw
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog( // Assuming CustomDialog is an AlertDialog or similar
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(winner == null || winner == 'draw' ? 'تعادل!' : 'انتهت اللعبة', textAlign: TextAlign.center, style: GoogleFonts.lalezar(fontSize: 28)),
        content: Text(winner == null || winner == 'draw' ? 'لايوجد فائز هذه المرة' : 'الفائز هو: $winner', textAlign: TextAlign.center, style: GoogleFonts.lalezar(fontSize: 20)),
        actions: [
          Center(
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _resetRoom();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA5D6A7), padding: const EdgeInsets.symmetric(horizontal: 40)),
                  child: Text('إعادة اللعب', style: GoogleFonts.lalezar(color: Colors.white)),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF5350), padding: const EdgeInsets.symmetric(horizontal: 40)),
                  child: Text('خروج', style: GoogleFonts.lalezar(color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: GoogleFonts.lalezar()), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          return Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Wrap(
                      spacing: 40, runSpacing: 40,
                      children: List.generate(100, (index) => Icon(Icons.grid_3x3, size: 40, color: Colors.black.withOpacity(0.05)))
                    ),
                  )
                ),
              ),
              Positioned.fill(
                child: (_roomId == null || _gameState == null) ? _buildMenu() : _buildGame()
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMenu() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader('XO - غرفة الأونلاين', onBack: () => Navigator.pop(context)),
          const SizedBox(height: 20),
          if (_playerName != null)
            Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), decoration: BoxDecoration(color: const Color(0xFFA5D6A7).withOpacity(0.2), borderRadius: BorderRadius.circular(30), border: Border.all(color: const Color(0xFFA5D6A7))), child: Text('مرحباً بك يا $_playerName', style: GoogleFonts.lalezar(color: const Color(0xFF2E7D32)))),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                _actionButton(
                    title: 'دخول تلقائي (عشوائي)',
                    icon: Icons.bolt_rounded,
                    color: const Color(0xFFEF5350),
                    onTap: _autoJoin,
                    isLoading: _isAutoJoining),
                const SizedBox(height: 15),
                _actionButton(
                    title: 'إنشاء غرفة جديدة', icon: Icons.add_rounded, color: const Color(0xFF64B5F6), onTap: _createRoom, isLoading: _isCreating),
                const SizedBox(height: 15),
                _actionButton(title: 'الانضمام لغرفة', icon: Icons.login_rounded, color: const Color(0xFFFFCC33), onTap: () {
                  showDialog(context: context, builder: (context) => AlertDialog(
                    title: Text('ادخل كود الغرفة', style: GoogleFonts.lalezar()),
                    content: TextField(controller: _joinController, textAlign: TextAlign.center, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: 'مثلاً: 1234', border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
                    actions: [TextButton(onPressed: () { Navigator.pop(context); _joinRoom(); }, child: Text('دخول', style: GoogleFonts.lalezar()))],
                  ));
                }, isLoading: _isJoining),
              ],
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _actionButton({required String title, required IconData icon, required Color color, required VoidCallback onTap, bool isLoading = false}) {
    return GestureDetector(
      onTap: isLoading ? null : () {
        AudioService.playClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF1A1A1A), width: 3), boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (isLoading) const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
          else Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 15),
          Text(title, style: GoogleFonts.lalezar(fontSize: 22, color: Colors.white)),
        ]),
      ),
    );
  }

  Widget _buildHeader(String title, {required VoidCallback onBack}) {
    return Padding(padding: const EdgeInsets.all(20), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      GestureDetector(onTap: () {
        AudioService.playClick();
        onBack();
      }, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1A1A1A), width: 2)), child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20))),
      Text(title, style: GoogleFonts.lalezar(fontSize: 28, color: const Color(0xFF1A1A2E))),
      const SizedBox(width: 40),
    ]));
  }

  Widget _buildGame() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader('اللعب المباشر', onBack: _onExit),
          if (_gameState!.player2Id == null) _buildRoomHeader(),
          _buildScoreBoard(),
          const SizedBox(height: 30),
          _buildGrid(),
          const SizedBox(height: 30),
          _buildStatusIndicator(),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    bool isMyTurn = (_gameState!.player1Id == _playerName && _gameState!.currentTurn == 'player1') || (_gameState!.player2Id == _playerName && _gameState!.currentTurn == 'player2');
    return Container(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15), decoration: BoxDecoration(color: isMyTurn ? const Color(0xFFEF5350) : Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(30), border: Border.all(color: const Color(0xFF1A1A1A), width: 3)), child: Text(isMyTurn ? 'دورك الآن يا بطل!' : 'انتظر خصمك يخلص...', style: GoogleFonts.lalezar(fontSize: 22, color: isMyTurn ? Colors.white : Colors.grey)));
  }

  Widget _buildRoomHeader() {
    return Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.all(15), decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFFFD700), width: 2)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('كود الغرفة:', style: GoogleFonts.lalezar(fontSize: 12, color: Colors.white70)), Text(_roomId!, style: GoogleFonts.lalezar(fontSize: 28, color: const Color(0xFFFFD700), letterSpacing: 2))]),
        ElevatedButton(onPressed: () {
          AudioService.playClick();
          Clipboard.setData(ClipboardData(text: _roomId!));
        }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700), foregroundColor: Colors.black), child: Text('نسخ الكود', style: GoogleFonts.lalezar()))
      ]),
    );
  }

  Widget _buildScoreBoard() {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      _playerScore(_gameState!.player1Id, 'X', const Color(0xFF64B5F6), _gameState!.currentTurn == 'player1'),
      const Icon(Icons.bolt_rounded, color: Color(0xFFFFCC33), size: 40),
      _playerScore(_gameState!.player2Id ?? 'بانتظار المنافس...', 'O', const Color(0xFFFFCC33), _gameState!.currentTurn == 'player2')
    ]));
  }

  Widget _playerScore(String name, String symbol, Color color, bool isActive) {
    return Expanded(child: Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.symmetric(horizontal: 5), decoration: BoxDecoration(color: isActive ? color.withOpacity(0.2) : Colors.transparent, borderRadius: BorderRadius.circular(20), border: Border.all(color: isActive ? color : Colors.transparent, width: 2)),
      child: Column(children: [Text(symbol, style: GoogleFonts.lalezar(fontSize: 32, color: color)), Text(name, overflow: TextOverflow.ellipsis, style: GoogleFonts.lalezar(fontSize: 14))])));
  }

  Widget _buildGrid() {
    return Container(padding: const EdgeInsets.all(20), margin: const EdgeInsets.symmetric(horizontal: 20), decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(32), border: Border.all(color: const Color(0xFF1A1A1A), width: 4)),
      child: GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 15, mainAxisSpacing: 15), itemCount: 9,
        itemBuilder: (context, index) => GestureDetector(onTap: () => _onTapBoard(index), child: Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: Center(child: Text(_gameState!.board[index], style: GoogleFonts.lalezar(fontSize: 48, color: _gameState!.board[index] == 'X' ? const Color(0xFF64B5F6) : const Color(0xFFFFCC33))))))));
  }
}
