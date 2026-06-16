import 'package:equatable/equatable.dart';

class MovementPresetModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final List<MovementStepModel> steps;
  final DateTime createdAt;
  final bool isFavorite;

  const MovementPresetModel({
    required this.id,
    required this.name,
    required this.description,
    required this.steps,
    required this.createdAt,
    this.isFavorite = false,
  });

  MovementPresetModel copyWith({
    String? id,
    String? name,
    String? description,
    List<MovementStepModel>? steps,
    DateTime? createdAt,
    bool? isFavorite,
  }) {
    return MovementPresetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      steps: steps ?? this.steps,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

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

class MovementStepModel extends Equatable {
  final String type; // 'servo', 'linear', 'base'
  final Map<String, dynamic> parameters;
  final int delayMs;

  const MovementStepModel({
    required this.type,
    required this.parameters,
    this.delayMs = 0,
  });

  MovementStepModel copyWith({
    String? type,
    Map<String, dynamic>? parameters,
    int? delayMs,
  }) {
    return MovementStepModel(
      type: type ?? this.type,
      parameters: parameters ?? this.parameters,
      delayMs: delayMs ?? this.delayMs,
    );
  }

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

  @override
  List<Object?> get props => [type, parameters, delayMs];
}
