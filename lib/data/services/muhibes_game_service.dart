import 'dart:async';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/muhibes_models.dart';

class MuhibesGameService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final StreamController<MuhibesGameState> _gameStreamController = StreamController<MuhibesGameState>.broadcast();
  RealtimeChannel? _channel;
  MuhibesGameState? _currentState;
  String? _myPlayerId;

  // Real-time access
  MuhibesGameState? get currentState => _currentState;
  String? get myPlayerId => _myPlayerId;
  Stream<MuhibesGameState> get gameStream => _gameStreamController.stream;

  // Initialize and get Room stream
  Future<void> listenToRoom(String roomId) async {
    // Initial Fetch
    final response = await _supabase.from('rooms').select().eq('id', roomId).maybeSingle();
    if (response != null) {
      _updateLocalStateFromPayload(response);
    }

    // Subscribe to changes
    _channel = _supabase.channel('room:$roomId').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'rooms',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: roomId,
      ),
      callback: (payload) {
        if (payload.newRecord.isNotEmpty) {
          _updateLocalStateFromPayload(payload.newRecord);
        }
      },
    );

    await _channel!.subscribe();
  }

  void _updateLocalStateFromPayload(Map<String, dynamic> data) {
    _currentState = MuhibesGameState.fromJson(data);
    _gameStreamController.add(_currentState!);
  }

  // Room Management
  Future<String> createRoom(String playerName) async {
    _myPlayerId = DateTime.now().millisecondsSinceEpoch.toString();
    final player = Player(id: _myPlayerId!, name: playerName);

    final roomData = {
      'player1': player.toJson(),
      'state': 'waiting',
      'current_turn': _myPlayerId,
      'hider_id': '',
      'hands_player1': List.filled(6, 'closed'),
      'hands_player2': List.filled(6, 'closed'),
      'ring_position': -1,
      'last_move_action': '',
      'last_move_position': -1,
      'winner_id': '',
    };

    final response = await _supabase.from('rooms').insert(roomData).select().single();
    final roomId = response['id'].toString();
    await listenToRoom(roomId);
    return roomId;
  }

  Future<void> joinRoom(String roomId, String playerName) async {
    _myPlayerId = DateTime.now().millisecondsSinceEpoch.toString();
    final player = Player(id: _myPlayerId!, name: playerName);

    // Get current room state to make sure it exists
    final response = await _supabase.from('rooms').select().eq('id', roomId).maybeSingle();
    if (response == null) throw Exception('Room not found');
    if (response['player2'] != null) throw Exception('Room is full');

    await _supabase.from('rooms').update({
      'player2': player.toJson(),
      'state': 'playing',
    }).eq('id', roomId);

    await listenToRoom(roomId);
    await startNewRound();
  }

  // Game Logic
  Future<void> startNewRound() async {
    if (_currentState == null) return;

    // In a round, one player has the ring. 
    // If not set, let's alternate or pick randomly
    final random = Random();
    String? nextHiderId;
    if (_currentState!.hiderId.isEmpty) {
      nextHiderId = random.nextBool() ? _currentState!.player1?.id : _currentState!.player2?.id;
    } else {
      // Alternate hider every round
      nextHiderId = (_currentState!.hiderId == _currentState!.player1?.id)
          ? (_currentState!.player2?.id ?? '')
          : (_currentState!.player1?.id ?? '');
    }

    final guesserId = (nextHiderId == _currentState!.player1?.id)
        ? (_currentState!.player2?.id ?? '')
        : (_currentState!.player1?.id ?? '');

    final ringPos = random.nextInt(6); // Ring is in hands of nextHiderId

    await _supabase.from('rooms').update({
      'current_turn': guesserId,
      'hider_id': nextHiderId,
      'state': 'playing',
      'ring_position': ringPos,
      'hands_player1': List.filled(6, 'closed'),
      'hands_player2': List.filled(6, 'closed'),
      'last_move_action': 'start',
      'last_move_position': -1,
      'winner_id': '',
    }).eq('id', _currentState!.roomId);
  }

  Future<void> hit(int position) async {
    if (_currentState == null || _currentState!.state != 'playing') return;
    if (_currentState!.currentTurn != _myPlayerId) return;

    // Check hit on hider's hands
    final isP1Hider = _currentState!.hiderId == _currentState!.player1?.id;
    List<HandStatus> hands = isP1Hider ? List.from(_currentState!.handsPlayer1) : List.from(_currentState!.handsPlayer2);

    if (_currentState!.ringPosition == position) {
      // "طك" the hand with the ring? Hider wins round!
      hands[position] = HandStatus.ring;
      await _finishRound(false, action: 'hit', position: position);
    } else {
      hands[position] = HandStatus.open;
      await _supabase.from('rooms').update({
        isP1Hider ? 'hands_player1' : 'hands_player2': hands.map((e) => e.name).toList(),
        'last_move_action': 'hit',
        'last_move_position': position,
      }).eq('id', _currentState!.roomId);
    }
  }

  Future<void> guess(int position) async {
    if (_currentState == null || _currentState!.state != 'playing') return;
    if (_currentState!.currentTurn != _myPlayerId) return;

    if (_currentState!.ringPosition == position) {
      // Correct! Guesser wins
      await _finishRound(true, action: 'guess', position: position);
    } else {
      // Incorrect! Switch turn? 
      // User says "إذا خطأ: تبديل الدور"
      await _switchTurn(action: 'guess', position: position);
    }
  }

  Future<void> _switchTurn({required String action, required int position}) async {
    final nextTurn = (_currentState!.currentTurn == _currentState!.player1?.id)
        ? _currentState!.player2?.id
        : _currentState!.player1?.id;

    await _supabase.from('rooms').update({
      'current_turn': nextTurn,
      'last_move_action': action,
      'last_move_position': position,
    }).eq('id', _currentState!.roomId);
  }

  Future<void> _finishRound(bool guesserWon, {required String action, required int position}) async {
    final winnerId = guesserWon ? _currentState!.currentTurn : _currentState!.hiderId;
    
    // Update score
    Player? p1 = _currentState!.player1;
    Player? p2 = _currentState!.player2;

    if (winnerId == p1?.id) {
      p1 = p1?.copyWith(score: (p1.score) + 1);
    } else if (winnerId == p2?.id) {
      p2 = p2?.copyWith(score: (p2.score) + 1);
    }

    // Reveal ring position in hider hands
    final isP1Hider = _currentState!.hiderId == _currentState!.player1?.id;
    List<HandStatus> hands = isP1Hider ? List.from(_currentState!.handsPlayer1) : List.from(_currentState!.handsPlayer2);
    hands[_currentState!.ringPosition] = HandStatus.ring;

    await _supabase.from('rooms').update({
      'state': 'roundEnded',
      'player1': p1?.toJson(),
      'player2': p2?.toJson(),
      'winner_id': winnerId,
      'last_move_action': action,
      'last_move_position': position,
      isP1Hider ? 'hands_player1' : 'hands_player2': hands.map((e) => e.name).toList(),
    }).eq('id', _currentState!.roomId);
  }

  Future<void> skipTurn() async {
    await _switchTurn(action: 'skip', position: -1);
  }

  Future<void> continueGame() async {
    await startNewRound();
  }

  void dispose() {
    _channel?.unsubscribe();
    _gameStreamController.close();
  }
}
