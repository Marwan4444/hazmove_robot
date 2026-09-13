import '../../domain/entities/servo_entity.dart';

class ServoModel extends ServoEntity {
  const ServoModel({
    required super.id,
    required super.name,
    required super.currentAngle,
    required super.targetAngle,
    required super.speed,
    required super.isMoving,
    super.minAngle,
    super.maxAngle,
  });

  factory ServoModel.fromJson(Map<String, dynamic> json) {
    final int minAngle = json['minAngle'] ?? 0;
    final int maxAngle = json['maxAngle'] ?? 180;
    int _clamp(int? raw, int fallback) =>
        (raw ?? fallback).clamp(minAngle, maxAngle).toInt();
    return ServoModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      currentAngle: _clamp(json['currentAngle'] as int?, 0),
      targetAngle: _clamp(json['targetAngle'] as int?, 0),
      speed: json['speed'] ?? 50,
      isMoving: json['isMoving'] ?? false,
      minAngle: minAngle,
      maxAngle: maxAngle,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'currentAngle': currentAngle,
      'targetAngle': targetAngle,
      'speed': speed,
      'isMoving': isMoving,
      'minAngle': minAngle,
      'maxAngle': maxAngle,
    };
  }
}
