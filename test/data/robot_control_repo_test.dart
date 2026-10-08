import 'package:flutter_test/flutter_test.dart';
import 'package:hazmove_robot/core/error/failure.dart';
import 'package:hazmove_robot/modules/robot_control/data/models/movement_preset_model.dart';
import 'package:hazmove_robot/modules/robot_control/data/protocol/robot_response.dart';
import 'package:hazmove_robot/modules/robot_control/data/providers/robot_control_repo_impl.dart';

import '../fakes.dart';

RobotControlRepoImpl makeRepo(
  FakeRemoteDataSource remote,
  FakeLocalDataSource local, {
  Duration timeout = const Duration(milliseconds: 500),
}) {
  return RobotControlRepoImpl(
    remoteDataSource: remote,
    localDataSource: local,
    servoAwaitTimeout: timeout,
    baseAwaitTimeout: timeout,
    linearAwaitTimeout: timeout,
    controlAwaitTimeout: timeout,
  );
}

MovementPresetModel presetWithSteps(
    String id, List<MovementStepModel> steps) {
  return MovementPresetModel(
    id: id,
    name: 'preset $id',
    description: '',
    steps: steps,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('RobotControlRepoImpl command construction + response handling', () {
    late FakeRemoteDataSource remote;
    late FakeLocalDataSource local;
    late RobotControlRepoImpl repo;

    setUp(() {
      remote = FakeRemoteDataSource();
      local = FakeLocalDataSource();
      repo = makeRepo(remote, local);
    });

    tearDown(() {
      remote.dispose();
    });

    test('servo command is built with commandId and resolves on DONE',
        () async {
      remote.autoDone();
      final result = await repo.setServoAngle(2, 90, 60);
      expect(result.isRight(), isTrue);
      expect(remote.sentCommands.length, 1);
      final cmd = remote.sentCommands.single;
      expect(cmd['type'], 'servo');
      expect(cmd['servo_id'], 2);
      expect(cmd['end'], 90);
      expect(cmd['speed'], 60);
      expect(cmd['commandId'].toString(), isNotEmpty);
    });

    test('linear command uses absolute distance field', () async {
      remote.autoDone();
      final result = await repo.setLinearPosition(20.5, 80);
      expect(result.isRight(), isTrue);
      final cmd = remote.sentCommands.single;
      expect(cmd['type'], 'linear');
      expect(cmd['distance'], 20.5);
    });

    test('base command uses degrees field', () async {
      remote.autoDone();
      final result = await repo.setBaseRotation(-90.0, 60);
      expect(result.isRight(), isTrue);
      final cmd = remote.sentCommands.single;
      expect(cmd['type'], 'base');
      expect(cmd['degrees'], -90.0);
    });

    test('stop / pause / resume / mode schemas', () async {
      remote.autoDone();
      await repo.stopAllMovements();
      await repo.pauseMovements();
      await repo.resumeMovements();
      await repo.setMode('seq1');
      expect(
          remote.sentCommands.map((c) => c['type']),
          ['stop', 'pause', 'resume', 'mode']);
      expect(remote.sentCommands[3]['mode'], 'seq1');
      for (final cmd in remote.sentCommands) {
        expect(cmd['commandId'].toString(), isNotEmpty);
      }
    });

    test('ACK followed by DONE resolves', () async {
      remote.onSend = (command) async {
        final id = command['commandId'].toString();
        remote.responseController.add(AckResponse(commandId: id));
        await Future.delayed(const Duration(milliseconds: 20));
        remote.responseController.add(DoneResponse(commandId: id));
      };
      final result = await repo.setServoAngle(1, 10, 50);
      expect(result.isRight(), isTrue);
    });

    test('REJECT maps to a rejected Failure with a friendly message',
        () async {
      remote.onSend = (command) async {
        remote.responseController.add(RejectResponse(
            commandId: command['commandId'].toString(),
            reason: 'OUT_OF_RANGE'));
      };
      final result = await repo.setLinearPosition(40, 50);
      expect(result.isLeft(), isTrue);
      final failure = result.fold((l) => l, (_) => null)!;
      expect(failure.type, FailureType.rejected);
      expect(failure.userMessage, contains('safety limits'));
    });

    test('ERROR maps to a firmware Failure', () async {
      remote.onSend = (command) async {
        remote.responseController.add(ErrorResponse(
            commandId: command['commandId'].toString(),
            reason: 'INTERRUPTED'));
      };
      final result = await repo.setServoAngle(1, 10, 50);
      expect(result.isLeft(), isTrue);
      expect(result.fold((l) => l, (_) => null)!.type,
          FailureType.firmwareError);
    });

    test('no terminal frame maps to a timeout Failure', () async {
      final result = await repo.setServoAngle(1, 10, 50);
      expect(result.isLeft(), isTrue);
      expect(
          result.fold((l) => l, (_) => null)!.type, FailureType.timeout);
    });

    test('client-side range violations fail fast without sending', () async {
      var result = await repo.setServoAngle(1, 200, 50);
      expect(result.fold((l) => l, (_) => null)?.type,
          FailureType.invalidInput);

      result = await repo.setLinearPosition(45.1, 50);
      expect(result.fold((l) => l, (_) => null)?.type,
          FailureType.invalidInput);

      result = await repo.setBaseRotation(180.1, 50);
      expect(result.fold((l) => l, (_) => null)?.type,
          FailureType.invalidInput);

      expect(remote.sentCommands, isEmpty);
    });

    test('seq2 is refused client-side (firmware has no Sequence2)', () async {
      final result = await repo.setMode('seq2');
      expect(result.fold((l) => l, (_) => null)?.type,
          FailureType.invalidInput);
      expect(remote.sentCommands, isEmpty);
    });

    test('transport send failure maps to a Failure', () async {
      remote.onSend = (_) async => throw Exception('Not connected to robot');
      final result = await repo.setServoAngle(1, 10, 50);
      expect(result.isLeft(), isTrue);
    });

    test('offline network check fails fast before touching the socket',
        () async {
      final offlineRepo = RobotControlRepoImpl(
        remoteDataSource: remote,
        localDataSource: local,
        networkInfo: FakeNetworkInfo(connected: false),
      );
      final result = await offlineRepo.connect('ws://192.168.4.1:81');
      expect(result.fold((l) => l, (_) => null)?.type,
          FailureType.noInternet);
      expect(remote.connectedUrls, isEmpty);
      await offlineRepo.dispose();
    });
  });

  group('preset execution', () {
    late FakeRemoteDataSource remote;
    late FakeLocalDataSource local;
    late RobotControlRepoImpl repo;

    setUp(() {
      remote = FakeRemoteDataSource()..autoDone();
      local = FakeLocalDataSource(presets: [
        presetWithSteps('p1', [
          const MovementStepModel(
              type: 'servo',
              parameters: {'servo_id': 1, 'end': 90, 'speed': 50}),
          const MovementStepModel(
              type: 'linear',
              parameters: {'distance': 20.0, 'speed': 50},
              delayMs: 150),
        ]),
      ]);
      repo = makeRepo(remote, local);
    });

    tearDown(() {
      remote.dispose();
    });

    test('normal completion sends every step with unique commandIds',
        () async {
      final result = await repo.executePreset('p1');
      expect(result.isRight(), isTrue);
      expect(remote.sentCommands.length, 2);
      expect(remote.sentCommands[0]['type'], 'servo');
      expect(remote.sentCommands[1]['type'], 'linear');
      final ids =
          remote.sentCommands.map((c) => c['commandId']).toSet();
      expect(ids.length, 2);
    });

    test('a rejected step aborts the preset with the rejection', () async {
      remote.onSend = (command) async {
        if (command['type'] == 'linear') {
          remote.responseController.add(RejectResponse(
              commandId: command['commandId'].toString(), reason: 'BUSY'));
        } else {
          remote.responseController.add(DoneResponse(
              commandId: command['commandId'].toString()));
        }
      };
      final result = await repo.executePreset('p1');
      expect(result.isLeft(), isTrue);
      expect(result.fold((l) => l, (_) => null)?.type,
          FailureType.rejected);
    });

    test('stop cancels a preset promptly during a delay', () async {
      local.presets = [
        presetWithSteps('slow', [
          const MovementStepModel(
              type: 'servo',
              parameters: {'servo_id': 1, 'end': 10, 'speed': 50},
              delayMs: 2000),
        ]),
      ];
      final executing = repo.executePreset('slow');
      // Wait until the first step has been sent, then emergency-stop.
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 10));
        return remote.sentCommands.isEmpty;
      });
      await repo.stopAllMovements();
      final result = await executing;
      expect(result.isLeft(), isTrue);
      expect(result.fold((l) => l, (_) => null)?.type,
          FailureType.cancelled);
      // The stop command itself went out too.
      expect(remote.sentCommands.last['type'], 'stop');
    });

    test('concurrent executions do not interfere', () async {
      local.presets = [
        presetWithSteps('long', [
          const MovementStepModel(
              type: 'servo',
              parameters: {'servo_id': 1, 'end': 10, 'speed': 50},
              delayMs: 1500),
        ]),
        presetWithSteps('quick', [
          const MovementStepModel(
              type: 'servo',
              parameters: {'servo_id': 2, 'end': 20, 'speed': 50}),
        ]),
      ];
      final longRun = repo.executePreset('long');
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 10));
        return repo.activePresetExecutions.isEmpty;
      });
      final quickRun = repo.executePreset('quick');
      expect(repo.activePresetExecutions.length, 2);

      // Cancel only the long run.
      final longId = repo.activePresetExecutions.first;
      await repo.cancelPresetExecution(longId);

      expect((await quickRun).isRight(), isTrue);
      final longResult = await longRun;
      expect(longResult.fold((l) => l, (_) => null)?.type,
          FailureType.cancelled);
      expect(repo.activePresetExecutions, isEmpty);
    });

    test('a new execution works right after a cancellation', () async {
      local.presets = [
        presetWithSteps('one', [
          const MovementStepModel(
              type: 'servo',
              parameters: {'servo_id': 1, 'end': 10, 'speed': 50},
              delayMs: 1200),
        ]),
      ];
      final first = repo.executePreset('one');
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 10));
        return repo.activePresetExecutions.isEmpty;
      });
      await repo.cancelPresetExecution(repo.activePresetExecutions.single);
      expect((await first).isLeft(), isTrue);

      // State is clean: a fresh run completes normally.
      final second = await repo.executePreset('one');
      expect(second.isRight(), isTrue);
    });

    test('cancelling an unknown execution id fails cleanly', () async {
      final result = await repo.cancelPresetExecution(999);
      expect(result.fold((l) => l, (_) => null)?.type, FailureType.notFound);
    });
  });
}
