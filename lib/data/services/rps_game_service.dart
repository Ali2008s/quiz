import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class RPSGameState {
  final String roomId;
  final String player1Id;
  final String? player2Id;
  final String? player1Choice;
  final String? player2Choice;
  final int player1Score;
  final int player2Score;
  final String? roundWinner;

  RPSGameState({
    required this.roomId,
    required this.player1Id,
    this.player2Id,
    this.player1Choice,
    this.player2Choice,
    required this.player1Score,
    required this.player2Score,
    this.roundWinner,
  });

  factory RPSGameState.fromJson(Map<String, dynamic> json) {
    return RPSGameState(
      roomId: json['id'],
      player1Id: json['player1_id'],
      player2Id: json['player2_id'],
      player1Choice: json['player1_choice'],
      player2Choice: json['player2_choice'],
      player1Score: json['player1_score'] ?? 0,
      player2Score: json['player2_score'] ?? 0,
      roundWinner: json['round_winner'],
    );
  }
}

class RPSGameService {
  final _supabase = Supabase.instance.client;

  Stream<RPSGameState?> gameStream(String roomId) {
    late StreamController<RPSGameState?> controller;
    RealtimeChannel? channel;

    void subscribe() {
      channel = _supabase.channel('rps_game_$roomId');
      channel!
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'rps_games',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: roomId,
            ),
            callback: (payload) {
              if (!controller.isClosed) {
                try {
                  controller.add(RPSGameState.fromJson(payload.newRecord));
                } catch (_) {}
              }
            },
          )
          .subscribe();
    }

    controller = StreamController<RPSGameState?>.broadcast(
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

  Future<RPSGameState?> getRoom(String roomId) async {
    final response = await _supabase.from('rps_games').select().eq('id', roomId).maybeSingle();
    if (response != null) {
      return RPSGameState.fromJson(response);
    }
    return null;
  }

  Future<String> createRoom(String playerName) async {
    final roomId = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
    await _supabase.from('rps_games').insert({
      'id': roomId,
      'player1_id': playerName,
      'player1_score': 0,
      'player2_score': 0,
    });
    return roomId;
  }

  Future<void> joinRoom(String roomId, String playerName) async {
    await _supabase.from('rps_games').update({
      'player2_id': playerName,
    }).eq('id', roomId);
  }

  Future<String?> findRandomRoom(String playerName) async {
    final response = await _supabase
        .from('rps_games')
        .select('id')
        .filter('player2_id', 'is', null)
        .neq('player1_id', playerName)
        .limit(1)
        .maybeSingle();

    if (response != null) {
      final roomId = response['id'] as String;
      await joinRoom(roomId, playerName);
      return roomId;
    }
    return null;
  }

  Future<void> makeChoice(String roomId, String playerName, String choice, RPSGameState currentState) async {
    final isPlayer1 = playerName == currentState.player1Id;
    final updateData = isPlayer1 ? {'player1_choice': choice} : {'player2_choice': choice};
    
    await _supabase.from('rps_games').update(updateData).eq('id', roomId);
    
    // Check if both made choices to determine round winner
    final updated = await _supabase.from('rps_games').select().eq('id', roomId).single();
    if (updated['player1_choice'] != null && updated['player2_choice'] != null) {
      _processRoundResult(roomId, updated);
    }
  }

  void _processRoundResult(String roomId, Map<String, dynamic> data) async {
    final c1 = data['player1_choice'];
    final c2 = data['player2_choice'];
    String? winner;
    int s1 = data['player1_score'] ?? 0;
    int s2 = data['player2_score'] ?? 0;

    if (c1 == c2) {
      winner = 'Draw';
    } else if (
      (c1 == 'حجرة' && c2 == 'مقص') ||
      (c1 == 'ورقة' && c2 == 'حجرة') ||
      (c1 == 'مقص' && c2 == 'ورقة')
    ) {
      winner = 'player1';
      s1++;
    } else {
      winner = 'player2';
      s2++;
    }

    // Wait 2 seconds before resetting choices so players can see result
    Timer(const Duration(seconds: 2), () async {
      await _supabase.from('rps_games').update({
        'player1_choice': null,
        'player2_choice': null,
        'player1_score': s1,
        'player2_score': s2,
        'round_winner': winner,
      }).eq('id', roomId);
    });
  }

  Future<void> deleteRoom(String roomId) async {
    await _supabase.from('rps_games').delete().eq('id', roomId);
  }
}
