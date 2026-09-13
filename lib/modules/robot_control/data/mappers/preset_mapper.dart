import '../../domain/entities/movement_preset_entity.dart';
import '../models/movement_preset_model.dart';

extension MovementStepMapper on MovementStepEntity {
  MovementStepModel toModel() {
    if (this is MovementStepModel) return this as MovementStepModel;
    return MovementStepModel(
      type: type,
      parameters: parameters,
      delayMs: delayMs,
    );
  }
}

extension MovementPresetMapper on MovementPresetEntity {
  MovementPresetModel toModel() {
    if (this is MovementPresetModel) return this as MovementPresetModel;
    return MovementPresetModel(
      id: id,
      name: name,
      description: description,
      steps: steps.map((s) => s.toModel()).toList(),
      createdAt: createdAt,
      isFavorite: isFavorite,
    );
  }
}
