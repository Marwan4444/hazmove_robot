import 'package:flutter_test/flutter_test.dart';
import 'package:hazmove_robot/modules/robot_control/data/models/robot_arm_model.dart';
import 'package:hazmove_robot/modules/robot_control/domain/enums/robot_enums.dart';

import '../fakes.dart';

void main() {
  group('RobotArmModel.fromJson', () {
    test('parses a valid firmware status payload', () {
      final model = RobotArmModel.fromJson(sampleStatusData());
      expect(model.servos.length, 5);
      expect(model.servos.first.id, 1);
      expect(model.servos.first.currentAngle, 90);
      expect(model.linearRail.currentPosition, 10.0);
      expect(model.baseRotation.currentDegrees, 0.0);
      expect(model.mode, RobotMode.manual);
      expect(model.status, RobotStatus.idle);
      expect(model.isConnected, isTrue);
      expect(model.lastUpdated, DateTime.parse('2026-06-30T18:05:25.000Z'));
    });

    test('tolerates missing sections with safe defaults', () {
      final model = RobotArmModel.fromJson({});
      expect(model.servos, isEmpty);
      expect(model.linearRail.currentPosition, 0.0);
      expect(model.baseRotation.currentDegrees, 0.0);
      expect(model.mode, RobotMode.manual);
      expect(model.status, RobotStatus.idle);
      expect(model.isConnected, isFalse);
    });

    test('maps seq1/seq2/error modes and statuses', () {
      var model = RobotArmModel.fromJson(
          sampleStatusData(mode: 'seq1', status: 'moving'));
      expect(model.mode, RobotMode.seq1);
      expect(model.status, RobotStatus.moving);

      model =
          RobotArmModel.fromJson(sampleStatusData(mode: 'seq2', status: 'error'));
      expect(model.mode, RobotMode.seq2);
      expect(model.status, RobotStatus.error);
    });

    test('falls back for unknown mode/status strings', () {
      final model = RobotArmModel.fromJson(
          sampleStatusData(mode: 'hyperdrive', status: 'vibing'));
      expect(model.mode, RobotMode.manual);
      expect(model.status, RobotStatus.idle);
    });

    test('clamps out-of-range servo angles instead of crashing', () {
      final data = sampleStatusData();
      (data['servos'] as List).first['currentAngle'] = 999;
      final model = RobotArmModel.fromJson(data);
      expect(model.servos.first.currentAngle, 180);
    });

    test('ignores unexpected extra fields', () {
      final data = sampleStatusData()
        ..['firmwareVersion'] = '9.9.9'
        ..['debug'] = {'heap': 123};
      expect(() => RobotArmModel.fromJson(data), returnsNormally);
    });

    test('round-trips through toJson', () {
      final model = RobotArmModel.fromJson(sampleStatusData());
      final restored = RobotArmModel.fromJson(model.toJson());
      expect(restored.servos.length, 5);
      expect(restored.linearRail.currentPosition, 10.0);
      expect(restored.mode, RobotMode.manual);
    });
  });
}
