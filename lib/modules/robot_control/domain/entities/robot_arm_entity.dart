import 'package:equatable/equatable.dart';
import 'servo_entity.dart';
import 'linear_rail_entity.dart';
import 'base_rotation_entity.dart';
import '../enums/robot_enums.dart';

class RobotArmEntity extends Equatable {
  final List<ServoEntity> servos;
  final LinearRailEntity linearRail;
  final BaseRotationEntity baseRotation;
  final RobotMode mode;
  final RobotStatus status;
  final bool isConnected;
  final DateTime lastUpdated;

  const RobotArmEntity({
    required this.servos,
    required this.linearRail,
    required this.baseRotation,
    this.mode = RobotMode.manual,
    this.status = RobotStatus.idle,
    this.isConnected = false,
    required this.lastUpdated,
  });

  RobotArmEntity copyWith({
    List<ServoEntity>? servos,
    LinearRailEntity? linearRail,
    BaseRotationEntity? baseRotation,
    RobotMode? mode,
    RobotStatus? status,
    bool? isConnected,
    DateTime? lastUpdated,
  }) {
    return RobotArmEntity(
      servos: servos ?? this.servos,
      linearRail: linearRail ?? this.linearRail,
      baseRotation: baseRotation ?? this.baseRotation,
      mode: mode ?? this.mode,
      status: status ?? this.status,
      isConnected: isConnected ?? this.isConnected,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  bool get isAnyMoving {
    return servos.any((servo) => servo.isMoving) ||
        linearRail.isMoving ||
        baseRotation.isMoving;
  }

  @override
  List<Object?> get props => [
        servos,
        linearRail,
        baseRotation,
        mode,
        status,
        isConnected,
        lastUpdated,
      ];
}
