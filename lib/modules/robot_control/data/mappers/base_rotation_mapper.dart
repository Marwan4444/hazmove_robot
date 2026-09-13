import '../../domain/entities/base_rotation_entity.dart';
import '../models/base_rotation_model.dart';

extension BaseRotationMapper on BaseRotationEntity {
  BaseRotationModel toModel() {
    if (this is BaseRotationModel) return this as BaseRotationModel;
    return BaseRotationModel(
      currentDegrees: currentDegrees,
      targetDegrees: targetDegrees,
      speed: speed,
      isMoving: isMoving,
      minDegrees: minDegrees,
      maxDegrees: maxDegrees,
    );
  }
}
