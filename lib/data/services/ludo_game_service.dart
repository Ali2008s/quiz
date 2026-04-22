import 'dart:async';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

// ─── ثوابت مسار اللودو ──────────────────────────────────────────────
const List<int> _kStartPos = [1, 14, 27, 40];
const int _kTotalSteps = 57;

const List<List<int>> _kPathGrid = [
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

const List<List<List<int>>> _kSafePath = [
  [[7, 13], [7, 12], [7, 11], [7, 10], [7, 9], [7, 8]],
  [[1, 7], [2, 7], [3, 7], [4, 7], [5, 7], [6, 7]],
  [[7, 1], [7, 2], [7, 3], [7, 4], [7, 5], [7, 6]],
  [[13, 7], [12, 7], [11, 7], [10, 7], [9, 7], [8, 7]],
];

// ─── نموذج حالة اللعبة ──────────────────────────────────────────────
class LudoOnlineState {
  final String roomId;
  final String player1Id;
  final String? player2Id;
  final String? player3Id;
  final String? player4Id;
  // مواضع القطع: قائمة من 4 أعداد (0=قاعدة, 1-57=مسار, 57=أكمل)
  final List<int> player1Pieces;
  final List<int> player2Pieces;
  final List<int> player3Pieces;
  final List<int> player4Pieces;
  final String currentTurn; // 'player1' .. 'player4'
  final int diceValue;
  final bool diceRolled;
  final String? winner;
  final int maxPlayers;
  final List<int> rankings; // مؤشرات اللاعبين الذين أكملوا بالترتيب

  LudoOnlineState({
    required this.roomId,
    required this.player1Id,
    this.player2Id,
    this.player3Id,
    this.player4Id,
    required this.player1Pieces,
    required this.player2Pieces,
    required this.player3Pieces,
    required this.player4Pieces,
    required this.currentTurn,
    required this.diceValue,
    required this.diceRolled,
    this.winner,
    required this.maxPlayers,
    required this.rankings,
  });

  factory LudoOnlineState.fromJson(Map<String, dynamic> json) {
    return LudoOnlineState(
      roomId: json['id'] ?? '',
      player1Id: json['player1_id'] ?? '',
      player2Id: json['player2_id'],
      player3Id: json['player3_id'],
      player4Id: json['player4_id'],
      player1Pieces: _parseIntList(json['player1_pieces'], 4),
      player2Pieces: _parseIntList(json['player2_pieces'], 4),
      player3Pieces: _parseIntList(json['player3_pieces'], 4),
      player4Pieces: _parseIntList(json['player4_pieces'], 4),
      currentTurn: json['current_turn'] ?? 'player1',
      diceValue: json['dice_value'] ?? 0,
      diceRolled: json['dice_rolled'] ?? false,
      winner: json['winner'],
      maxPlayers: json['max_players'] ?? 2,
      rankings: _parseIntList(json['rankings'], 0),
    );
  }

  static List<int> _parseIntList(dynamic val, int defaultLen) {
    if (val == null) return List.filled(defaultLen, 0);
    try {
      return List<int>.from((val as List).map((e) => (e as num).toInt()));
    } catch (_) {
      return List.filled(defaultLen, 0);
    }
  }

  List<int> getPieces(int playerIndex) {
    switch (playerIndex) {
      case 0: return player1Pieces;
      case 1: return player2Pieces;
      case 2: return player3Pieces;
      case 3: return player4Pieces;
      default: return [0, 0, 0, 0];
    }
  }

  String? getPlayerId(int playerIndex) {
    switch (playerIndex) {
      case 0: return player1Id;
      case 1: return player2Id;
      case 2: return player3Id;
      case 3: return player4Id;
      default: return null;
    }
  }

  int get currentPlayerIndex =>
      int.parse(currentTurn.replaceAll('player', '')) - 1;

  bool get isRoomFull {
    for (int i = 1; i < maxPlayers; i++) {
      if (getPlayerId(i) == null) return false;
    }
    return true;
  }

  int piecesHomeCount(int playerIndex) =>
      getPieces(playerIndex).where((p) => p == _kTotalSteps).length;
}

// ─── خدمة اللودو أونلاين ─────────────────────────────────────────────
class LudoGameService {
  final _supabase = Supabase.instance.client;

  // ── مجرى البيانات الفوري ──
  Stream<LudoOnlineState?> gameStream(String roomId) {
    late StreamController<LudoOnlineState?> controller;
    RealtimeChannel? channel;

    void subscribe() {
      channel = _supabase.channel('ludo_game_$roomId');
      channel!
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'ludo_games',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: roomId,
            ),
            callback: (payload) {
              if (!controller.isClosed) {
                try {
                  controller.add(LudoOnlineState.fromJson(payload.newRecord));
                } catch (e) {
                  debugPrint('Ludo parse error: $e');
                }
              }
            },
          )
          .subscribe((status, [err]) {
        debugPrint('Ludo Realtime: $status');
      });
    }

    controller = StreamController<LudoOnlineState?>.broadcast(
      onListen: subscribe,
      onCancel: () {
        if (channel != null) {
          _supabase.removeChannel(channel!);
          channel = null;
        }
      },
    );
    return controller.stream;
  }

  // ── جلب البيانات مرة واحدة ──
  Future<LudoOnlineState?> getGameData(String roomId) async {
    final response = await _supabase
        .from('ludo_games')
        .select()
        .eq('id', roomId)
        .maybeSingle();
    if (response == null) return null;
    return LudoOnlineState.fromJson(response);
  }

  // ── إنشاء غرفة ──
  Future<String> createRoom(String playerName, {int maxPlayers = 2}) async {
    final roomId = (1000 + Random().nextInt(9000)).toString();
    await _supabase.from('ludo_games').insert({
      'id': roomId,
      'player1_id': playerName,
      'player1_pieces': [0, 0, 0, 0],
      'player2_pieces': [0, 0, 0, 0],
      'player3_pieces': [0, 0, 0, 0],
      'player4_pieces': [0, 0, 0, 0],
      'current_turn': 'player1',
      'dice_value': 0,
      'dice_rolled': false,
      'winner': null,
      'max_players': maxPlayers,
      'rankings': [],
    });
    return roomId;
  }

  // ── الانضمام لغرفة ──
  Future<void> joinRoom(String roomId, String playerName) async {
    final response = await _supabase
        .from('ludo_games')
        .select()
        .eq('id', roomId)
        .maybeSingle();

    if (response == null) {
      throw Exception('عذراً، كود الغرفة غير صحيح أو تم حذف الغرفة.');
    }
    final state = response;

    // إذا كان موجوداً بالفعل
    if (state['player1_id'] == playerName ||
        state['player2_id'] == playerName ||
        state['player3_id'] == playerName ||
        state['player4_id'] == playerName) return;

    int max = state['max_players'] ?? 2;
    String? slot;
    if (max >= 2 && state['player2_id'] == null) {
      slot = 'player2_id';
    } else if (max >= 3 && state['player3_id'] == null) {
      slot = 'player3_id';
    } else if (max >= 4 && state['player4_id'] == null) {
      slot = 'player4_id';
    }

    if (slot != null) {
      await _supabase
          .from('ludo_games')
          .update({slot: playerName}).eq('id', roomId);
    } else {
      throw Exception('الغرفة ممتلئة!');
    }
  }

  // ── رمي الزهر ──
  Future<void> rollDice(
      String roomId, LudoOnlineState state, int diceValue) async {
    final playerIdx = state.currentPlayerIndex;
    final pieces = state.getPieces(playerIdx);

    // هل توجد قطع قابلة للتحريك؟
    bool hasMovable = false;
    for (int i = 0; i < 4; i++) {
      final pos = pieces[i];
      if (pos == _kTotalSteps) continue;
      if (pos == 0 && diceValue == 6) {
        hasMovable = true;
        break;
      }
      if (pos > 0 && pos + diceValue <= _kTotalSteps) {
        hasMovable = true;
        break;
      }
    }

    if (!hasMovable) {
      // لا حركة ممكنة - انتقل للاعب التالي
      await _supabase.from('ludo_games').update({
        'dice_value': diceValue,
        'dice_rolled': false,
        'current_turn':
            _getNextTurn(state.currentTurn, state.maxPlayers, state.rankings),
      }).eq('id', roomId);
    } else {
      await _supabase.from('ludo_games').update({
        'dice_value': diceValue,
        'dice_rolled': true,
      }).eq('id', roomId);
    }
  }

  // ── تحريك قطعة ──
  Future<bool> movePiece(
      String roomId, int pieceIndex, LudoOnlineState state) async {
    final playerIdx = state.currentPlayerIndex;
    final diceValue = state.diceValue;

    // نسخ مواضع جميع القطع
    final allPieces = [
      List<int>.from(state.player1Pieces),
      List<int>.from(state.player2Pieces),
      List<int>.from(state.player3Pieces),
      List<int>.from(state.player4Pieces),
    ];

    final oldPos = allPieces[playerIdx][pieceIndex];
    bool gotHome = false;
    bool extraTurn = diceValue == 6;

    // تحريك القطعة
    if (oldPos == 0) {
      allPieces[playerIdx][pieceIndex] = 1;
    } else {
      allPieces[playerIdx][pieceIndex] = oldPos + diceValue;
    }

    // وصلت البيت؟
    if (allPieces[playerIdx][pieceIndex] >= _kTotalSteps) {
      allPieces[playerIdx][pieceIndex] = _kTotalSteps;
      gotHome = true;
      extraTurn = true;
    }

    // تحقق من ضرب قطع الخصم
    bool killed = false;
    if (!gotHome) {
      final movedPos = allPieces[playerIdx][pieceIndex];
      final movedCell = _getGridCell(playerIdx, movedPos);

      if (movedCell != null && !_isSafeCell(movedCell)) {
        for (int p = 0; p < state.maxPlayers; p++) {
          if (p == playerIdx) continue;
          for (int i = 0; i < 4; i++) {
            final oPos = allPieces[p][i];
            if (oPos == 0 || oPos == _kTotalSteps) continue;
            final oCell = _getGridCell(p, oPos);
            if (oCell != null &&
                oCell[0] == movedCell[0] &&
                oCell[1] == movedCell[1]) {
              allPieces[p][i] = 0;
              killed = true;
            }
          }
        }
      }
    }

    // التحقق من الفوز
    String? winner;
    final rankings = List<int>.from(state.rankings);
    final piecesHome =
        allPieces[playerIdx].where((p) => p == _kTotalSteps).length;

    if (piecesHome == 4 && !rankings.contains(playerIdx)) {
      rankings.add(playerIdx);
      if (rankings.length == 1) {
        winner = state.getPlayerId(playerIdx) ?? 'اللاعب ${playerIdx + 1}';
      }
    }

    // تحديد الدور التالي
    String nextTurn = extraTurn && winner == null
        ? state.currentTurn
        : _getNextTurn(state.currentTurn, state.maxPlayers, rankings);

    // تحديث Supabase
    await _supabase.from('ludo_games').update({
      'player1_pieces': allPieces[0],
      'player2_pieces': allPieces[1],
      'player3_pieces': allPieces[2],
      'player4_pieces': allPieces[3],
      'current_turn': nextTurn,
      'dice_value': 0,
      'dice_rolled': false,
      'winner': winner,
      'rankings': rankings,
    }).eq('id', roomId);

    return killed;
  }

  // ── حذف الغرفة ──
  Future<void> deleteRoom(String roomId) async {
    await _supabase.from('ludo_games').delete().eq('id', roomId);
  }

  // ── الدور التالي (مع تخطي من أنهى) ──
  String _getNextTurn(String current, int max, List<int> rankings) {
    int cur = int.parse(current.replaceAll('player', '')) - 1;
    int next = (cur + 1) % max;
    int attempts = 0;
    while (rankings.contains(next) && attempts < max) {
      next = (next + 1) % max;
      attempts++;
    }
    return 'player${next + 1}';
  }

  // ── حساب موضع الشبكة من موضع المسار ──
  List<int>? _getGridCell(int playerIndex, int pos) {
    if (pos == 0 || pos == _kTotalSteps) return null;
    final startIdx = _kStartPos[playerIndex] - 1;
    int p = pos - 1;

    if (p < 51) {
      int pathIdx = (startIdx + p) % _kPathGrid.length;
      return _kPathGrid[pathIdx];
    } else {
      int safeIdx = p - 51;
      if (safeIdx < _kSafePath[playerIndex].length) {
        return _kSafePath[playerIndex][safeIdx];
      }
      return null;
    }
  }

  // ── هل الخلية آمنة؟ ──
  bool _isSafeCell(List<int> cell) {
    for (int p = 0; p < 4; p++) {
      final startOnPath = _kStartPos[p] - 1;
      if (startOnPath >= 0 && startOnPath < _kPathGrid.length) {
        if (_kPathGrid[startOnPath][0] == cell[0] &&
            _kPathGrid[startOnPath][1] == cell[1]) {
          return true;
        }
      }
      for (var sc in _kSafePath[p]) {
        if (sc[0] == cell[0] && sc[1] == cell[1]) return true;
      }
    }
    return false;
  }
}
