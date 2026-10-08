import 'models/robot_arm_model.dart';
import 'protocol/robot_response.dart';

abstract class RobotRemoteDataSource {
  Stream<bool> get connectionStatus;

  /// Throttled (~30 FPS) status snapshots. Transport-edge throttling only.
  Stream<RobotArmModel> get robotStatus;

  /// Unthrottled command responses (`ack` / `done` / `reject` / `error`).
  /// Must NEVER be throttled — command completion depends on them.
  Stream<RobotResponse> get commandResponses;

  Future<void> connect(String url);
  Future<void> disconnect();
  Future<void> sendCommand(Map<String, dynamic> command);
}
