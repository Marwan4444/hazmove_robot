import 'package:equatable/equatable.dart';

class ServoEntity extends Equatable {
  final int id;
  final String name;
  final int currentAngle;
  final int targetAngle;
  final int speed;
  final bool isMoving;
  final int minAngle;
  final int maxAngle;

  const ServoEntity({
    required this.id,
    required this.name,
    required this.currentAngle,
    required this.targetAngle,
    required this.speed,
    required this.isMoving,
    this.minAngle = 0,
    this.maxAngle = 180,
  });

  ServoEntity copyWith({
    int? id,
    String? name,
    int? currentAngle,
    int? targetAngle,
    int? speed,
    bool? isMoving,
    int? minAngle,
    int? maxAngle,
  }) {
    return ServoEntity(
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
