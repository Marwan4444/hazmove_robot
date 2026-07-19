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
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      
      _channel?.stream.listen(
        (data) {
          _handleIncomingData(data);
        },
        onError: (error) {
          _connectionController.addError(Exception('WebSocket Connection Error: $error'));
          _connectionController.add(false);
        },
        onDone: () {
          _connectionController.add(false);
        },
      );

      // Brief delay to allow WS negotiation
      await Future.delayed(const Duration(milliseconds: 500));
      _connectionController.add(true);
    } catch (e) {
      _connectionController.add(false);
      throw Exception('Failed to connect: $e');
    }
  }

  @override
  Future<void> disconnect() async {
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
    _connectionController.close();
    _statusController.close();
    _channel?.sink.close();
  }
}
