import '../../domain/entities/linear_rail_entity.dart';

class LinearRailModel extends LinearRailEntity {
  const LinearRailModel({
    required super.currentPosition,
    required super.targetPosition,
    required super.speed,
    required super.isMoving,
    super.minPosition,
    super.maxPosition,
  });

  factory LinearRailModel.fromJson(Map<String, dynamic> json) {
    return LinearRailModel(
      currentPosition: (json['currentPosition'] as num?)?.toDouble() ?? 0.0,
      targetPosition: (json['targetPosition'] as num?)?.toDouble() ?? 0.0,
      speed: json['speed'] ?? 50,
      isMoving: json['isMoving'] ?? false,
      minPosition: (json['minPosition'] as num?)?.toDouble() ?? 0.0,
      maxPosition: (json['maxPosition'] as num?)?.toDouble() ?? 100.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentPosition': currentPosition,
      'targetPosition': targetPosition,
      'speed': speed,
      'isMoving': isMoving,
      'minPosition': minPosition,
      'maxPosition': maxPosition,
    };
  }
}
