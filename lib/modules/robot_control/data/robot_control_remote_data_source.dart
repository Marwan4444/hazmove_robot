import '../domain/models/robot_arm_model.dart';

abstract class RobotRemoteDataSource {
  Stream<bool> get connectionStatus;
  Stream<RobotArmModel> get robotStatus;
  
  Future<void> connect(String url);
  Future<void> disconnect();
  Future<void> sendCommand(Map<String, dynamic> command);
}
