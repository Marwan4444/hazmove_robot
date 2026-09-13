import '../../domain/entities/movement_preset_entity.dart';

class MovementPresetModel extends MovementPresetEntity {
  const MovementPresetModel({
    required super.id,
    required super.name,
    required super.description,
    required List<MovementStepModel> super.steps,
    required super.createdAt,
    super.isFavorite,
  });

  @override
  List<MovementStepModel> get steps => super.steps.cast<MovementStepModel>();

  factory MovementPresetModel.fromJson(Map<String, dynamic> json) {
    return MovementPresetModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      steps: (json['steps'] as List?)
              ?.map((step) => MovementStepModel.fromJson(step))
              .toList() ??
          [],
      createdAt: DateTime.parse(
          json['createdAt'] ?? DateTime.now().toIso8601String()),
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'steps': steps.map((step) => step.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }
}

class MovementStepModel extends MovementStepEntity {
  const MovementStepModel({
    required super.type,
    required super.parameters,
    super.delayMs,
  });

  factory MovementStepModel.fromJson(Map<String, dynamic> json) {
    return MovementStepModel(
      type: json['type'] ?? '',
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
      delayMs: json['delayMs'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'parameters': parameters,
      'delayMs': delayMs,
    };
  }
}
