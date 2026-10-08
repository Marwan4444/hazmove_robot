import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hazmove_robot/core/error/failure.dart';
import 'package:hazmove_robot/presentation/view/auto/cubit/presets_cubit.dart';

import '../fakes.dart';

void main() {
  group('PresetsCubit execution states', () {
    late FakeRobotControlRepo repo;
    late PresetsCubit cubit;

    setUp(() {
      repo = FakeRobotControlRepo();
      cubit = PresetsCubit(repository: repo);
    });

    tearDown(() async {
      await cubit.close();
      repo.dispose();
    });

    test('reports running then completed', () async {
      final gate = Completer<Either<Failure, void>>();
      repo.onExecutePreset = (_) => gate.future;

      final future = cubit.executePreset('p1');
      await Future.delayed(Duration.zero);
      expect(cubit.state.executionStatus, PresetExecutionStatus.running);
      expect(cubit.state.runningPresetId, 'p1');

      gate.complete(const Right(null));
      await future;
      expect(cubit.state.executionStatus, PresetExecutionStatus.completed);
      expect(cubit.state.runningPresetId, isNull);
      expect(cubit.state.isLoading, isFalse);
    });

    test('maps cancellation to cancelled (not failed)', () async {
      repo.onExecutePreset = (_) async =>
          const Left(Failure('cancelled', type: FailureType.cancelled));
      await cubit.executePreset('p1');
      expect(cubit.state.executionStatus, PresetExecutionStatus.cancelled);
      expect(cubit.state.failure, isNull);
      expect(cubit.state.runningPresetId, isNull);
    });

    test('maps rejection to failed with the failure surfaced', () async {
      repo.onExecutePreset = (_) async =>
          const Left(Failure('busy', type: FailureType.rejected));
      await cubit.executePreset('p1');
      expect(cubit.state.executionStatus, PresetExecutionStatus.failed);
      expect(cubit.state.failure?.type, FailureType.rejected);
    });
  });
}
