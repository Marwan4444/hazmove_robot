import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hazmove_robot/modules/robot_control/data/protocol/command_tracker.dart';
import 'package:hazmove_robot/modules/robot_control/data/protocol/robot_response.dart';

void main() {
  group('CommandTracker', () {
    test('done completes a tracked command', () async {
      final tracker = CommandTracker();
      final future = tracker.track('id-1', timeout: const Duration(seconds: 5));
      expect(tracker.pendingCount, 1);
      expect(tracker.resolve(DoneResponse(commandId: 'id-1')), isTrue);
      final response = await future;
      expect(response, isA<DoneResponse>());
      expect(tracker.pendingCount, 0);
    });

    test('ack is recorded but does not complete', () async {
      final tracker = CommandTracker();
      final future = tracker.track('id-1', timeout: const Duration(seconds: 5));
      expect(tracker.resolve(AckResponse(commandId: 'id-1')), isTrue);
      expect(tracker.wasAcknowledged('id-1'), isTrue);
      expect(tracker.pendingCount, 1);
      tracker.resolve(DoneResponse(commandId: 'id-1'));
      await future;
      expect(tracker.pendingCount, 0);
    });

    test('reject and error complete as terminal frames', () async {
      final tracker = CommandTracker();
      final r1 = tracker.track('a', timeout: const Duration(seconds: 5));
      final r2 = tracker.track('b', timeout: const Duration(seconds: 5));
      tracker.resolve(RejectResponse(commandId: 'a', reason: 'BUSY'));
      tracker.resolve(ErrorResponse(commandId: 'b', reason: 'INTERRUPTED'));
      expect(await r1, isA<RejectResponse>());
      expect(await r2, isA<ErrorResponse>());
    });

    test('unknown commandIds are ignored', () async {
      final tracker = CommandTracker();
      final future = tracker.track('mine', timeout: const Duration(seconds: 5));
      expect(tracker.resolve(DoneResponse(commandId: 'yours')), isFalse);
      expect(tracker.resolve(AckResponse(commandId: 'yours')), isFalse);
      expect(tracker.pendingCount, 1);
      tracker.resolve(DoneResponse(commandId: 'mine'));
      await future;
    });

    test('frames for unknown commandIds never match', () async {
      final tracker = CommandTracker();
      final future = tracker.track('mine', timeout: const Duration(seconds: 5));
      expect(tracker.resolve(DoneResponse(commandId: 'stale-or-foreign')),
          isFalse);
      expect(tracker.resolve(AckResponse(commandId: 'stale-or-foreign')),
          isFalse);
      expect(tracker.pendingCount, 1);
      expect(tracker.resolve(DoneResponse(commandId: 'mine')), isTrue);
      await future;
      expect(tracker.pendingCount, 0);
    });

    test('timeout fails the pending future', () async {
      final tracker = CommandTracker();
      await expectLater(
        tracker.track('id-9', timeout: const Duration(milliseconds: 50)),
        throwsA(isA<TimeoutException>()),
      );
      expect(tracker.pendingCount, 0);
    });

    test('failAll completes every pending command', () async {
      final tracker = CommandTracker();
      final f1 = tracker.track('a', timeout: const Duration(seconds: 5));
      final f2 = tracker.track('b', timeout: const Duration(seconds: 5));
      expect(tracker.failAll(StateError('disconnected')), 2);
      await expectLater(f1, throwsStateError);
      await expectLater(f2, throwsStateError);
      expect(tracker.pendingCount, 0);
    });

    test('cancel removes one pending command and fails its observer',
        () async {
      final tracker = CommandTracker();
      final future = tracker.track('id-1', timeout: const Duration(seconds: 5));
      expect(tracker.cancel('id-1'), isTrue);
      expect(tracker.cancel('id-1'), isFalse);
      await expectLater(future, throwsStateError);
    });

    test('discard drops an entry without failing anyone', () async {
      final tracker = CommandTracker();
      tracker.track('id-1', timeout: const Duration(milliseconds: 100));
      expect(tracker.discard('id-1'), isTrue);
      expect(tracker.discard('id-1'), isFalse);
      expect(tracker.pendingCount, 0);
      // The orphaned timer fires harmlessly; the test completes normally.
      await Future.delayed(const Duration(milliseconds: 150));
    });
  });
}
