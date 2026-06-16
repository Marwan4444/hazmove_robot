import 'package:equatable/equatable.dart';

class LinearRailModel extends Equatable {
  final double currentPosition; // in cm
  final double targetPosition; // in cm
  final int speed;
  final bool isMoving;
  final double minPosition;
  final double maxPosition;

  const LinearRailModel({
    required this.currentPosition,
    required this.targetPosition,
    required this.speed,
    required this.isMoving,
    this.minPosition = 0.0,
    this.maxPosition = 100.0,
  });

  LinearRailModel copyWith({
    double? currentPosition,
    double? targetPosition,
    int? speed,
    bool? isMoving,
    double? minPosition,
    double? maxPosition,
  }) {
    return LinearRailModel(
      currentPosition: currentPosition ?? this.currentPosition,
      targetPosition: targetPosition ?? this.targetPosition,
      speed: speed ?? this.speed,
      isMoving: isMoving ?? this.isMoving,
      minPosition: minPosition ?? this.minPosition,
      maxPosition: maxPosition ?? this.maxPosition,
    );
  }

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
