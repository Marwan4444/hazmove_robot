import '../../domain/entities/linear_rail_entity.dart';
import '../models/linear_rail_model.dart';

extension LinearRailMapper on LinearRailEntity {
  LinearRailModel toModel() {
    if (this is LinearRailModel) return this as LinearRailModel;
    return LinearRailModel(
      currentPosition: currentPosition,
      targetPosition: targetPosition,
      speed: speed,
      isMoving: isMoving,
      minPosition: minPosition,
      maxPosition: maxPosition,
    );
  }
}
