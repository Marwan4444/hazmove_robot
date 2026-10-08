import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/robot_arm_model.dart';
import '../protocol/robot_response.dart';

import '../robot_control_remote_data_source.dart';

class RobotRemoteDataSourceApiImp implements RobotRemoteDataSource {
  WebSocketChannel? _channel;
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  final StreamController<RobotArmModel> _statusController =
      StreamController<RobotArmModel>.broadcast();
  // Command responses bypass throttling: completion must be reliable.
  final StreamController<RobotResponse> _responseController =
      StreamController<RobotResponse>.broadcast();

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
  Stream<RobotResponse> get commandResponses => _responseController.stream;

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

      // Wait for genuine connection handshake with timeout
      await _channel!.ready.timeout(
        const Duration(milliseconds: AppConstants.connectionTimeout),
      );

      _channel?.stream.listen(
        (data) {
          _handleIncomingData(data);
        },
        onError: (error) {
          _log('[WS] Connection error: $error');
          _connectionController.add(false);
          _scheduleReconnect();
        },
        onDone: () {
          _log('[WS] Connection closed');
          _connectionController.add(false);
          _scheduleReconnect();
        },
      );

      _connectionController.add(true);
      _reconnectAttempts = 0; // Reset counter on success
      _log('[WS] Connected successfully to $url');
    } catch (e) {
      _log('[WS] Connection failed: $e');
      _connectionController.add(false);
      _scheduleReconnect();
    }
  }

  /// Schedules an auto-reconnect attempt with exponential backoff.
  /// Will NOT reconnect if the user disconnected intentionally.
  void _scheduleReconnect() {
    if (_intentionalDisconnect || _lastUrl == null) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _log(
        '[WS] Max reconnect attempts reached ($_maxReconnectAttempts). Giving up.',
      );
      return;
    }

    _reconnectTimer?.cancel();
    // Exponential backoff: 2s, 4s, 8s, 16s, 32s... capped at ~17 min
    final delay = _baseReconnectDelay * (1 << _reconnectAttempts);
    _reconnectAttempts++;

    _log(
      '[WS] Reconnecting in ${delay.inSeconds}s '
      '(attempt $_reconnectAttempts/$_maxReconnectAttempts)',
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
    // Command responses (ack/done/reject/error) bypass throttling so command
    // completion stays reliable; only status snapshots are throttled (~30 FPS).
    try {
      final Map<String, dynamic> json = jsonDecode(data);
      final type = json['type']?.toString();

      if (type != null && type != RobotCommands.status) {
        try {
          _responseController.add(RobotResponse.fromJson(json));
        } catch (e) {
          _log('[ESP32 response ERROR] $e | raw=$data');
        }
        return;
      }

      final now = DateTime.now();
      if (now.difference(_lastProcessTime).inMilliseconds < _throttleMs) {
        return;
      }
      _lastProcessTime = now;

      _log('[ESP32 parsed] type=$type');
      if (type == RobotCommands.status) {
        final robotArm = RobotArmModel.fromJson(
            json['data'] is Map<String, dynamic> ? json['data'] : {});
        _statusController.add(robotArm);
      }
    } catch (e) {
      _log('[ESP32 parse ERROR] $e | raw=$data');
    }
  }

  /// Debug-only transport log. Per-frame logging in release builds wastes
  /// CPU/IO on every status frame, so it is compiled out via [kDebugMode].
  void _log(String message) {
    if (kDebugMode) debugPrint(message);
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _connectionController.close();
    _statusController.close();
    _responseController.close();
    _channel?.sink.close();
  }
}
