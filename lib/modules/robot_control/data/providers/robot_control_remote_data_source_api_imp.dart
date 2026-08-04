import 'dart:async';
import 'dart:developer' as dev;
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../domain/models/robot_arm_model.dart';

import '../robot_control_remote_data_source.dart';

class RobotRemoteDataSourceApiImp implements RobotRemoteDataSource {
  WebSocketChannel? _channel;
  final StreamController<bool> _connectionController = 
      StreamController<bool>.broadcast();
  final StreamController<RobotArmModel> _statusController = 
      StreamController<RobotArmModel>.broadcast();

  // ─── Auto-Reconnect fields ──────────────────────────────────
  String? _lastUrl;
  bool _intentionalDisconnect = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _baseReconnectDelay = Duration(seconds: 2);
  // ──────────────────────────────────────────────────────────────

  RobotRemoteDataSourceApiImp() {
    // Initial status emitter state
    _connectionController.add(false);
  }

  DateTime _lastProcessTime = DateTime.now();
  static const int _throttleMs = 32; // ~30 fps max

  @override
  Stream<bool> get connectionStatus => _connectionController.stream;

  @override
  Stream<RobotArmModel> get robotStatus => _statusController.stream;

  @override
  Future<void> connect(String url) async {
    _intentionalDisconnect = false;
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
    _lastUrl = url;
    await _establishConnection(url);
  }

  /// Internal method to establish the WebSocket connection.
  /// Used by both [connect] and the auto-reconnect logic.
  Future<void> _establishConnection(String url) async {
    try {
      // Close any existing channel before reconnecting
      try {
        await _channel?.sink.close();
      } catch (_) {}
      _channel = null;

      _channel = WebSocketChannel.connect(Uri.parse(url));
      
      _channel?.stream.listen(
        (data) {
          _handleIncomingData(data);
        },
        onError: (error) {
          dev.log('[WS] Connection error: $error', name: 'WebSocket');
          _connectionController.add(false);
          _scheduleReconnect();
        },
        onDone: () {
          dev.log('[WS] Connection closed', name: 'WebSocket');
          _connectionController.add(false);
          _scheduleReconnect();
        },
      );

      // Brief delay to allow WS negotiation
      await Future.delayed(const Duration(milliseconds: 500));
      _connectionController.add(true);
      _reconnectAttempts = 0; // Reset counter on success
      dev.log('[WS] Connected successfully to $url', name: 'WebSocket');
    } catch (e) {
      dev.log('[WS] Connection failed: $e', name: 'WebSocket');
      _connectionController.add(false);
      _scheduleReconnect();
    }
  }

  /// Schedules an auto-reconnect attempt with exponential backoff.
  /// Will NOT reconnect if the user disconnected intentionally.
  void _scheduleReconnect() {
    if (_intentionalDisconnect || _lastUrl == null) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      dev.log(
        '[WS] Max reconnect attempts reached ($_maxReconnectAttempts). Giving up.',
        name: 'WebSocket',
      );
      return;
    }

    _reconnectTimer?.cancel();
    // Exponential backoff: 2s, 4s, 8s, 16s, 32s... capped at ~17 min
    final delay = _baseReconnectDelay * (1 << _reconnectAttempts);
    _reconnectAttempts++;

    dev.log(
      '[WS] Reconnecting in ${delay.inSeconds}s '
      '(attempt $_reconnectAttempts/$_maxReconnectAttempts)',
      name: 'WebSocket',
    );

    _reconnectTimer = Timer(delay, () async {
      if (!_intentionalDisconnect && _lastUrl != null) {
        await _establishConnection(_lastUrl!);
      }
    });
  }

  @override
  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;
    try {
      await _channel?.sink.close();
      _channel = null;
      _connectionController.add(false);
    } catch (e) {
      throw Exception('Failed to disconnect: $e');
    }
  }

  @override
  Future<void> sendCommand(Map<String, dynamic> command) async {
    try {
      if (_channel == null) {
        throw Exception('Not connected to robot');
      }
      final jsonCommand = jsonEncode(command);
      _channel!.sink.add(jsonCommand);
    } catch (e) {
      throw Exception('Failed to send command: $e');
    }
  }

  void _handleIncomingData(dynamic data) {
    // ─── Log every raw message from ESP32 ───────────────────────────────
    dev.log('[ESP32 ←] $data', name: 'WebSocket');
    // ────────────────────────────────────────────────────────────────────

    final now = DateTime.now();
    if (now.difference(_lastProcessTime).inMilliseconds < _throttleMs) {
      return;
    }
    _lastProcessTime = now;

    try {
      final Map<String, dynamic> json = jsonDecode(data);

      dev.log('[ESP32 parsed] type=${json['type']} | data=${json['data']}',
          name: 'WebSocket');

      if (json['type'] == 'status') {
        final robotArm = RobotArmModel.fromJson(json['data'] ?? {});
        _statusController.add(robotArm);
      }
    } catch (e) {
      dev.log('[ESP32 parse ERROR] $e | raw=$data', name: 'WebSocket', level: 900);
    }
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _connectionController.close();
    _statusController.close();
    _channel?.sink.close();
  }
}
