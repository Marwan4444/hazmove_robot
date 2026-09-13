import 'package:equatable/equatable.dart';

class LinearRailEntity extends Equatable {
  final double currentPosition; // in cm
  final double targetPosition; // in cm
  final int speed;
  final bool isMoving;
  final double minPosition;
  final double maxPosition;

  const LinearRailEntity({
    required this.currentPosition,
    required this.targetPosition,
    required this.speed,
    required this.isMoving,
    this.minPosition = 0.0,
    this.maxPosition = 100.0,
  });

  LinearRailEntity copyWith({
    double? currentPosition,
    double? targetPosition,
    int? speed,
    bool? isMoving,
    double? minPosition,
    double? maxPosition,
  }) {
    return LinearRailEntity(
      currentPosition: currentPosition ?? this.currentPosition,
      targetPosition: targetPosition ?? this.targetPosition,
      speed: speed ?? this.speed,
      isMoving: isMoving ?? this.isMoving,
      minPosition: minPosition ?? this.minPosition,
      maxPosition: maxPosition ?? this.maxPosition,
    );
  }

  @override
  List<Object?> get props => [
        currentPosition,
        targetPosition,
        speed,
        isMoving,
        minPosition,
        maxPosition,
      ];
}
