import 'package:equatable/equatable.dart';

class BaseRotationModel extends Equatable {
  final double currentDegrees;
  final double targetDegrees;
  final int speed;
  final bool isMoving;
  final double minDegrees;
  final double maxDegrees;

  const BaseRotationModel({
    required this.currentDegrees,
    required this.targetDegrees,
    required this.speed,
    required this.isMoving,
    this.minDegrees = 0.0,
    this.maxDegrees = 360.0,
  });

  BaseRotationModel copyWith({
    double? currentDegrees,
    double? targetDegrees,
    int? speed,
    bool? isMoving,
    double? minDegrees,
    double? maxDegrees,
  }) {
    return BaseRotationModel(
      currentDegrees: currentDegrees ?? this.currentDegrees,
      targetDegrees: targetDegrees ?? this.targetDegrees,
      speed: speed ?? this.speed,
      isMoving: isMoving ?? this.isMoving,
      minDegrees: minDegrees ?? this.minDegrees,
      maxDegrees: maxDegrees ?? this.maxDegrees,
    );
  }

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
