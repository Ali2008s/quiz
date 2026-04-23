/// =====================================================================
/// خدمة XO المحلية (Local Room / Simulated Bluetooth via LAN)
/// =====================================================================
/// هذا الملف يوفر آلية لعب XO عبر اتصال محلي.
/// بما أن Flutter لا يدعم البلوتوث مباشرة دون مكتبات إضافية تتطلب أذونات
/// معقدة، نستخدم نظام غرف "بلوتوث" مُحاكاة عبر Supabase بكود رمزي قصير
/// يمكن مشاركته محلياً (يُنصح به للاستخدام على شبكة نفس الـ WiFi أو قرب
/// بعض). هذا يحقق تجربة شبيهة بالبلوتوث من حيث الكود القصير والاتصال الفوري.
///
/// للبلوتوث الحقيقي: أضف مكتبة flutter_bluetooth_serial أو nearby_connections
/// وهي تتطلب أذونات وإعدادات Android إضافية.
///
/// =====================================================================

import 'dart:async';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

enum ConnectionMode { internet, localNetwork }

class LocalXOState {
  final String roomId;
  final List<String> board;
  final String player1Id;
  final String? player2Id;
  final String currentTurn;
  final String? winner;
  final bool isLocalMode;

  LocalXOState({
    required this.roomId,
    required this.board,
    required this.player1Id,
    this.player2Id,
    required this.currentTurn,
    this.winner,
    this.isLocalMode = false,
  });

  factory LocalXOState.fromJson(Map<String, dynamic> json) {
    return LocalXOState(
      roomId: json['id'],
      board: List<String>.from(json['board']),
      player1Id: json['player1_id'],
      player2Id: json['player2_id'],
      currentTurn: json['current_turn'],
      winner: json['winner'],
      isLocalMode: json['is_local'] ?? false,
    );
  }
}

class BluetoothXOService {
  final _supabase = Supabase.instance.client;

  /// إنشاء غرفة محلية (كود 4 أرقام بسيط)
  Future<String> createLocalRoom(String playerName) async {
    // كود قصير من 4 أرقام لسهولة المشاركة المحلية
    final roomId = (1000 + Random().nextInt(9000)).toString();
    await _supabase.from('xo_games').insert({
      'id': roomId,
      'player1_id': playerName,
      'player2_id': null,
      'board': List.generate(9, (index) => ''),
      'current_turn': 'player1',
      'winner': null,
      'is_local': true,
    });
    return roomId;
  }

  /// الانضمام لغرفة محلية
  Future<void> joinLocalRoom(String roomId, String playerName) async {
    final response = await _supabase
        .from('xo_games')
        .select()
        .eq('id', roomId)
        .maybeSingle();

    if (response == null) {
      throw Exception('الغرفة غير موجودة! تحقق من الكود');
    }
    if (response['player2_id'] != null) {
      throw Exception('الغرفة ممتلئة!');
    }
    if (response['player1_id'] == playerName) {
      throw Exception('لا يمكنك الانضمام لغرفتك الخاصة!');
    }

    await _supabase.from('xo_games').update({
      'player2_id': playerName,
    }).eq('id', roomId);
  }

  /// مجرى البيانات
  Stream<LocalXOState?> gameStream(String roomId) {
    late StreamController<LocalXOState?> controller;
    RealtimeChannel? channel;

    void subscribe() {
      channel = _supabase.channel('local_xo_$roomId');
      channel!
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'xo_games',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: roomId,
            ),
            callback: (payload) {
              if (!controller.isClosed) {
                try {
                  controller.add(LocalXOState.fromJson(payload.newRecord));
                } catch (_) {}
              }
            },
          )
          .subscribe();
    }

    controller = StreamController<LocalXOState?>.broadcast(
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

  Future<LocalXOState?> getRoom(String roomId) async {
    final response = await _supabase
        .from('xo_games')
        .select()
        .eq('id', roomId)
        .maybeSingle();
    return response == null ? null : LocalXOState.fromJson(response);
  }

  Future<void> makeMove(String roomId, int index, String playerType,
      List<String> newBoard, String? winner) async {
    await _supabase.from('xo_games').update({
      'board': newBoard,
      'current_turn': playerType == 'player1' ? 'player2' : 'player1',
      'winner': winner,
    }).eq('id', roomId);
  }

  Future<void> deleteRoom(String roomId) async {
    await _supabase.from('xo_games').delete().eq('id', roomId);
  }

  Future<void> resetRoom(String roomId) async {
    await _supabase.from('xo_games').update({
      'board': List.generate(9, (index) => ''),
      'current_turn': 'player1',
      'winner': null,
    }).eq('id', roomId);
  }
}
