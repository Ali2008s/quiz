import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/services/auth_service.dart';
import '../data/services/ludo_game_service.dart';
import '../data/services/audio_service.dart';
import '../data/services/point_service.dart';
import '../data/services/ad_manager_service.dart';
import 'game_win_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── رموز وألوان اللاعبين ──────────────────────────────────────────
const Color kRed = Color(0xFFE53935);
const Color kBlue = Color(0xFF1E88E5);
const Color kGreen = Color(0xFF43A047);
const Color kYellow = Color(0xFFFDD835);
const Color kGold = Color(0xFFFFD700);
const Color kDark = Color(0xFF1A1A2E);

const List<Color> kColors = [kRed, kBlue, kGreen, kYellow];
const List<String> kPlayerNames = ['أحمر', 'أزرق', 'أخضر', 'أصفر'];
const List<IconData> kPlayerIcons = [
  Icons.favorite,
  Icons.water_drop,
  Icons.eco,
  Icons.star
];

const List<List<int>> kPathGrid = [
  [6, 12],
  [6, 11],
  [6, 10],
  [6, 9],
  [6, 8],
  [5, 8],
  [4, 8],
  [3, 8],
  [2, 8],
  [1, 8],
  [0, 8],
  [0, 7],
  [0, 6],
  [1, 6],
  [2, 6],
  [3, 6],
  [4, 6],
  [5, 6],
  [6, 5],
  [6, 4],
  [6, 3],
  [6, 2],
  [6, 1],
  [6, 0],
  [7, 0],
  [8, 0],
  [8, 1],
  [8, 2],
  [8, 3],
  [8, 4],
  [8, 5],
  [9, 6],
  [10, 6],
  [11, 6],
  [12, 6],
  [13, 6],
  [14, 6],
  [14, 7],
  [14, 8],
  [13, 8],
  [12, 8],
  [11, 8],
  [10, 8],
  [9, 8],
  [8, 9],
  [8, 10],
  [8, 11],
  [8, 12],
  [8, 13],
  [8, 14],
  [7, 14],
  [6, 14],
  [6, 13],
];

const List<int> kStartPos = [1, 14, 27, 40];

const List<List<List<int>>> kSafePath = [
  [
    [7, 13],
    [7, 12],
    [7, 11],
    [7, 10],
    [7, 9],
    [7, 8]
  ],
  [
    [1, 7],
    [2, 7],
    [3, 7],
    [4, 7],
    [5, 7],
    [6, 7]
  ],
  [
    [7, 1],
    [7, 2],
    [7, 3],
    [7, 4],
    [7, 5],
    [7, 6]
  ],
  [
    [13, 7],
    [12, 7],
    [11, 7],
    [10, 7],
    [9, 7],
    [8, 7]
  ],
];

const List<List<List<int>>> kHomeCells = [
  [
    [1, 10],
    [2, 10],
    [1, 11],
    [2, 11]
  ],
  [
    [1, 2],
    [2, 2],
    [1, 3],
    [2, 3]
  ],
  [
    [10, 2],
    [11, 2],
    [10, 3],
    [11, 3]
  ],
  [
    [10, 10],
    [11, 10],
    [10, 11],
    [11, 11]
  ],
];

class LudoOnlineScreen extends StatefulWidget {
  const LudoOnlineScreen({super.key});

  @override
  State<LudoOnlineScreen> createState() => _LudoOnlineScreenState();
}

class _LudoOnlineScreenState extends State<LudoOnlineScreen>
    with TickerProviderStateMixin {
  final LudoGameService _gameService = LudoGameService();
  String? _roomId;
  bool _isCreating = false;
  bool _isJoining = false;
  String? _playerName;
  String? _playerAvatar;
  StreamSubscription<LudoOnlineState?>? _gameSub;
  Timer? _pollTimer;
  LudoOnlineState? _gameState;
  final TextEditingController _joinController = TextEditingController();
  RealtimeChannel? _presence;
  Timer? _dcTimer;

  int _playerCount = 2; // 2 or 4

  bool _isCountdownRunning = false;
  int _countdownSeconds = 5;
  Timer? _countdownTimer;
  bool _hasStartedGame = false;

  late AnimationController _diceAnimCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  bool _isRollingLocal = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();

    _diceAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
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
    _diceAnimCtrl.dispose();
    _pulseCtrl.dispose();
    _countdownTimer?.cancel();
    AudioService.resumeBgm();
    super.dispose();
  }

  // ─── إعدادات الغرفة ───

  void _showGameSetup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A0A2E), Color(0xFF0D0520)],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20)],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'إعدادات الغرفة',
                  style: GoogleFonts.lalezar(fontSize: 30, color: Colors.white),
                ),
                const SizedBox(height: 20),

                // ── طريقة الاتصال تمت إزالتها (فقط إنترنت للـ Ludo)

                // ── عدد اللاعبين
                _sectionHeader('👥 عدد اللاعبين'),
                Row(
                  children: [
                    Expanded(
                      child: _setupCard(
                        '2 لاعبين',
                        Icons.person,
                        _playerCount == 2,
                        () => setModalState(() => _playerCount = 2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _setupCard(
                        '4 لاعبين',
                        Icons.group,
                        _playerCount == 4,
                        () => setModalState(() => _playerCount = 4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _actionBtn(
                  'ابدأ اللعبة الآن 🚀',
                  Icons.play_arrow_rounded,
                  const Color(0xFF4CAF50),
                  () {
                    AudioService.playClick();
                    setState(() {/* _isLocalMode already set */});
                    Navigator.pop(context);
                    _createRoom();
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _setupCard2(
    String title,
    String emoji,
    String subtitle,
    bool isSelected,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        AudioService.playClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.lalezar(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 16,
              ),
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.lalezar(
                color: isSelected ? color : Colors.white38,
                fontSize: 11,
              ),
            ),
          ],
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
              ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
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

  void _createRoom() async {
    if (_playerName == null) return;
    setState(() => _isCreating = true);
    try {
      final id = await _gameService.createRoom(_playerName!,
          maxPlayers: _playerCount, avatar: _playerAvatar);
      _listenToGame(id);
      setState(() => _roomId = id);
    } catch (e) {
      if (mounted) setState(() => _isCreating = false);
      _showError('خطأ: $e');
    }
  }

  void _joinRandomRoom() async {
    if (_playerName == null) return;
    setState(() => _isJoining = true);
    try {
      final avatar = _playerAvatar ?? '';
      final id = await _gameService.findRandomRoom(_playerName!, avatar);
      if (id != null) {
        _listenToGame(id);
        setState(() => _roomId = id);
      } else {
        // إذا لم نجد غرفة، نقوم بإنشاء واحدة جديدة تلقائياً
        _createRoom();
      }
    } catch (e) {
      if (mounted) setState(() => _isJoining = false);
      _showError('خطأ في البحث: $e');
    }
  }

  void _setupPresence(String id) {
    if (_presence != null) {
      Supabase.instance.client.removeChannel(_presence!);
    }
    _presence = Supabase.instance.client.channel('ludo_pr_$id');
    _presence!.onPresenceSync((payload) {
      if (!mounted || _gameState == null) return;

      bool isFull = _gameState!.isRoomFull;
      if (!isFull) return;

      final List<dynamic> stateList = _presence!.presenceState();
      final Set<String> users =
          stateList.map((p) => p.payload['u'].toString()).toSet();

      List<String> expected = [_gameState!.player1Id];
      if (_gameState!.player2Id != null) expected.add(_gameState!.player2Id!);
      if (_gameState!.player3Id != null) expected.add(_gameState!.player3Id!);
      if (_gameState!.player4Id != null) expected.add(_gameState!.player4Id!);

      bool missing = false;
      for (var p in expected) {
        if (p != _playerName && !users.contains(p)) missing = true;
      }

      if (missing) {
        if (!(_dcTimer?.isActive ?? false)) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('تم فصل اتصال أحد اللاعبين! الانتظار 10 ثواني...',
                  style: GoogleFonts.lalezar()),
              backgroundColor: Colors.orange));
          _dcTimer = Timer(const Duration(seconds: 10), () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('تم إغلاق الغرفة لعدم عودة اللاعب.',
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
              content: Text('عاد اللاعب! ✅', style: GoogleFonts.lalezar()),
              backgroundColor: Colors.green));
        }
      }
    }).subscribe((status, [e]) async {
      if (status == RealtimeSubscribeStatus.subscribed && _playerName != null) {
        await _presence!.track({'u': _playerName});
      }
    });

    _gameSub = _gameService.gameStream(id).listen((state) {
      if (!mounted) return;
      if (state == null) {
        if (_roomId != null) {
          _gameSub?.cancel();
          setState(() {
            _roomId = null;
            _gameState = null;
          });
        }
        return;
      }

      setState(() {
        _gameState = state;
        _isCreating = false;
        _isJoining = false;
      });

      if (state.isRoomFull && !_isCountdownRunning && !_hasStartedGame) {
        setState(() {
          _isCountdownRunning = true;
          _countdownSeconds = 5;
        });
        _countdownTimer?.cancel();
        _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (_countdownSeconds > 1) {
            if (mounted) setState(() => _countdownSeconds--);
          } else {
            t.cancel();
            if (mounted)
              setState(() {
                _hasStartedGame = true;
                _isCountdownRunning = false;
              });
          }
        });
      }

      if (state.winner != null) {
        // ... game over logic ...
      }
    });
  }

  void _listenToGame(String id) {
    _gameSub?.cancel();
    _setupPresence(id);
  }

  void _handleWinner(String winner) {
    if (winner == _playerName) {
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
                          builder: (context) => const LudoOnlineScreen())),
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

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: GoogleFonts.lalezar()),
        backgroundColor: Colors.red));
  }

  _joinRoom() async {
    try {
      await _gameService.joinRoom(_joinController.text.trim(), _playerName!,
          avatar: _playerAvatar);
      _listenToGame(_joinController.text.trim());
      setState(() => _roomId = _joinController.text.trim());
    } catch (e) {
      _showError(e.toString());
    }
  }

  // ─── واجهة المستخدم ───

  @override
  Widget build(BuildContext context) {
    // عرض شاشة الانتظار إذا كانت الغرفة موجودة ولم تبدأ اللعبة بعد
    if (_roomId != null &&
        _gameState != null &&
        (!_gameState!.isRoomFull || _isCountdownRunning || !_hasStartedGame)) {
      return _waitingScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF2C1810),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2C1810), Color(0xFF4A2C1A), Color(0xFF6B3F20)],
          ),
        ),
        child: SafeArea(
            child: (_roomId == null || _gameState == null)
                ? _buildMenu()
                : _buildGame()),
      ),
    );
  }

  Widget _waitingScreen() {
    final maxP = _gameState?.maxPlayers ?? _playerCount;
    final joined = List.generate(maxP, (i) => _gameState?.getPlayerId(i))
        .where((p) => p != null)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFF1A0A2E),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A0A2E), Color(0xFF2C1810), Color(0xFF4A1A0A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── AppBar داكن
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        AudioService.playClick();
                        _gameService.deleteRoom(_roomId!);
                        setState(() {
                          _roomId = null;
                          _gameState = null;
                          _hasStartedGame = false;
                          _isCountdownRunning = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: kGold.withOpacity(0.5), width: 1.5),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: kGold, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'غرفة الانتظار',
                      style: GoogleFonts.lalezar(
                          color: Colors.white, fontSize: 24),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ── الرأس
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Text(
                      _isCountdownRunning
                          ? '🚀 اللعبة تبدأ بعد $_countdownSeconds...'
                          : '⏳ بانتظار انضمام لاعبين...',
                      style: GoogleFonts.lalezar(
                        fontSize: 22,
                        color: _isCountdownRunning ? kGold : Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // عداد اللاعبين
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: kGold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: kGold.withOpacity(0.5), width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_alt_rounded,
                              color: kGold, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '$joined / $maxP لاعب انضم',
                            style:
                                GoogleFonts.lalezar(color: kGold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── كود الغرفة
              GestureDetector(
                onTap: () {
                  AudioService.playClick();
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: kGold.withOpacity(0.4), width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.gamepad_rounded, color: kGold, size: 24),
                      const SizedBox(width: 10),
                      Column(
                        children: [
                          Text(
                            'كود الغرفة',
                            style: GoogleFonts.lalezar(
                                color: Colors.white54, fontSize: 13),
                          ),
                          Text(
                            _roomId ?? '----',
                            style: GoogleFonts.lalezar(
                              fontSize: 36,
                              color: kGold,
                              letterSpacing: 6,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.copy_rounded, color: kGold, size: 24),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ── صور اللاعبين بشكل دائري جذاب
              Expanded(
                child: Center(
                  child: _buildPlayerSlotGrid(maxP),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerSlotGrid(int maxP) {
    final slots = List.generate(maxP, (index) {
      final pName = _gameState?.getPlayerId(index);
      final pAvatar = _gameState?.getPlayerAvatar(index);
      final isMe = pName == _playerName;
      final playerColor = kColors[index % kColors.length];

      return _buildPlayerSlot(
        playerName: pName,
        playerAvatar: pAvatar,
        isMe: isMe,
        color: playerColor,
        index: index,
        label: kPlayerNames[index % kPlayerNames.length],
      );
    });

    if (maxP == 2) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: slots,
      );
    } else {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 30),
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        children: slots,
      );
    }
  }

  Widget _buildPlayerSlot({
    required String? playerName,
    required String? playerAvatar,
    required bool isMe,
    required Color color,
    required int index,
    required String label,
  }) {
    final hasPlayer = playerName != null;

    return TweenAnimationBuilder<double>(
      key: ValueKey('slot_$index${hasPlayer ? '_filled' : ''}'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + index * 100),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: hasPlayer ? value : 1.0,
          child: child,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar container
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasPlayer
                  ? RadialGradient(
                      colors: [
                        color.withValues(alpha: 0.4),
                        color.withValues(alpha: 0.1),
                      ],
                    )
                  : null,
              color: hasPlayer ? null : Colors.grey.shade100,
              border: Border.all(
                color: hasPlayer ? color : const Color(0xFF1A1A1A),
                width: hasPlayer ? 3 : 2,
              ),
              boxShadow: hasPlayer
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: hasPlayer
                ? ClipOval(
                    child: playerAvatar != null
                        ? Image.network(
                            playerAvatar,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                playerName[0].toUpperCase(),
                                style: GoogleFonts.lalezar(
                                  color: Colors.white,
                                  fontSize: 36,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              playerName[0].toUpperCase(),
                              style: GoogleFonts.lalezar(
                                color: Colors.white,
                                fontSize: 36,
                              ),
                            ),
                          ),
                  )
                : const Icon(Icons.person_outline_rounded,
                    color: Colors.white24, size: 40),
          ),

          const SizedBox(height: 10),

          // اسم اللاعب
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Column(
              key: ValueKey(playerName ?? 'empty_$index'),
              children: [
                if (hasPlayer && isMe)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: kGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'أنت 👑',
                      style: GoogleFonts.lalezar(color: kGold, fontSize: 12),
                    ),
                  ),
                Text(
                  hasPlayer ? playerName : 'بانتظار...',
                  style: GoogleFonts.lalezar(
                    color: hasPlayer ? Colors.white : Colors.white30,
                    fontSize: 15,
                  ),
                ),
                if (hasPlayer)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color,
                              blurRadius: 6,
                            )
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        label,
                        style: GoogleFonts.lalezar(
                          color: color,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenu() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          const SizedBox(height: 30),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  AudioService.playClick();
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: kGold.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: kGold, size: 20),
                ),
              ),
              Expanded(
                  child: _header('لودو أونلاين', Icons.casino, Colors.white)),
            ],
          ),
          const SizedBox(height: 40),
          _menuBox('إنشاء غرفة', 'العب مع أصدقائك ونافسهم',
              const Color(0xFF6A1B9A), Icons.add_box_rounded, () {
            _showGameSetup();
          }),
          const SizedBox(height: 20),
          _menuBox('دخول سريع', 'انضم لغرفة عشوائية والعب فوراً',
              const Color(0xFF00897B), Icons.flash_on_rounded, () {
            _joinRandomRoom();
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
            color: c.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white24, width: 2),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black45, offset: Offset(0, 8), blurRadius: 10)
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
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9)))
              ]))
        ]),
      ),
    );
  }

  Widget _joinCardUI() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white12, width: 2),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 12),
            child: Text('انضمام بكود الغرفة',
                style:
                    GoogleFonts.lalezar(fontSize: 18, color: Colors.white70)),
          ),
          Row(children: [
            Expanded(
                child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10)),
              child: TextField(
                  controller: _joinController,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lalezar(
                      fontSize: 22, color: kGold, letterSpacing: 2),
                  decoration: const InputDecoration(
                      hintText: '--- ---',
                      hintStyle: TextStyle(color: Colors.white24),
                      border: InputBorder.none)),
            )),
            const SizedBox(width: 12),
            ElevatedButton(
                onPressed: _joinRoom,
                style: ElevatedButton.styleFrom(
                    backgroundColor: kGold,
                    foregroundColor: Colors.black,
                    elevation: 5,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
                child: const Icon(Icons.arrow_forward_rounded, size: 28)),
          ]),
        ],
      ),
    );
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

  // ─── واجهة اللعبة ───

  int _getMyIndex() {
    if (_gameState?.player1Id == _playerName) return 0;
    if (_gameState?.player2Id == _playerName) return 1;
    if (_gameState?.player3Id == _playerName) return 2;
    if (_gameState?.player4Id == _playerName) return 3;
    return 0; // Default fallback
  }

  Widget _buildGame() {
    return Column(
      children: [
        _buildHeader(),
        _buildPlayerInfo(),
        Expanded(child: _buildBoardArea()),
        _buildControls(),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              AudioService.playClick();
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: kDark,
                  title: Text('خروج؟',
                      style: GoogleFonts.lalezar(color: Colors.white)),
                  content: Text('هل أنت متأكد من الخروج من الغرفة؟',
                      style: GoogleFonts.lalezar(color: Colors.white)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('لا',
                            style: GoogleFonts.lalezar(color: Colors.grey))),
                    TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                        },
                        child: Text('نعم',
                            style: GoogleFonts.lalezar(color: kRed))),
                  ],
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: kGold.withValues(alpha: 0.5), width: 1.5),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: kGold, size: 20),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'لودو أونلاين',
                style: TextStyle(
                  fontFamily: 'Lalezar',
                  fontSize: 26,
                  color: kGold,
                  shadows: [
                    Shadow(
                        color: Colors.black54,
                        blurRadius: 4,
                        offset: Offset(0, 2))
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: kGold.withValues(alpha: 0.5), width: 1.5),
            ),
            child: Text('كود: $_roomId',
                style: GoogleFonts.lalezar(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerInfo() {
    return Container(
      height: 62,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _gameState!.maxPlayers,
        itemBuilder: (_, i) {
          final isActive = i == _gameState!.currentPlayerIndex;
          final pName = _gameState!.getPlayerId(i) ?? kPlayerNames[i];
          final pieces = _gameState!.getPieces(i);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color:
                  isActive ? kColors[i].withValues(alpha: 0.9) : Colors.black38,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    isActive ? Colors.white : kColors[i].withValues(alpha: 0.4),
                width: isActive ? 2.5 : 1.5,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                          color: kColors[i].withValues(alpha: 0.5),
                          blurRadius: 12)
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(kPlayerIcons[i],
                    color: isActive ? Colors.white : kColors[i], size: 18),
                const SizedBox(width: 6),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pName,
                        style: GoogleFonts.lalezar(
                            fontSize: 14,
                            color: isActive ? Colors.white : Colors.white70)),
                    Row(
                      children: List.generate(
                          4,
                          (j) => Icon(
                                pieces[j] == 57
                                    ? Icons.home_rounded
                                    : (pieces[j] > 0
                                        ? Icons.circle
                                        : Icons.radio_button_unchecked),
                                size: 10,
                                color: isActive
                                    ? Colors.white
                                    : kColors[i].withValues(alpha: 0.7),
                              )),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBoardArea() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: kGold.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 3),
              ],
            ),
            child: CustomPaint(
              painter: _LudoBoardPainter(
                numPlayers: _gameState!.maxPlayers,
              ),
              child: _buildPiecesOverlay(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPiecesOverlay() {
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.maxWidth;
      final cellSize = size / 15;
      List<Widget> pieceWidgets = [];

      final myIndex = _getMyIndex();
      final isMyTurn = myIndex == _gameState!.currentPlayerIndex;

      for (int p = 0; p < _gameState!.maxPlayers; p++) {
        final pieces = _gameState!.getPieces(p);
        for (int i = 0; i < 4; i++) {
          final pos = pieces[i];
          final cell = _getGridCell(p, pos, i);
          if (cell == null) continue;

          final col = cell[0];
          final row = cell[1];

          double dx = 0, dy = 0;
          if (pos == 0) {
            // No offset needed, already assigned home cell
          } else if (pos == 57) {
            dx = (i % 2 == 0 ? -6 : 6).toDouble();
            dy = (i < 2 ? -6 : 6).toDouble();
          }

          // Check if movable
          bool isMovable = false;
          if (isMyTurn &&
              p == myIndex &&
              _gameState!.diceRolled &&
              !_isRollingLocal) {
            if (pos == 0 && _gameState!.diceValue == 6) {
              isMovable = true;
            } else if (pos > 0 && pos + _gameState!.diceValue <= 57) {
              isMovable = true;
            }
          }

          final pieceSize = cellSize * 0.82;
          final left = col * cellSize + (cellSize - pieceSize) / 2 + dx;
          final top = row * cellSize + (cellSize - pieceSize) / 2 + dy;

          pieceWidgets.add(
            AnimatedPositioned(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOutCirc,
              left: left,
              top: top,
              width: pieceSize,
              height: pieceSize,
              child: GestureDetector(
                onTap: () async {
                  if (isMovable) {
                    final killed =
                        await _gameService.movePiece(_roomId!, i, _gameState!);
                    if (pos + _gameState!.diceValue == 57) {
                      AudioService.playSfx('sounds/ludo_token_home.mp3');
                    } else if (killed) {
                      AudioService.playSfx('sounds/ludo_kill.mp3');
                    } else {
                      AudioService.playClick();
                    }
                  }
                },
                child: _buildPieceWidget(p, pos == 57, isMovable, pieceSize),
              ),
            ),
          );
        }
      }

      return Stack(children: pieceWidgets);
    });
  }

  List<int>? _getGridCell(int playerIndex, int pos, int pieceIndex) {
    if (pos == 0) {
      return kHomeCells[playerIndex][pieceIndex];
    }
    if (pos == 57) {
      return [7, 7]; // Center
    }

    final startIdx = kStartPos[playerIndex] - 1;
    int p = pos - 1;

    if (p < 51) {
      int pathIdx = (startIdx + p) % kPathGrid.length;
      return kPathGrid[pathIdx];
    } else {
      int safeIdx = p - 51;
      if (safeIdx < kSafePath[playerIndex].length) {
        return kSafePath[playerIndex][safeIdx];
      }
      return [7, 7];
    }
  }

  Widget _buildPieceWidget(
      int player, bool isFinished, bool isMovable, double size) {
    return AnimatedBuilder(
      animation: isMovable ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
      builder: (_, child) {
        final scale = isMovable ? _pulseAnim.value : 1.0;
        return Transform.scale(
          scale: scale,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Bottom Shadow/Depth
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black45,
                ),
              ),
              // Main Body
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      kColors[player].withValues(alpha: 0.8),
                      kColors[player],
                      kColors[player].withValues(alpha: 0.9),
                    ],
                    stops: const [0.3, 0.7, 1.0],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.6),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kColors[player].withValues(alpha: 0.5),
                      blurRadius: isMovable ? 10 : 4,
                      spreadRadius: isMovable ? 2 : 0,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: size * 0.4,
                    height: size * 0.4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ),
              if (isFinished)
                const Icon(Icons.check_circle, color: Colors.white, size: 14),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    final myIndex = _getMyIndex();
    final isMyTurn = myIndex == _gameState!.currentPlayerIndex;
    final canRoll = isMyTurn &&
        !_gameState!.diceRolled &&
        !_isRollingLocal &&
        _gameState!.winner == null;

    final curPlayer = _gameState!.currentPlayerIndex;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border:
            Border(top: BorderSide(color: kGold.withOpacity(0.5), width: 2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // معلومات اللاعب الحالي
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    kColors[curPlayer].withValues(alpha: 0.8),
                    kColors[curPlayer].withValues(alpha: 0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white30, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: kColors[curPlayer].withValues(alpha: 0.3),
                    blurRadius: 10,
                  )
                ],
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white,
                        backgroundImage:
                            _gameState!.getPlayerAvatar(curPlayer) != null
                                ? NetworkImage(
                                    _gameState!.getPlayerAvatar(curPlayer)!)
                                : null,
                        child: _gameState!.getPlayerAvatar(curPlayer) == null
                            ? Icon(kPlayerIcons[curPlayer],
                                color: kColors[curPlayer])
                            : null,
                      ),
                      if (isMyTurn)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                                color: Colors.green, shape: BoxShape.circle),
                            child: const Icon(Icons.check,
                                color: Colors.white, size: 10),
                          ),
                        )
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                            _gameState!.getPlayerId(curPlayer) ??
                                kPlayerNames[curPlayer],
                            style: GoogleFonts.lalezar(
                                fontSize: 18,
                                color: Colors.white,
                                height: 1.1)),
                        Text(isMyTurn ? 'دورك الآن!' : 'ينتظر الدور...',
                            style: GoogleFonts.lalezar(
                                fontSize: 13, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),

          // زر الزهر
          GestureDetector(
            onTap: canRoll ? _rollDiceNetwork : null,
            child: AnimatedBuilder(
              animation: _diceAnimCtrl,
              builder: (_, child) {
                return Transform.rotate(
                  angle: _isRollingLocal ? _diceAnimCtrl.value * 2 * pi : 0,
                  child: child,
                );
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: (_gameState!.diceRolled || canRoll)
                        ? [kGold, const Color(0xFFFF8F00)]
                        : [Colors.grey.shade500, Colors.grey.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (_gameState!.diceRolled || canRoll) ? kGold : kDark,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (_gameState!.diceValue != 0 && _gameState!.diceRolled
                                  ? kGold
                                  : Colors.black)
                              .withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child:
                      (_gameState!.diceValue == 0 && !_gameState!.diceRolled) ||
                              _isRollingLocal
                          ? Icon(Icons.casino_rounded,
                              size: 40,
                              color: (_gameState!.diceRolled || canRoll)
                                  ? Colors.white
                                  : kDark)
                          : Text(
                              _getDiceFace(_gameState!.diceValue),
                              style: TextStyle(
                                fontSize: 42,
                                color: Colors.white,
                              ),
                            ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _rollDiceNetwork() async {
    setState(() => _isRollingLocal = true);
    _diceAnimCtrl.reset();
    _diceAnimCtrl.forward();
    AudioService.playSfx('sounds/ludo_dice.mp3');

    await Future.delayed(const Duration(milliseconds: 600));
    final val = Random().nextInt(6) + 1;

    await _gameService.rollDice(_roomId!, _gameState!, val);

    if (mounted) {
      setState(() => _isRollingLocal = false);
    }
  }

  String _getDiceFace(int val) {
    if (val <= 0 || val > 6) return '';
    const faces = ['', '⚀', '⚁', '⚂', '⚃', '⚄', '⚅'];
    return faces[val];
  }
}

// ─── رسام اللوحة (نفسه من اللعبة المحلية) ──────────────────────────
class _LudoBoardPainter extends CustomPainter {
  final int numPlayers;
  _LudoBoardPainter({required this.numPlayers});

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / 15;
    final paint = Paint();

    paint.color = const Color(0xFFFFF8E7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)),
      paint,
    );

    _drawGrid(canvas, size, cellSize, paint);
    _drawHomes(canvas, cellSize, paint);
    _drawSafePaths(canvas, cellSize, paint);
    _drawCenter(canvas, cellSize, paint);

    paint
      ..color = kGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
          const Radius.circular(16)),
      paint,
    );
    paint.style = PaintingStyle.fill;
  }

  void _drawGrid(Canvas canvas, Size size, double cs, Paint p) {
    p.color = const Color(0xFFE0D0B0);
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 0.5;
    for (int r = 6; r <= 9; r++) {
      canvas.drawLine(Offset(0, r * cs), Offset(size.width, r * cs), p);
    }
    for (int c = 6; c <= 9; c++) {
      canvas.drawLine(Offset(c * cs, 0), Offset(c * cs, size.height), p);
    }
    for (int r = 0; r <= 15; r++) {
      canvas.drawLine(Offset(6 * cs, r * cs), Offset(9 * cs, r * cs), p);
      canvas.drawLine(Offset(0, 6 * cs + r * cs / 3),
          Offset(size.width, 6 * cs + r * cs / 3), p);
    }
    p.style = PaintingStyle.fill;
  }

  void _drawHomes(Canvas canvas, double cs, Paint p) {
    final homeRects = [
      Rect.fromLTWH(0, 9 * cs, 6 * cs, 6 * cs), // أحمر (أسفل يسار)
      Rect.fromLTWH(0, 0, 6 * cs, 6 * cs), // أزرق (أعلى يسار)
      Rect.fromLTWH(9 * cs, 0, 6 * cs, 6 * cs), // أخضر (أعلى يمين)
      Rect.fromLTWH(9 * cs, 9 * cs, 6 * cs, 6 * cs), // أصفر (أسفل يمين)
    ];

    for (int i = 0; i < 4; i++) {
      p.color = kColors[i].withValues(alpha: 0.9);
      canvas.drawRRect(
          RRect.fromRectAndRadius(homeRects[i], const Radius.circular(8)), p);

      p
        ..color = kGold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawRRect(
          RRect.fromRectAndRadius(homeRects[i], const Radius.circular(8)), p);
      p.style = PaintingStyle.fill;

      const inset = 10.0;
      final innerRect = homeRects[i].deflate(inset);
      p.color = Colors.white.withValues(alpha: 0.85);
      canvas.drawRRect(
          RRect.fromRectAndRadius(innerRect, const Radius.circular(6)), p);

      final centers = kHomeCells[i]
          .map((c) => Offset(c[0] * cs + cs / 2, c[1] * cs + cs / 2))
          .toList();
      for (final center in centers) {
        p.color = kColors[i].withValues(alpha: 0.3);
        canvas.drawCircle(center, cs * 0.36, p);
        p
          ..color = kColors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(center, cs * 0.36, p);
        p.style = PaintingStyle.fill;
      }
    }
  }

  void _drawSafePaths(Canvas canvas, double cs, Paint p) {
    for (int pl = 0; pl < 4; pl++) {
      for (int s = 0; s < kSafePath[pl].length; s++) {
        final cell = kSafePath[pl][s];
        final rect =
            Rect.fromLTWH(cell[0] * cs + 1, cell[1] * cs + 1, cs - 2, cs - 2);
        p.color = kColors[pl].withValues(alpha: 0.65);
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(4)), p);
      }
    }

    for (int i = 0; i < kPathGrid.length; i++) {
      final cell = kPathGrid[i];
      final rect =
          Rect.fromLTWH(cell[0] * cs + 1, cell[1] * cs + 1, cs - 2, cs - 2);

      bool isStart = false;
      int? startPlayer;
      for (int sp = 0; sp < 4; sp++) {
        if (kStartPos[sp] - 1 == i) {
          isStart = true;
          startPlayer = sp;
          break;
        }
      }

      if (isStart && startPlayer != null) {
        p.color = kColors[startPlayer].withValues(alpha: 0.4);
      } else {
        p.color = Colors.white.withValues(alpha: 0.8);
      }
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(3)), p);

      p
        ..color = const Color(0xFFCCC0A0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(3)), p);
      p.style = PaintingStyle.fill;
    }
  }

  void _drawCenter(Canvas canvas, double cs, Paint p) {
    final centerRect = Rect.fromLTWH(6 * cs, 6 * cs, 3 * cs, 3 * cs);
    final path = Path();
    final cx = centerRect.center.dx;
    final cy = centerRect.center.dy;
    final l = centerRect.left;
    final r = centerRect.right;
    final t = centerRect.top;
    final b = centerRect.bottom;

    path.reset();
    path.moveTo(cx, cy);
    path.lineTo(l, b);
    path.lineTo(l, t);
    path.close();
    p.color = kRed.withValues(alpha: 0.85);
    canvas.drawPath(path, p);

    path.reset();
    path.moveTo(cx, cy);
    path.lineTo(l, t);
    path.lineTo(r, t);
    path.close();
    p.color = kBlue.withValues(alpha: 0.85);
    canvas.drawPath(path, p);

    path.reset();
    path.moveTo(cx, cy);
    path.lineTo(r, t);
    path.lineTo(r, b);
    path.close();
    p.color = kGreen.withValues(alpha: 0.85);
    canvas.drawPath(path, p);

    path.reset();
    path.moveTo(cx, cy);
    path.lineTo(r, b);
    path.lineTo(l, b);
    path.close();
    p.color = kYellow.withValues(alpha: 0.85);
    canvas.drawPath(path, p);

    p
      ..color = kGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(cx, cy), cs * 0.5, p);
    p.style = PaintingStyle.fill;
    p.color = kGold.withValues(alpha: 0.2);
    canvas.drawCircle(Offset(cx, cy), cs * 0.5, p);
  }

  @override
  bool shouldRepaint(covariant _LudoBoardPainter old) =>
      old.numPlayers != numPlayers;
}
