import 'package:equatable/equatable.dart';

class MovementPresetEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final List<MovementStepEntity> steps;
  final DateTime createdAt;
  final bool isFavorite;

  const MovementPresetEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.steps,
    required this.createdAt,
    this.isFavorite = false,
  });

  MovementPresetEntity copyWith({
    String? id,
    String? name,
    String? description,
    List<MovementStepEntity>? steps,
    DateTime? createdAt,
    bool? isFavorite,
  }) {
    return MovementPresetEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      steps: steps ?? this.steps,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        steps,
        createdAt,
        isFavorite,
      ];
}

class MovementStepEntity extends Equatable {
  final String type; // 'servo', 'linear', 'base'
  final Map<String, dynamic> parameters;
  final int delayMs;

  const MovementStepEntity({
    required this.type,
    required this.parameters,
    this.delayMs = 0,
  });

  MovementStepEntity copyWith({
    String? type,
    Map<String, dynamic>? parameters,
    int? delayMs,
  }) {
    return MovementStepEntity(
      type: type ?? this.type,
      parameters: parameters ?? this.parameters,
      delayMs: delayMs ?? this.delayMs,
    );
  }

  @override
  List<Object?> get props => [type, parameters, delayMs];
}
