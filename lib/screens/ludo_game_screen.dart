import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../data/services/audio_service.dart';

// ─── رموز اللاعبين ────────────────────────────────────────────────
const int kEmpty = 0;

// ─── الألوان ──────────────────────────────────────────────────────
const Color kRed = Color(0xFFE53935);
const Color kBlue = Color(0xFF1E88E5);
const Color kGreen = Color(0xFF43A047);
const Color kYellow = Color(0xFFFDD835);
const Color kGold = Color(0xFFFFD700);
const Color kDark = Color(0xFF1A1A2E);
const Color kSand = Color(0xFFD4A96A);
const Color kSandLight = Color(0xFFF5DEB3);

// ─── نموذج الرقعة ─────────────────────────────────────────────────
// كل لاعب لديه 4 قطع، كل قطعة في موضع (0=قاعدة, 1..57=المسار, 58=وصل)
class LudoPiece {
  final int player; // 0=أحمر 1=أزرق 2=أخضر 3=أصفر
  int pos; // 0=قاعدة, 1..56=مسار الأمان, 57=اكتمل
  bool finished;
  LudoPiece({required this.player, this.pos = 0, this.finished = false});
}

// مسار كل لاعب (الخلايا على المسار المشترك 52 + 6 أمان)
// نستخدم مصفوفة 15×15 ونرسمها يدوياً

const List<Color> kColors = [kRed, kBlue, kGreen, kYellow];
const List<String> kPlayerNames = ['أحمر', 'أزرق', 'أخضر', 'أصفر'];
const List<IconData> kPlayerIcons = [
  Icons.favorite,
  Icons.water_drop,
  Icons.eco,
  Icons.star
];

const List<int> kStartPos = [1, 14, 27, 40];
const int kTotalSteps = 57;

const List<List<int>> kPathGrid = [
  [6, 12], [6, 11], [6, 10], [6, 9], [6, 8],
  [5, 8], [4, 8], [3, 8], [2, 8], [1, 8],
  [0, 8], [0, 7], [0, 6],
  [1, 6], [2, 6], [3, 6], [4, 6], [5, 6],
  [6, 5], [6, 4], [6, 3], [6, 2], [6, 1],
  [6, 0], [7, 0], [8, 0],
  [8, 1], [8, 2], [8, 3], [8, 4], [8, 5],
  [9, 6], [10, 6], [11, 6], [12, 6], [13, 6], [14, 6],
  [14, 7], [14, 8],
  [13, 8], [12, 8], [11, 8], [10, 8], [9, 8],
  [8, 9], [8, 10], [8, 11], [8, 12], [8, 13], [8, 14],
  [7, 14], [6, 14], [6, 13],
];

const List<List<List<int>>> kSafePath = [
  [[7, 13], [7, 12], [7, 11], [7, 10], [7, 9], [7, 8]],
  [[1, 7], [2, 7], [3, 7], [4, 7], [5, 7], [6, 7]],
  [[7, 1], [7, 2], [7, 3], [7, 4], [7, 5], [7, 6]],
  [[13, 7], [12, 7], [11, 7], [10, 7], [9, 7], [8, 7]],
];

const List<List<List<int>>> kHomeCells = [
  [[1, 10], [2, 10], [1, 11], [2, 11]],
  [[1, 2], [2, 2], [1, 3], [2, 3]],
  [[10, 2], [11, 2], [10, 3], [11, 3]],
  [[10, 10], [11, 10], [10, 11], [11, 11]],
];

class LudoGameScreen extends StatefulWidget {
  final int playerCount;
  const LudoGameScreen({super.key, this.playerCount = 2});

  @override
  State<LudoGameScreen> createState() => _LudoGameScreenState();
}

class _LudoGameScreenState extends State<LudoGameScreen>
    with TickerProviderStateMixin {
  late int _numPlayers;
  late List<List<LudoPiece>> _pieces;
  int _currentPlayer = 0;
  int _diceValue = 0;
  bool _diceRolled = false;
  bool _isRolling = false;
  bool _waitingForMove = false;
  bool _gameOver = false;
  int? _winner;
  List<int> _rankings = [];
  List<int> _piecesHome = [0, 0, 0, 0];
  int? _selectedPiece;

  late AnimationController _diceAnimCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  List<int> _movablePieces = [];

  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _numPlayers = widget.playerCount;
    _initGame();

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

    AudioService.pauseBgm();
    _playBgm();
  }

  void _initGame() {
    _pieces = List.generate(
      4,
      (p) => List.generate(4, (i) => LudoPiece(player: p, pos: 0)),
    );
    _currentPlayer = 0;
    _diceValue = 0;
    _diceRolled = false;
    _isRolling = false;
    _waitingForMove = false;
    _gameOver = false;
    _winner = null;
    _rankings = [];
    _piecesHome = [0, 0, 0, 0];
    _movablePieces = [];
  }

  Future<void> _playBgm() async {
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.play(AssetSource('sounds/bgm_ludo.mp3'), volume: 0.35);
  }

  Future<void> _playSfx(String asset) async {
    await _sfxPlayer.play(AssetSource('sounds/$asset'), volume: 0.8);
  }

  @override
  void dispose() {
    _diceAnimCtrl.dispose();
    _pulseCtrl.dispose();
    _bgmPlayer.dispose();
    _sfxPlayer.dispose();
    AudioService.resumeBgm();
    super.dispose();
  }

  // ─── رمي الزهر ───────────────────────────────────────────────────
  void _rollDice() async {
    if (_diceRolled || _isRolling || _gameOver) return;
    setState(() => _isRolling = true);
    _diceAnimCtrl.reset();
    _diceAnimCtrl.forward();

    await _playSfx('ludo_dice.mp3');

    // محاكاة الرمي
    for (int i = 0; i < 8; i++) {
      await Future.delayed(const Duration(milliseconds: 60));
      setState(() => _diceValue = Random().nextInt(6) + 1);
    }

    final finalVal = Random().nextInt(6) + 1;
    setState(() {
      _diceValue = finalVal;
      _diceRolled = true;
      _isRolling = false;
    });

    _calculateMovablePieces();
  }

  // ─── حساب القطع القابلة للتحرك ────────────────────────────────────
  void _calculateMovablePieces() {
    final pieces = _pieces[_currentPlayer];
    List<int> movable = [];

    for (int i = 0; i < 4; i++) {
      final p = pieces[i];
      if (p.finished) continue;

      if (p.pos == 0) {
        // في القاعدة، تحتاج 6 للخروج
        if (_diceValue == 6) movable.add(i);
      } else {
        // في المسار
        int newPos = p.pos + _diceValue;
        if (newPos <= kTotalSteps) movable.add(i);
      }
    }

    setState(() {
      _movablePieces = movable;
      _waitingForMove = movable.isNotEmpty;
    });

    if (movable.isEmpty) {
      // لا توجد حركة ممكنة
      _showNoMoveSnack();
      _endTurn();
    }
  }

  void _showNoMoveSnack() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('لا توجد حركة ممكنة! 😅',
          style: GoogleFonts.lalezar(), textAlign: TextAlign.center),
      backgroundColor: kColors[_currentPlayer].withOpacity(0.9),
      duration: const Duration(seconds: 1),
    ));
  }

  // ─── تحريك قطعة ─────────────────────────────────────────────────
  void _movePiece(int pieceIndex) async {
    if (!_waitingForMove) return;
    if (!_movablePieces.contains(pieceIndex)) return;

    final p = _pieces[_currentPlayer][pieceIndex];
    bool killed = false;
    bool gotHome = false;
    bool extraTurn = _diceValue == 6;

    setState(() {
      if (p.pos == 0) {
        // أخرج من القاعدة
        p.pos = 1;
      } else {
        p.pos += _diceValue;
      }

      if (p.pos >= kTotalSteps) {
        p.pos = kTotalSteps;
        p.finished = true;
        _piecesHome[_currentPlayer]++;
        gotHome = true;
        extraTurn = true;
      }

      _movablePieces = [];
      _waitingForMove = false;
      _diceRolled = false;
      _diceRolled = false;
    });

    // تحقق من الضرب
    if (!gotHome) {
      killed = _checkKill(pieceIndex);
    }

    // أصوات
    if (gotHome) {
      await _playSfx('ludo_token_home.mp3');
    } else if (killed) {
      await _playSfx('ludo_kill.mp3');
    } else {
      AudioService.playClick();
    }

    // تحقق من الفوز
    if (_piecesHome[_currentPlayer] == 4) {
      _rankings.add(_currentPlayer);
      if (_rankings.length == 1) {
        _winner = _currentPlayer;
        setState(() => _gameOver = true);
        await Future.delayed(const Duration(milliseconds: 500));
        await _playSfx('ludo_win.mp3');
        _showWinDialog();
        return;
      }
    }

    if (extraTurn) {
      // نفس اللاعب يلعب مرة أخرى
      _showExtraTurnSnack();
    } else {
      _endTurn();
    }
  }

  bool _checkKill(int movedIndex) {
    final movedPiece = _pieces[_currentPlayer][movedIndex];
    bool killed = false;

    for (int p = 0; p < 4; p++) {
      if (p == _currentPlayer) continue;
      if (p >= _numPlayers) continue;

      for (int i = 0; i < 4; i++) {
        final other = _pieces[p][i];
        if (other.finished || other.pos == 0) continue;

        // هل هم في نفس الموضع على المسار؟
        if (_getGridPos(movedPiece) == _getGridPos(other)) {
          // هل الموضع ليس خلية أمان؟
          if (!_isSafeCell(_getGridPos(movedPiece))) {
            setState(() => other.pos = 0); // أرجعها للقاعدة
            killed = true;
          }
        }
      }
    }
    return killed;
  }

  List<int>? _getGridPos(LudoPiece piece) {
    if (piece.pos == 0 || piece.finished) return null;
    return _getPieceGridCell(piece);
  }

  bool _isSafeCell(List<int>? cell) {
    if (cell == null) return true;
    // خلايا الأمان: نقاط البداية ومسارات الأمان الداخلية
    for (int p = 0; p < 4; p++) {
      final startOnPath = kStartPos[p] - 1;
      if (startOnPath >= 0 && startOnPath < kPathGrid.length) {
        if (kPathGrid[startOnPath][0] == cell[0] &&
            kPathGrid[startOnPath][1] == cell[1]) {
          return true;
        }
      }
      for (var sc in kSafePath[p]) {
        if (sc[0] == cell[0] && sc[1] == cell[1]) {
          return true;
        }
      }
    }
    return false;
  }

  void _showExtraTurnSnack() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('🎲 دورة إضافية!',
          style: GoogleFonts.lalezar(fontSize: 20),
          textAlign: TextAlign.center),
      backgroundColor: kColors[_currentPlayer],
      duration: const Duration(seconds: 1),
    ));
  }

  void _endTurn() {
    int next = (_currentPlayer + 1) % _numPlayers;
    // تخطى إذا أنهى
    while (_piecesHome[next] == 4 && next != _currentPlayer) {
      next = (next + 1) % _numPlayers;
    }
    setState(() {
      _currentPlayer = next;
      _diceValue = 0;
      _diceRolled = false;
      _movablePieces = [];
    });
  }

  // ─── حساب موضع القطعة على الشبكة ───────────────────────────────
  List<int> _getPieceGridCell(LudoPiece piece) {
    if (piece.pos == 0) {
      // في القاعدة
      final idx = _pieces[piece.player].indexOf(piece);
      return kHomeCells[piece.player][idx];
    }
    if (piece.finished) {
      return [7, 7]; // المركز
    }

    final player = piece.player;
    final startIdx = kStartPos[player] - 1; // index في كبادي path اللاعب

    // كم خطوة مشى في المسار الأمان الداخلي؟
    // مسار اللاعب = kPathGrid مبدأه عند startIdx لمدة 52 ثم kSafePath لمدة 6
    int pos = piece.pos - 1; // 0-based

    if (pos < 51) {
      // في المسار المشترك
      int pathIdx = (startIdx + pos) % kPathGrid.length;
      return kPathGrid[pathIdx];
    } else {
      // في مسار الأمان الداخلي
      int safeIdx = pos - 51;
      if (safeIdx < kSafePath[player].length) {
        return kSafePath[player][safeIdx];
      }
      return [7, 7];
    }
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1A2E), Color(0xFF2C1810)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: kGold, width: 3),
            boxShadow: [
              BoxShadow(
                  color: kGold.withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 5)
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 12),
              Text('الفائز!',
                  style: GoogleFonts.lalezar(
                      fontSize: 36,
                      color: kGold,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 4)])),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: kColors[_winner!].withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kColors[_winner!], width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(kPlayerIcons[_winner!],
                        color: kColors[_winner!], size: 32),
                    const SizedBox(width: 10),
                    Text(
                      'اللاعب ${kPlayerNames[_winner!]}',
                      style: GoogleFonts.lalezar(
                          fontSize: 28, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        AudioService.playClick();
                        Navigator.pop(ctx);
                        setState(() => _initGame());
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF43A047),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white24, width: 2),
                        ),
                        child: Text('إعادة',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.lalezar(
                                fontSize: 20, color: Colors.white)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        AudioService.playClick();
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white24, width: 2),
                        ),
                        child: Text('خروج',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.lalezar(
                                fontSize: 20, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2C1810), // بني غامق
              Color(0xFF4A2C1A), // بني صحراوي
              Color(0xFF6B3F20), // بني ذهبي
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildPlayerInfo(),
              Expanded(child: _buildBoardArea()),
              _buildControls(),
            ],
          ),
        ),
      ),
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
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kGold.withOpacity(0.5), width: 1.5),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: kGold, size: 20),
            ),
          ),
          const Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🎲', style: TextStyle(fontSize: 24)),
                  SizedBox(width: 8),
                  Text(
                    'لودو المصري',
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
                  SizedBox(width: 8),
                  Text('🪬', style: TextStyle(fontSize: 22)),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              AudioService.playClick();
              showDialog(
                context: context,
                builder: (ctx) => _buildRestartDialog(ctx),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kGold.withOpacity(0.5), width: 1.5),
              ),
              child: const Icon(Icons.refresh_rounded, color: kGold, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestartDialog(BuildContext ctx) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: kDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kGold, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('إعادة اللعبة؟',
                style: GoogleFonts.lalezar(fontSize: 24, color: Colors.white)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                    },
                    child: Text('لا',
                        style: GoogleFonts.lalezar(
                            color: Colors.grey, fontSize: 18)),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: kRed),
                    onPressed: () {
                      AudioService.playClick();
                      Navigator.pop(ctx);
                      setState(() => _initGame());
                    },
                    child: Text('نعم',
                        style: GoogleFonts.lalezar(
                            color: Colors.white, fontSize: 18)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerInfo() {
    return Container(
      height: 62,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _numPlayers,
        itemBuilder: (_, i) {
          final isActive = i == _currentPlayer;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? kColors[i].withOpacity(0.9) : Colors.black38,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive ? Colors.white : kColors[i].withOpacity(0.4),
                width: isActive ? 2.5 : 1.5,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                          color: kColors[i].withOpacity(0.5), blurRadius: 12)
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
                    Text(kPlayerNames[i],
                        style: GoogleFonts.lalezar(
                            fontSize: 14,
                            color: isActive ? Colors.white : Colors.white70)),
                    Row(
                      children: List.generate(
                          4,
                          (j) => Icon(
                                _pieces[i][j].finished
                                    ? Icons.home_rounded
                                    : (_pieces[i][j].pos > 0
                                        ? Icons.circle
                                        : Icons.radio_button_unchecked),
                                size: 10,
                                color: isActive
                                    ? Colors.white
                                    : kColors[i].withOpacity(0.7),
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
                    color: kGold.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 3),
              ],
            ),
            child: CustomPaint(
              painter: _LudoBoardPainter(
                numPlayers: _numPlayers,
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

      for (int p = 0; p < _numPlayers; p++) {
        for (int i = 0; i < 4; i++) {
          final piece = _pieces[p][i];
          final cell = _getPieceGridCell(piece);
          final col = cell[0];
          final row = cell[1];

          // حساب الإزاحة لتجنب التداخل
          double dx = 0, dy = 0;
          if (piece.pos == 0) {
            // في القاعدة - 2x2 شبكة
          } else if (piece.finished) {
            // في المركز - رتّبهم
            dx = (i % 2 == 0 ? -6 : 6).toDouble();
            dy = (i < 2 ? -6 : 6).toDouble();
          }

          final isMovable = p == _currentPlayer && _movablePieces.contains(i);
          final pieceSize = cellSize * 0.82;

          final left = col * cellSize + (cellSize - pieceSize) / 2 + dx;
          final top = row * cellSize + (cellSize - pieceSize) / 2 + dy;

          pieceWidgets.add(
            Positioned(
              left: left,
              top: top,
              width: pieceSize,
              height: pieceSize,
              child: GestureDetector(
                onTap: () {
                  if (isMovable) _movePiece(i);
                },
                child: _buildPieceWidget(piece, isMovable, pieceSize),
              ),
            ),
          );
        }
      }

      return Stack(children: pieceWidgets);
    });
  }

  Widget _buildPieceWidget(LudoPiece piece, bool isMovable, double size) {
    return AnimatedBuilder(
      animation: isMovable ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
      builder: (_, child) {
        final scale = isMovable ? _pulseAnim.value : 1.0;
        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kColors[piece.player],
              border: Border.all(
                color: isMovable ? Colors.white : Colors.black45,
                width: isMovable ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      kColors[piece.player].withOpacity(isMovable ? 0.8 : 0.4),
                  blurRadius: isMovable ? 8 : 4,
                ),
              ],
            ),
            child: piece.finished
                ? const Icon(Icons.star, color: Colors.white, size: 10)
                : null,
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black38,
        border:
            Border(top: BorderSide(color: kGold.withOpacity(0.3), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // معلومات اللاعب الحالي
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: kColors[_currentPlayer].withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kColors[_currentPlayer], width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(kPlayerIcons[_currentPlayer],
                    color: kColors[_currentPlayer], size: 22),
                const SizedBox(width: 8),
                Text('دور ${kPlayerNames[_currentPlayer]}',
                    style:
                        GoogleFonts.lalezar(fontSize: 16, color: Colors.white)),
              ],
            ),
          ),

          // زر الزهر
          GestureDetector(
            onTap:
                (!_diceRolled && !_isRolling && !_gameOver) ? _rollDice : null,
            child: AnimatedBuilder(
              animation: _diceAnimCtrl,
              builder: (_, child) {
                return Transform.rotate(
                  angle: _isRolling ? _diceAnimCtrl.value * 2 * pi : 0,
                  child: child,
                );
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _diceRolled
                        ? [kGold, const Color(0xFFFF8F00)]
                        : (!_gameOver
                            ? [Colors.white, Colors.grey.shade200]
                            : [Colors.grey.shade500, Colors.grey.shade600]),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _diceRolled ? kGold : kDark,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (_diceValue != 0 && _diceRolled ? kGold : Colors.black).withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: _diceValue == 0
                      ? Icon(Icons.casino_rounded,
                          size: 40, color: _diceRolled ? Colors.white : kDark)
                      : Text(
                          _getDiceFace(_diceValue),
                          style: TextStyle(
                            fontSize: 42,
                            color: _diceRolled ? Colors.white : kDark,
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

  String _getDiceFace(int val) {
    const faces = ['', '⚀', '⚁', '⚂', '⚃', '⚄', '⚅'];
    return faces[val];
  }
}

// ─── رسام اللوحة ──────────────────────────────────────────────────
class _LudoBoardPainter extends CustomPainter {
  final int numPlayers;
  _LudoBoardPainter({required this.numPlayers});

  static const List<Color> kColors = [kRed, kBlue, kGreen, kYellow];

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / 15;
    final paint = Paint();

    // ─── خلفية الرقعة ──────────────────────────────
    paint.color = const Color(0xFFFFF8E7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)),
      paint,
    );

    // ─── رسم الخلايا ──────────────────────────────
    _drawGrid(canvas, size, cellSize, paint);

    // ─── رسم البيوت ──────────────────────────────
    _drawHomes(canvas, cellSize, paint);

    // ─── رسم مسارات الأمان ──────────────────────
    _drawSafePaths(canvas, cellSize, paint);

    // ─── رسم المركز ──────────────────────────────
    _drawCenter(canvas, cellSize, paint);

    // ─── حدود الرقعة ──────────────────────────────
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
    // رسم خطوط الشبكة لمسار اللعبة (المصلبة)
    p.color = const Color(0xFFE0D0B0);
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 0.5;

    // خطوط أفقية
    for (int r = 6; r <= 9; r++) {
      canvas.drawLine(Offset(0, r * cs), Offset(size.width, r * cs), p);
    }
    // خطوط عمودية
    for (int c = 6; c <= 9; c++) {
      canvas.drawLine(Offset(c * cs, 0), Offset(c * cs, size.height), p);
    }
    // الشريط الأفقي الكامل
    for (int r = 0; r <= 15; r++) {
      canvas.drawLine(Offset(6 * cs, r * cs), Offset(9 * cs, r * cs), p);
      canvas.drawLine(Offset(0, 6 * cs + r * cs / 3),
          Offset(size.width, 6 * cs + r * cs / 3), p);
    }

    p.style = PaintingStyle.fill;
  }

  void _drawHomes(Canvas canvas, double cs, Paint p) {
    // 4 بيوت في الزوايا (6x6)
    final homeRects = [
      Rect.fromLTWH(0, 9 * cs, 6 * cs, 6 * cs), // أحمر (أسفل يسار)
      Rect.fromLTWH(0, 0, 6 * cs, 6 * cs), // أزرق (أعلى يسار)
      Rect.fromLTWH(9 * cs, 0, 6 * cs, 6 * cs), // أخضر (أعلى يمين)
      Rect.fromLTWH(9 * cs, 9 * cs, 6 * cs, 6 * cs), // أصفر (أسفل يمين)
    ];

    for (int i = 0; i < 4; i++) {
      // خلفية البيت
      p.color = kColors[i].withOpacity(0.9);
      canvas.drawRRect(
          RRect.fromRectAndRadius(homeRects[i], const Radius.circular(8)), p);

      // إطار ذهبي
      p
        ..color = kGold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawRRect(
          RRect.fromRectAndRadius(homeRects[i], const Radius.circular(8)), p);
      p.style = PaintingStyle.fill;

      // المنطقة الداخلية البيضاء
      const inset = 10.0;
      final innerRect = homeRects[i].deflate(inset);
      p.color = Colors.white.withOpacity(0.85);
      canvas.drawRRect(
          RRect.fromRectAndRadius(innerRect, const Radius.circular(6)), p);

      // دوائر مواضع القطع
      final centers = _getHomeCenters(i, cs);
      for (final center in centers) {
        p.color = kColors[i].withOpacity(0.3);
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

  List<Offset> _getHomeCenters(int player, double cs) {
    return kHomeCells[player]
        .map((c) => Offset(c[0] * cs + cs / 2, c[1] * cs + cs / 2))
        .toList();
  }

  void _drawSafePaths(Canvas canvas, double cs, Paint p) {
    // مسارات الأمان الداخلية
    const safeColors = [kRed, kBlue, kGreen, kYellow];
    for (int pl = 0; pl < 4; pl++) {
      for (int s = 0; s < kSafePath[pl].length; s++) {
        final cell = kSafePath[pl][s];
        final rect =
            Rect.fromLTWH(cell[0] * cs + 1, cell[1] * cs + 1, cs - 2, cs - 2);
        p.color = safeColors[pl].withOpacity(0.65);
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(4)), p);
      }
    }

    // المسار المشترك - خلايا بيضاء
    for (int i = 0; i < kPathGrid.length; i++) {
      final cell = kPathGrid[i];
      // تخطى خلايا بيوت اللاعبين المجاورة
      final rect =
          Rect.fromLTWH(cell[0] * cs + 1, cell[1] * cs + 1, cs - 2, cs - 2);

      // هل هي نقطة بداية؟
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
        p.color = safeColors[startPlayer].withOpacity(0.4);
      } else {
        p.color = Colors.white.withOpacity(0.8);
      }
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(3)), p);

      // إطار رفيع
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
    // المركز (3x3 من خلية 6,6 إلى 8,8)
    final centerRect = Rect.fromLTWH(6 * cs, 6 * cs, 3 * cs, 3 * cs);

    // مثلثات ملونة
    final path = Path();
    final cx = centerRect.center.dx;
    final cy = centerRect.center.dy;
    final l = centerRect.left;
    final r = centerRect.right;
    final t = centerRect.top;
    final b = centerRect.bottom;

    // أحمر (أسفل يسار)
    path.reset();
    path.moveTo(cx, cy);
    path.lineTo(l, b);
    path.lineTo(l, t);
    path.close();
    p.color = kRed.withOpacity(0.85);
    canvas.drawPath(path, p);

    // أزرق (أعلى يسار)
    path.reset();
    path.moveTo(cx, cy);
    path.lineTo(l, t);
    path.lineTo(r, t);
    path.close();
    p.color = kBlue.withOpacity(0.85);
    canvas.drawPath(path, p);

    // أخضر (أعلى يمين)
    path.reset();
    path.moveTo(cx, cy);
    path.lineTo(r, t);
    path.lineTo(r, b);
    path.close();
    p.color = kGreen.withOpacity(0.85);
    canvas.drawPath(path, p);

    // أصفر (أسفل يمين)
    path.reset();
    path.moveTo(cx, cy);
    path.lineTo(r, b);
    path.lineTo(l, b);
    path.close();
    p.color = kYellow.withOpacity(0.85);
    canvas.drawPath(path, p);

    // نجمة ذهبية في المركز
    p
      ..color = kGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(cx, cy), cs * 0.5, p);
    p.style = PaintingStyle.fill;
    p.color = kGold.withOpacity(0.2);
    canvas.drawCircle(Offset(cx, cy), cs * 0.5, p);
  }

  @override
  bool shouldRepaint(covariant _LudoBoardPainter old) =>
      old.numPlayers != numPlayers;
}

// ─── شاشة اختيار عدد اللاعبين ─────────────────────────────────────
class LudoSetupScreen extends StatefulWidget {
  const LudoSetupScreen({super.key});

  @override
  State<LudoSetupScreen> createState() => _LudoSetupScreenState();
}

class _LudoSetupScreenState extends State<LudoSetupScreen>
    with SingleTickerProviderStateMixin {
  int _selectedPlayers = 2;
  late AnimationController _enterCtrl;
  late Animation<double> _enterAnim;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _enterAnim = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A0A00),
              Color(0xFF3D1F08),
              Color(0xFF5C2F0F),
              Color(0xFF8B4513),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // هيدر
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
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
                              color: kGold.withOpacity(0.5), width: 1.5),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: kGold, size: 20),
                      ),
                    ),
                    const Spacer(),
                    Text('لودو المصري 🎲',
                        style: GoogleFonts.lalezar(
                            fontSize: 26,
                            color: kGold,
                            shadows: [
                              const Shadow(color: Colors.black54, blurRadius: 6)
                            ])),
                    const Spacer(),
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              Expanded(
                child: ScaleTransition(
                  scale: _enterAnim,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // رقعة اللودو المصغرة
                        _buildMiniBoardPreview(),

                        const SizedBox(height: 32),

                        // وصف اللعبة
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: kGold.withOpacity(0.4), width: 1.5),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('🪬',
                                      style: TextStyle(fontSize: 22)),
                                  const SizedBox(width: 8),
                                  Text('اللودو المصري الأصيل',
                                      style: GoogleFonts.lalezar(
                                          fontSize: 20, color: kGold)),
                                  const SizedBox(width: 8),
                                  const Text('🪬',
                                      style: TextStyle(fontSize: 22)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'حرّك قطعك 57 خطوة للوصول للمركز!\nرمي 6 = إخراج قطعة + دور إضافي\nضرب قطعة الخصم = ترجع للبداية',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.lalezar(
                                    fontSize: 14,
                                    color: Colors.white70,
                                    height: 1.5),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // اختيار عدد اللاعبين
                        Text('عدد اللاعبين',
                            style: GoogleFonts.lalezar(
                                fontSize: 22, color: Colors.white)),
                        const SizedBox(height: 16),

                        Row(
                          children: [2, 3, 4].map((count) {
                            final isSelected = _selectedPlayers == count;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  AudioService.playClick();
                                  setState(() => _selectedPlayers = count);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 4),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? kGold.withOpacity(0.9)
                                        : Colors.black38,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color:
                                            isSelected ? kGold : Colors.white24,
                                        width: isSelected ? 3 : 1.5),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                                color: kGold.withOpacity(0.4),
                                                blurRadius: 12)
                                          ]
                                        : [],
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '$count',
                                        style: GoogleFonts.lalezar(
                                            fontSize: 36,
                                            color: isSelected
                                                ? kDark
                                                : Colors.white70),
                                      ),
                                      Text(
                                        count == 2
                                            ? 'لاعبان'
                                            : count == 3
                                                ? '٣ لاعبين'
                                                : '٤ لاعبين',
                                        style: GoogleFonts.lalezar(
                                            fontSize: 12,
                                            color: isSelected
                                                ? kDark
                                                : Colors.white54),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: List.generate(
                                          count,
                                          (i) => Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 2),
                                            child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: kColors[i],
                                                border: Border.all(
                                                    color: Colors.white,
                                                    width: 1),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 32),

                        // زر البدء
                        GestureDetector(
                          onTap: () {
                            AudioService.playClick();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LudoGameScreen(
                                    playerCount: _selectedPlayers),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [kGold, Color(0xFFFF8F00)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border:
                                  Border.all(color: Colors.white.withOpacity(0.38), width: 2),
                              boxShadow: [
                                BoxShadow(
                                    color: kGold.withOpacity(0.5),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6)),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.play_arrow_rounded,
                                    color: kDark, size: 32),
                                const SizedBox(width: 12),
                                Text('ابدأ اللعبة!',
                                    style: GoogleFonts.lalezar(
                                        fontSize: 26, color: kDark)),
                                const SizedBox(width: 8),
                                const Text('🎲',
                                    style: TextStyle(fontSize: 24)),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniBoardPreview() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kGold, width: 2.5),
          boxShadow: [
            BoxShadow(
                color: kGold.withOpacity(0.3), blurRadius: 20, spreadRadius: 3)
          ],
        ),
        child: CustomPaint(
          painter: _LudoBoardPainter(numPlayers: _selectedPlayers),
        ),
      ),
    );
  }
}

// ─── ألوان قابلة للاستدعاء من الخارج ─────────────────────────────
// Constants pointing to private definitions below
class _LudoGameScreen {
  static const kHomeCells = _kHomeCells;
  static const kSafePath = _kSafePath;
  static const kStartPos = _kStartPos;
  static const kPathGrid = _kPathGrid;
}

const List<List<List<int>>> _kHomeCells = [
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

const List<List<List<int>>> _kSafePath = [
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

const List<int> _kStartPos = [1, 14, 27, 40];

const List<List<int>> _kPathGrid = [
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
