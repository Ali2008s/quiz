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
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

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
    this.isLocalMode = true,
  });

  LocalXOState copyWith({
    String? roomId,
    List<String>? board,
    String? player1Id,
    String? player2Id,
    String? currentTurn,
    String? winner,
  }) {
    return LocalXOState(
      roomId: roomId ?? this.roomId,
      board: board ?? this.board,
      player1Id: player1Id ?? this.player1Id,
      player2Id: player2Id ?? this.player2Id,
      currentTurn: currentTurn ?? this.currentTurn,
      winner: winner ?? this.winner,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'board': board,
      'player1Id': player1Id,
      'player2Id': player2Id,
      'currentTurn': currentTurn,
      'winner': winner,
    };
  }

  factory LocalXOState.fromJson(Map<String, dynamic> json) {
    return LocalXOState(
      roomId: json['roomId'],
      board: List<String>.from(json['board']),
      player1Id: json['player1Id'],
      player2Id: json['player2Id'],
      currentTurn: json['currentTurn'],
      winner: json['winner'],
    );
  }
}

class BluetoothXOService {
  static final BluetoothXOService _instance = BluetoothXOService._internal();
  factory BluetoothXOService() => _instance;
  BluetoothXOService._internal();

  final Strategy strategy = Strategy.P2P_STAR;
  String? connectedEndpointId;
  String? _myRole; // 'player1' or 'player2'

  final StreamController<LocalXOState?> _stateController =
      StreamController<LocalXOState?>.broadcast();
  LocalXOState? _currentState;

  Stream<LocalXOState?> get gameStream => _stateController.stream;

  Future<bool> requestPermissions() async {
    // طلب الأذونات المطلوبة
    final List<Permission> permissions = [
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.locationWhenInUse,
      Permission.nearbyWifiDevices,
    ];

    // تحقق من الأذونات المرفوضة بشكل دائم أولاً
    for (final perm in permissions) {
      final status = await perm.status;
      if (status.isPermanentlyDenied) {
        // فتح إعدادات التطبيق للسماح للمستخدم بالتغيير
        await openAppSettings();
        await Future.delayed(const Duration(seconds: 2));
        break;
      }
    }

    // طلب جميع الأذونات
    Map<Permission, PermissionStatus> statuses = await permissions.request();

    // التحقق من أن كل الأذونات ممنوحة
    bool allGranted =
        statuses.values.every((status) => status.isGranted || status.isLimited);

    return allGranted;
  }

  Future<void> createLocalRoom(String playerName) async {
    _myRole = 'player1';

    _currentState = LocalXOState(
      roomId: 'bt_room_${Random().nextInt(9999)}',
      board: List.filled(9, ''),
      player1Id: playerName,
      currentTurn: 'player1',
    );
    _stateController.add(_currentState);

    await Nearby().startAdvertising(
      playerName,
      strategy,
      onConnectionInitiated: (id, info) {
        Nearby().acceptConnection(
          id,
          onPayLoadRecieved: (endpointId, payload) {
            if (payload.type == PayloadType.BYTES) {
              final str = String.fromCharCodes(payload.bytes!);
              _handleIncomingData(str);
            }
          },
        );
      },
      onConnectionResult: (id, status) {
        if (status == Status.CONNECTED) {
          connectedEndpointId = id;
          Nearby().stopAdvertising();
          // Update state with player2
          // Note: we can't get player2 name directly easily unless they send it.
          // For now just set placeholder, wait for sync.
        }
      },
      onDisconnected: (id) {
        connectedEndpointId = null;
        _stateController.add(null);
      },
    );
  }

  Future<void> joinLocalRoom(String endpointId, String playerName) async {
    _myRole = 'player2';

    await Nearby().startDiscovery(
      playerName,
      strategy,
      onEndpointFound: (id, name, serviceId) {
        if (name == endpointId || true) {
          // Auto connect to first found for simplicity
          Nearby().stopDiscovery();
          Nearby().requestConnection(
            playerName,
            id,
            onConnectionInitiated: (id, info) {
              Nearby().acceptConnection(
                id,
                onPayLoadRecieved: (endpointId, payload) {
                  if (payload.type == PayloadType.BYTES) {
                    final str = String.fromCharCodes(payload.bytes!);
                    _handleIncomingData(str);
                  }
                },
              );
            },
            onConnectionResult: (id, status) {
              if (status == Status.CONNECTED) {
                connectedEndpointId = id;
                // We send our join intent
                _sendData({'type': 'join', 'name': playerName});
              } else {
                throw Exception('فشل الاتصال!');
              }
            },
            onDisconnected: (id) {
              connectedEndpointId = null;
              _stateController.add(null);
            },
          );
        }
      },
      onEndpointLost: (id) {},
    );
  }

  void _handleIncomingData(String jsonStr) {
    try {
      final data = jsonDecode(jsonStr);
      if (data['type'] == 'join' && _myRole == 'player1') {
        _currentState = _currentState?.copyWith(player2Id: data['name']);
        _stateController.add(_currentState);
        _broadcastState();
      } else if (data['type'] == 'sync') {
        _currentState = LocalXOState.fromJson(data['state']);
        _stateController.add(_currentState);
      }
    } catch (_) {}
  }

  void _broadcastState() {
    if (connectedEndpointId != null && _currentState != null) {
      _sendData({'type': 'sync', 'state': _currentState!.toJson()});
    }
  }

  void _sendData(Map<String, dynamic> data) {
    if (connectedEndpointId != null) {
      Nearby().sendBytesPayload(
          connectedEndpointId!, Uint8List.fromList(jsonEncode(data).codeUnits));
    }
  }

  Future<void> makeMove(int index, String playerType, List<String> newBoard,
      String? winner) async {
    if (_currentState == null) return;
    _currentState = _currentState!.copyWith(
      board: newBoard,
      currentTurn: playerType == 'player1' ? 'player2' : 'player1',
      winner: winner,
    );
    _stateController.add(_currentState);
    _broadcastState();
  }

  Future<void> resetRoom() async {
    if (_currentState == null) return;
    _currentState = _currentState!.copyWith(
      board: List.filled(9, ''),
      currentTurn: 'player1',
      winner: null,
    );
    _stateController.add(_currentState);
    _broadcastState();
  }

  Future<void> disposeRoom() async {
    Nearby().stopAdvertising();
    Nearby().stopDiscovery();
    if (connectedEndpointId != null) {
      Nearby().disconnectFromEndpoint(connectedEndpointId!);
      connectedEndpointId = null;
    }
    _currentState = null;
    _stateController.add(null);
  }
}
