import 'dart:async';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class DominoPiece {
  final int side1;
  final int side2;

  DominoPiece(this.side1, this.side2);

  Map<String, dynamic> toJson() => {'s1': side1, 's2': side2};
  factory DominoPiece.fromJson(Map<String, dynamic> json) =>
      DominoPiece(json['s1'], json['s2']);

  @override
  bool operator ==(Object other) =>
      other is DominoPiece && side1 == other.side1 && side2 == other.side2;
  @override
  int get hashCode => side1.hashCode ^ side2.hashCode;
}

class DominoGameState {
  final String roomId;
  final String player1Id;
  final String? player2Id;
  final String? player3Id;
  final String? player4Id;
  final List<DominoPiece> player1Hand;
  final List<DominoPiece> player2Hand;
  final List<DominoPiece> player3Hand;
  final List<DominoPiece> player4Hand;
  final List<DominoPiece> board;
  final String currentTurn;
  final String? winner;
  final int maxPlayers;
  final String difficulty;

  DominoGameState({
    required this.roomId,
    required this.player1Id,
    this.player2Id,
    this.player3Id,
    this.player4Id,
    required this.player1Hand,
    required this.player2Hand,
    required this.player3Hand,
    required this.player4Hand,
    required this.board,
    required this.currentTurn,
    this.winner,
    required this.maxPlayers,
    required this.difficulty,
  });

  factory DominoGameState.fromJson(Map<String, dynamic> json) {
    return DominoGameState(
      roomId: json['id'],
      player1Id: json['player1_id'] ?? '',
      player2Id: json['player2_id'],
      player3Id: json['player3_id'],
      player4Id: json['player4_id'],
      player1Hand: (json['player1_hand'] as List? ?? [])
          .map((e) => DominoPiece.fromJson(e))
          .toList(),
      player2Hand: (json['player2_hand'] as List? ?? [])
          .map((e) => DominoPiece.fromJson(e))
          .toList(),
      player3Hand: (json['player3_hand'] as List? ?? [])
          .map((e) => DominoPiece.fromJson(e))
          .toList(),
      player4Hand: (json['player4_hand'] as List? ?? [])
          .map((e) => DominoPiece.fromJson(e))
          .toList(),
      board: (json['board'] as List? ?? [])
          .map((e) => DominoPiece.fromJson(e))
          .toList(),
      currentTurn: json['current_turn'] ?? 'player1',
      winner: json['winner'],
      maxPlayers: json['max_players'] ?? 4,
      difficulty: json['difficulty'] ?? 'medium',
    );
  }
}

class DominoGameService {
  final _supabase = Supabase.instance.client;

  Stream<DominoGameState?> gameStream(String roomId) {
    return _supabase
        .from('domino_games')
        .stream(primaryKey: ['id'])
        .eq('id', roomId)
        .map((data) =>
            data.isEmpty ? null : DominoGameState.fromJson(data.first));
  }

  Future<DominoGameState?> getGameData(String roomId) async {
    final response = await _supabase
        .from('domino_games')
        .select()
        .eq('id', roomId)
        .maybeSingle();
    if (response == null) return null;
    return DominoGameState.fromJson(response);
  }

  Future<String> createRoom(String playerName,
      {int maxPlayers = 4,
      String difficulty = 'medium',
      bool vsAI = false}) async {
    final roomId = (1000 + (Random().nextInt(9000))).toString();

    List<DominoPiece> deck = [];
    for (int i = 0; i <= 6; i++) {
      for (int j = i; j <= 6; j++) deck.add(DominoPiece(i, j));
    }
    deck.shuffle();

    final p1Hand = deck.sublist(0, 7);
    final p2Hand = deck.sublist(7, 14);
    final p3Hand = deck.sublist(14, 21);
    final p4Hand = deck.sublist(21, 28);

    Map<String, dynamic> data = {
      'id': roomId,
      'player1_id': playerName,
      'player1_hand': p1Hand.map((e) => e.toJson()).toList(),
      'player2_hand': p2Hand.map((e) => e.toJson()).toList(),
      'player3_hand': p3Hand.map((e) => e.toJson()).toList(),
      'player4_hand': p4Hand.map((e) => e.toJson()).toList(),
      'board': [],
      'current_turn': 'player1',
      'max_players': maxPlayers,
      'difficulty': difficulty,
    };

    if (vsAI) {
      if (maxPlayers >= 2) data['player2_id'] = 'ذكاء اصطناعي 🤖';
      if (maxPlayers >= 3) data['player3_id'] = 'ذكاء اصطناعي 🤖';
      if (maxPlayers >= 4) data['player4_id'] = 'ذكاء اصطناعي 🤖';
    }

    await _supabase.from('domino_games').insert(data);
    return roomId;
  }

  Future<void> joinRoom(String roomId, String playerName) async {
    final state =
        await _supabase.from('domino_games').select().eq('id', roomId).single();
    int max = state['max_players'] ?? 4;

    if (state['player1_id'] == playerName ||
        state['player2_id'] == playerName ||
        state['player3_id'] == playerName ||
        state['player4_id'] == playerName) return;

    String? slot;
    if (max >= 2 && state['player2_id'] == null)
      slot = 'player2_id';
    else if (max >= 3 && state['player3_id'] == null)
      slot = 'player3_id';
    else if (max >= 4 && state['player4_id'] == null) slot = 'player4_id';

    if (slot != null) {
      await _supabase
          .from('domino_games')
          .update({slot: playerName}).eq('id', roomId);
    } else {
      throw Exception('الغرفة ممتلئة!');
    }
  }

  Future<void> makeMove(String roomId, DominoPiece piece, bool atEnd,
      DominoGameState state) async {
    final List<DominoPiece> newBoard = List.from(state.board);
    final Map<String, List<DominoPiece>> hands = {
      'player1': List.from(state.player1Hand),
      'player2': List.from(state.player2Hand),
      'player3': List.from(state.player3Hand),
      'player4': List.from(state.player4Hand),
    };

    final turn = state.currentTurn;
    DominoPiece played = piece;

    if (newBoard.isNotEmpty) {
      int target = atEnd ? newBoard.last.side2 : newBoard.first.side1;
      if (atEnd) {
        if (piece.side1 != target)
          played = DominoPiece(piece.side2, piece.side1);
      } else {
        if (piece.side2 != target)
          played = DominoPiece(piece.side2, piece.side1);
      }
    }

    if (atEnd)
      newBoard.add(played);
    else
      newBoard.insert(0, played);
    hands[turn]!.removeWhere((p) => p == piece);

    String? winner;
    if (hands[turn]!.isEmpty) {
      if (state.maxPlayers == 4) {
        winner = (turn == 'player1' || turn == 'player3')
            ? "الفريق الأول 🏆"
            : "الفريق الثاني 🏆";
      } else {
        winner = (turn == 'player1')
            ? (state.player1Id)
            : (state.player2Id ?? "الخصم");
      }
    }

    String nextTurn = _getNextTurn(turn, state.maxPlayers);

    await _supabase.from('domino_games').update({
      'board': newBoard.map((e) => e.toJson()).toList(),
      'player1_hand': hands['player1']!.map((e) => e.toJson()).toList(),
      'player2_hand': hands['player2']!.map((e) => e.toJson()).toList(),
      'player3_hand': hands['player3']!.map((e) => e.toJson()).toList(),
      'player4_hand': hands['player4']!.map((e) => e.toJson()).toList(),
    }).eq('id', roomId);

    // Actually simpler fix for the update:
    await _supabase.from('domino_games').update({
      'board': newBoard.map((e) => e.toJson()).toList(),
      'player1_hand': hands['player1']!.map((e) => e.toJson()).toList(),
      'player2_hand': hands['player2']!.map((e) => e.toJson()).toList(),
      'player3_hand': hands['player3']!.map((e) => e.toJson()).toList(),
      'player4_hand': hands['player4']!.map((e) => e.toJson()).toList(),
      'current_turn': nextTurn,
      'winner': winner,
    }).eq('id', roomId);
  }

  String _getNextTurn(String current, int max) {
    int curNum = int.parse(current.replaceAll('player', ''));
    int next = curNum + 1;
    if (next > max) next = 1;
    return 'player$next';
  }

  Future<void> passTurn(String roomId, DominoGameState state) async {
    await _supabase.from('domino_games').update({
      'current_turn': _getNextTurn(state.currentTurn, state.maxPlayers),
    }).eq('id', roomId);
  }

  Future<void> deleteRoom(String roomId) async {
    await _supabase.from('domino_games').delete().eq('id', roomId);
  }
}
