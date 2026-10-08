import 'package:flutter_test/flutter_test.dart';
import 'package:hazmove_robot/modules/robot_control/data/protocol/robot_response.dart';

import '../fakes.dart';

void main() {
  group('RobotResponse.fromJson', () {
    test('parses ACK', () {
      final r = RobotResponse.fromJson(
          {'type': 'ack', 'commandId': 'abc123', 'status': 'accepted'});
      expect(r, isA<AckResponse>());
      expect(r.commandId, 'abc123');
      expect(r.isTerminal, isFalse);
    });

    test('parses DONE', () {
      final r = RobotResponse.fromJson(
          {'type': 'done', 'commandId': 'abc123', 'status': 'completed'});
      expect(r, isA<DoneResponse>());
      expect(r.commandId, 'abc123');
      expect(r.isTerminal, isTrue);
    });

    test('parses REJECT with reason', () {
      final r = RobotResponse.fromJson({
        'type': 'reject',
        'commandId': 'abc123',
        'reason': 'OUT_OF_RANGE',
      });
      expect(r, isA<RejectResponse>());
      expect((r as RejectResponse).reason, 'OUT_OF_RANGE');
      expect(r.isTerminal, isTrue);
    });

    test('parses ERROR with reason', () {
      final r = RobotResponse.fromJson({
        'type': 'error',
        'commandId': 'abc123',
        'reason': 'INTERRUPTED',
      });
      expect(r, isA<ErrorResponse>());
      expect((r as ErrorResponse).reason, 'INTERRUPTED');
      expect(r.isTerminal, isTrue);
    });

    test('parses STATUS snapshot without commandId', () {
      final r = RobotResponse.fromJson(
          {'type': 'status', 'data': sampleStatusData()});
      expect(r, isA<StatusResponse>());
      expect(r.commandId, isNull);
      expect(r.isTerminal, isFalse);
      final arm = (r as StatusResponse).robotArm;
      expect(arm.servos.length, 5);
      expect(arm.linearRail.currentPosition, 10.0);
    });

    test('throws on unknown type', () {
      expect(() => RobotResponse.fromJson({'type': 'teleport'}),
          throwsA(isA<FormatException>()));
    });

    test('throws on missing type', () {
      expect(() => RobotResponse.fromJson({'commandId': 'x'}),
          throwsA(isA<FormatException>()));
    });

    test('throws on ack/done/reject/error missing commandId', () {
      for (final type in ['ack', 'done', 'reject', 'error']) {
        expect(() => RobotResponse.fromJson({'type': type}),
            throwsA(isA<FormatException>()),
            reason: '$type without commandId cannot be correlated');
      }
    });

    test('reject without reason defaults to UNKNOWN', () {
      final r = RobotResponse.fromJson(
          {'type': 'reject', 'commandId': 'x'}) as RejectResponse;
      expect(r.reason, 'UNKNOWN');
    });
  });
}
