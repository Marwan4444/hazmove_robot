import '../../domain/entities/servo_entity.dart';
import '../models/servo_model.dart';

extension ServoMapper on ServoEntity {
  ServoModel toModel() {
    if (this is ServoModel) return this as ServoModel;
    return ServoModel(
      id: id,
      name: name,
      currentAngle: currentAngle,
      targetAngle: targetAngle,
      speed: speed,
      isMoving: isMoving,
      minAngle: minAngle,
      maxAngle: maxAngle,
    );
  }
}

extension ServoModelMapper on ServoModel {
  ServoEntity toEntity() => this; // Implicit
}
