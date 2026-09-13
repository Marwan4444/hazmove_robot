import '../../domain/entities/robot_arm_entity.dart';
import '../../domain/enums/robot_enums.dart';
import 'servo_model.dart';
import 'linear_rail_model.dart';
import 'base_rotation_model.dart';

class RobotArmModel extends RobotArmEntity {
  const RobotArmModel({
    required List<ServoModel> super.servos,
    required LinearRailModel super.linearRail,
    required BaseRotationModel super.baseRotation,
    super.mode,
    super.status,
    super.isConnected,
    required super.lastUpdated,
  });

  @override
  List<ServoModel> get servos => super.servos.cast<ServoModel>();

  @override
  LinearRailModel get linearRail => super.linearRail as LinearRailModel;

  @override
  BaseRotationModel get baseRotation => super.baseRotation as BaseRotationModel;

  factory RobotArmModel.fromJson(Map<String, dynamic> json) {
    return RobotArmModel(
      servos: (json['servos'] as List?)
              ?.map((servo) => ServoModel.fromJson(servo))
              .toList() ??
          [],
      linearRail: json['linearRail'] != null
          ? LinearRailModel.fromJson(json['linearRail'])
          : const LinearRailModel(
              currentPosition: 0.0,
              targetPosition: 0.0,
              speed: 50,
              isMoving: false),
      baseRotation: json['baseRotation'] != null
          ? BaseRotationModel.fromJson(json['baseRotation'])
          : const BaseRotationModel(
              currentDegrees: 0.0,
              targetDegrees: 0.0,
              speed: 50,
              isMoving: false),
      mode: RobotMode.values.firstWhere(
        (mode) => mode.name == json['mode'],
        orElse: () => RobotMode.manual,
      ),
      status: RobotStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => RobotStatus.idle,
      ),
      isConnected: json['isConnected'] ?? false,
      lastUpdated: DateTime.parse(
          json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'servos': servos.map((servo) => servo.toJson()).toList(),
      'linearRail': linearRail.toJson(),
      'baseRotation': baseRotation.toJson(),
      'mode': mode.name,
      'status': status.name,
      'isConnected': isConnected,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}
