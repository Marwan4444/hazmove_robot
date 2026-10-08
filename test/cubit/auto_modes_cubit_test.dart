import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hazmove_robot/modules/robot_control/domain/enums/robot_enums.dart';
import 'package:hazmove_robot/presentation/view/auto/cubit/auto_modes_cubit.dart';

import '../fakes.dart';

void main() {
  group('AutoModesCubit', () {
    late FakeRobotControlRepo repo;
    late AutoModesCubit cubit;

    setUp(() {
      repo = FakeRobotControlRepo();
      cubit = AutoModesCubit(repository: repo);
    });

    tearDown(() async {
      await cubit.close();
      repo.dispose();
    });

    test('startMode(mode1) sends seq1 and marks running', () async {
      await cubit.startMode(AutoModeType.mode1);
      expect(repo.modeCalls, ['seq1']);
      expect(cubit.state.currentMode, AutoModeType.mode1);
      expect(cubit.state.modeState, AutoModeState.running);
    });

    test('startMode(mode2) is refused client-side (no firmware Sequence2)',
        () async {
      await cubit.startMode(AutoModeType.mode2);
      expect(repo.modeCalls, isEmpty);
      expect(cubit.state.currentMode, AutoModeType.none);
      expect(cubit.state.modeState, AutoModeState.idle);
    });

    test('pause / resume round-trip through the repository', () async {
      await cubit.startMode(AutoModeType.mode1);
      await cubit.pauseMode();
      expect(cubit.state.modeState, AutoModeState.paused);
      await cubit.resumeMode();
      expect(cubit.state.modeState, AutoModeState.running);
    });

    test('stopMode resets and returns the robot to manual', () async {
      await cubit.startMode(AutoModeType.mode1);
      await cubit.stopMode();
      expect(cubit.state.currentMode, AutoModeType.none);
      expect(cubit.state.modeState, AutoModeState.idle);
      expect(repo.modeCalls.last, 'manual');
    });

    test('mirrors firmware seq1 running/paused status frames', () async {
      repo.statusController
          .add(Right(testArm().copyWith(mode: RobotMode.seq1)));
      await Future.delayed(Duration.zero);
      expect(cubit.state.currentMode, AutoModeType.mode1);
      expect(cubit.state.modeState, AutoModeState.running);
    });
  });
}
