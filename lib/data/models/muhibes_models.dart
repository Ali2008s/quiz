enum HandStatus { closed, open, ring }

class Player {
  final String id;
  final String name;
  final int score;

  Player({required this.id, required this.name, this.score = 0});

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      score: json['score'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'score': score,
      };

  Player copyWith({String? id, String? name, int? score}) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      score: score ?? this.score,
    );
  }
}

class MuhibesGameState {
  final String roomId;
  final Player? player1;
  final Player? player2;
  final String currentTurn; // ID of the player currently acting (the guesser)
  final String hiderId; // ID of the player who has the ring
  final String state; // waiting, playing, roundEnded
  final List<HandStatus> handsPlayer1;
  final List<HandStatus> handsPlayer2;
  final int ringPosition; // 0-5
  final String lastMoveAction; // hit, guess, skip
  final int lastMovePosition;
  final String winnerId;

  MuhibesGameState({
    required this.roomId,
    this.player1,
    this.player2,
    required this.currentTurn,
    required this.hiderId,
    required this.state,
    required this.handsPlayer1,
    required this.handsPlayer2,
    required this.ringPosition,
    this.lastMoveAction = '',
    this.lastMovePosition = -1,
    this.winnerId = '',
  });

  factory MuhibesGameState.fromJson(Map<String, dynamic> json) {
    return MuhibesGameState(
      roomId: json['id']?.toString() ?? '',
      player1: json['player1'] != null ? Player.fromJson(json['player1']) : null,
      player2: json['player2'] != null ? Player.fromJson(json['player2']) : null,
      currentTurn: json['current_turn']?.toString() ?? '',
      hiderId: json['hider_id']?.toString() ?? '',
      state: json['state']?.toString() ?? 'waiting',
      handsPlayer1: _parseHands(json['hands_player1']),
      handsPlayer2: _parseHands(json['hands_player2']),
      ringPosition: json['ring_position'] ?? -1,
      lastMoveAction: json['last_move_action'] ?? '',
      lastMovePosition: json['last_move_position'] ?? -1,
      winnerId: json['winner_id']?.toString() ?? '',
    );
  }

  static List<HandStatus> _parseHands(dynamic hands) {
    if (hands == null) return List.filled(6, HandStatus.closed);
    return (hands as List).map((e) {
      if (e == 'closed') return HandStatus.closed;
      if (e == 'open') return HandStatus.open;
      if (e == 'ring') return HandStatus.ring;
      return HandStatus.closed;
    }).toList();
  }

  Map<String, dynamic> toJson() => {
    'player1': player1?.toJson(),
    'player2': player2?.toJson(),
    'current_turn': currentTurn,
    'hider_id': hiderId,
    'state': state,
    'hands_player1': handsPlayer1.map((e) => e.name).toList(),
    'hands_player2': handsPlayer2.map((e) => e.name).toList(),
    'ring_position': ringPosition,
    'last_move_action': lastMoveAction,
    'last_move_position': lastMovePosition,
    'winner_id': winnerId,
  };
}
