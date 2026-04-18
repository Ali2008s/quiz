import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class XOGameState {
  final String roomId;
  final List<String> board;
  final String player1Id;
  final String? player2Id;
  final String currentTurn; // 'player1' or 'player2'
  final String? winner;

  XOGameState({
    required this.roomId,
    required this.board,
    required this.player1Id,
    this.player2Id,
    required this.currentTurn,
    this.winner,
  });

  factory XOGameState.fromJson(Map<String, dynamic> json) {
    return XOGameState(
      roomId: json['id'],
      board: List<String>.from(json['board']),
      player1Id: json['player1_id'],
      player2Id: json['player2_id'],
      currentTurn: json['current_turn'],
      winner: json['winner'],
    );
  }
}

class XOGameService {
  final _supabase = Supabase.instance.client;

  // Stream to listen to game changes
  Stream<XOGameState?> gameStream(String roomId) {
    return _supabase
        .from('xo_games')
        .stream(primaryKey: ['id'])
        .eq('id', roomId)
        .map((data) => data.isEmpty ? null : XOGameState.fromJson(data.first));
  }

  // Get current room state manually
  Future<XOGameState?> getRoom(String roomId) async {
    final response = await _supabase
        .from('xo_games')
        .select()
        .eq('id', roomId)
        .maybeSingle();
    return response == null ? null : XOGameState.fromJson(response);
  }

  // Create a new room
  Future<String> createRoom(String playerName) async {
    final roomId =
        (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
    await _supabase.from('xo_games').insert({
      'id': roomId,
      'player1_id': playerName,
      'player2_id': null,
      'board': List.generate(9, (index) => ''),
      'current_turn': 'player1',
      'winner': null,
    });
    return roomId;
  }

  // Join an existing room
  Future<void> joinRoom(String roomId, String playerName) async {
    await _supabase.from('xo_games').update({
      'player2_id': playerName,
    }).eq('id', roomId);
  }

  // Find a random available room or return null
  Future<String?> findRandomRoom(String playerName) async {
    final response = await _supabase
        .from('xo_games')
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

  // Make a move
  Future<void> makeMove(String roomId, int index, String playerType,
      List<String> newBoard, String? winner) async {
    await _supabase.from('xo_games').update({
      'board': newBoard,
      'current_turn': playerType == 'player1' ? 'player2' : 'player1',
      'winner': winner,
    }).eq('id', roomId);
  }

  // Delete a room
  Future<void> deleteRoom(String roomId) async {
    await _supabase.from('xo_games').delete().eq('id', roomId);
  }

  // Reset a room for a new match
  Future<void> resetRoom(String roomId) async {
    await _supabase.from('xo_games').update({
      'board': List.generate(9, (index) => ''),
      'current_turn': 'player1',
      'winner': null,
    }).eq('id', roomId);
  }
}
