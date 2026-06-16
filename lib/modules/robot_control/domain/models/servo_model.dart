import 'package:equatable/equatable.dart';

class ServoModel extends Equatable {
  final int id;
  final String name;
  final int currentAngle;
  final int targetAngle;
  final int speed;
  final bool isMoving;
  final int minAngle;
  final int maxAngle;

  const ServoModel({
    required this.id,
    required this.name,
    required this.currentAngle,
    required this.targetAngle,
    required this.speed,
    required this.isMoving,
    this.minAngle = 0,
    this.maxAngle = 180,
  });

  ServoModel copyWith({
    int? id,
    String? name,
    int? currentAngle,
    int? targetAngle,
    int? speed,
    bool? isMoving,
    int? minAngle,
    int? maxAngle,
  }) {
    return ServoModel(
      id: id ?? this.id,
      name: name ?? this.name,
      currentAngle: currentAngle ?? this.currentAngle,
      targetAngle: targetAngle ?? this.targetAngle,
      speed: speed ?? this.speed,
      isMoving: isMoving ?? this.isMoving,
      minAngle: minAngle ?? this.minAngle,
      maxAngle: maxAngle ?? this.maxAngle,
    );
  }

  factory ServoModel.fromJson(Map<String, dynamic> json) {
    return ServoModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      currentAngle: json['currentAngle'] ?? 0,
      targetAngle: json['targetAngle'] ?? 0,
      speed: json['speed'] ?? 50,
      isMoving: json['isMoving'] ?? false,
      minAngle: json['minAngle'] ?? 0,
      maxAngle: json['maxAngle'] ?? 180,
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

  @override
  List<Object?> get props => [
        id,
        name,
        currentAngle,
        targetAngle,
        speed,
        isMoving,
        minAngle,
        maxAngle,
      ];
}
