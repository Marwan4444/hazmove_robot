import '../../domain/entities/base_rotation_entity.dart';

class BaseRotationModel extends BaseRotationEntity {
  const BaseRotationModel({
    required super.currentDegrees,
    required super.targetDegrees,
    required super.speed,
    required super.isMoving,
    super.minDegrees,
    super.maxDegrees,
  });

  factory BaseRotationModel.fromJson(Map<String, dynamic> json) {
    return BaseRotationModel(
      currentDegrees: (json['currentDegrees'] as num?)?.toDouble() ?? 0.0,
      targetDegrees: (json['targetDegrees'] as num?)?.toDouble() ?? 0.0,
      speed: json['speed'] ?? 50,
      isMoving: json['isMoving'] ?? false,
      minDegrees: (json['minDegrees'] as num?)?.toDouble() ?? 0.0,
      maxDegrees: (json['maxDegrees'] as num?)?.toDouble() ?? 360.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentDegrees': currentDegrees,
      'targetDegrees': targetDegrees,
      'speed': speed,
      'isMoving': isMoving,
      'minDegrees': minDegrees,
      'maxDegrees': maxDegrees,
    };
  }
}
