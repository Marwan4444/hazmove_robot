import '../../domain/entities/robot_arm_entity.dart';
import '../models/robot_arm_model.dart';
import 'servo_mapper.dart';
import 'linear_rail_mapper.dart';
import 'base_rotation_mapper.dart';

extension RobotArmMapper on RobotArmEntity {
  RobotArmModel toModel() {
    if (this is RobotArmModel) return this as RobotArmModel;
    return RobotArmModel(
      servos: servos.map((s) => s.toModel()).toList(),
      linearRail: linearRail.toModel(),
      baseRotation: baseRotation.toModel(),
      mode: mode,
      status: status,
      isConnected: isConnected,
      lastUpdated: lastUpdated,
    );
  }
}
