import 'package:equatable/equatable.dart';

class BaseRotationEntity extends Equatable {
  final double currentDegrees;
  final double targetDegrees;
  final int speed;
  final bool isMoving;
  final double minDegrees;
  final double maxDegrees;

  const BaseRotationEntity({
    required this.currentDegrees,
    required this.targetDegrees,
    required this.speed,
    required this.isMoving,
    this.minDegrees = 0.0,
    this.maxDegrees = 360.0,
  });

  BaseRotationEntity copyWith({
    double? currentDegrees,
    double? targetDegrees,
    int? speed,
    bool? isMoving,
    double? minDegrees,
    double? maxDegrees,
  }) {
    return BaseRotationEntity(
      currentDegrees: currentDegrees ?? this.currentDegrees,
      targetDegrees: targetDegrees ?? this.targetDegrees,
      speed: speed ?? this.speed,
      isMoving: isMoving ?? this.isMoving,
      minDegrees: minDegrees ?? this.minDegrees,
      maxDegrees: maxDegrees ?? this.maxDegrees,
    );
  }

  @override
  List<Object?> get props => [
        currentDegrees,
        targetDegrees,
        speed,
        isMoving,
        minDegrees,
        maxDegrees,
      ];
}
