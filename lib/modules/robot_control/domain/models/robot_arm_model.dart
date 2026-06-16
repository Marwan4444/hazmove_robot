import 'package:equatable/equatable.dart';
import 'servo_model.dart';
import 'linear_rail_model.dart';
import 'base_rotation_model.dart';
import '../enums/robot_enums.dart';

class RobotArmModel extends Equatable {
  final List<ServoModel> servos;
  final LinearRailModel linearRail;
  final BaseRotationModel baseRotation;
  final RobotMode mode;
  final RobotStatus status;
  final bool isConnected;
  final DateTime lastUpdated;

  const RobotArmModel({
    required this.servos,
    required this.linearRail,
    required this.baseRotation,
    this.mode = RobotMode.manual,
    this.status = RobotStatus.idle,
    this.isConnected = false,
    required this.lastUpdated,
  });

  RobotArmModel copyWith({
    List<ServoModel>? servos,
    LinearRailModel? linearRail,
    BaseRotationModel? baseRotation,
    RobotMode? mode,
    RobotStatus? status,
    bool? isConnected,
    DateTime? lastUpdated,
  }) {
    return RobotArmModel(
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
