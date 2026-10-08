import 'package:flutter_test/flutter_test.dart';
import 'package:hazmove_robot/core/constants/app_constants.dart';
import 'package:hazmove_robot/core/error/failure.dart';
import 'package:hazmove_robot/modules/robot_control/data/protocol/robot_command.dart';

void main() {
  group('command serialization', () {
    test('servo command schema matches protocol', () {
      final cmd = ServoCommand(
          servoId: 1, endAngle: 90, speed: 50, commandId: 'uuid-1');
      expect(cmd.toJson(), {
        'type': 'servo',
        'commandId': 'uuid-1',
        'servo_id': 1,
        'end': 90,
        'speed': 50,
      });
    });

    test('linear command schema matches protocol', () {
      final cmd =
          LinearCommand(distance: 20.5, speed: 80, commandId: 'uuid-2');
      expect(cmd.toJson(), {
        'type': 'linear',
        'commandId': 'uuid-2',
        'distance': 20.5,
        'speed': 80,
      });
    });

    test('base command schema matches protocol', () {
      final cmd =
          BaseCommand(degrees: -90.0, speed: 60, commandId: 'uuid-3');
      expect(cmd.toJson(), {
        'type': 'base',
        'commandId': 'uuid-3',
        'degrees': -90.0,
        'speed': 60,
      });
    });

    test('stop / pause / resume carry type + commandId only', () {
      expect(StopCommand(commandId: 'a').toJson(),
          {'type': 'stop', 'commandId': 'a'});
      expect(PauseCommand(commandId: 'b').toJson(),
          {'type': 'pause', 'commandId': 'b'});
      expect(ResumeCommand(commandId: 'c').toJson(),
          {'type': 'resume', 'commandId': 'c'});
    });

    test('mode command schema matches protocol', () {
      final cmd = ModeCommand('seq1', commandId: 'uuid-4');
      expect(cmd.toJson(),
          {'type': 'mode', 'commandId': 'uuid-4', 'mode': 'seq1'});
    });

    test('commands auto-generate a commandId when omitted', () {
      final a = ServoCommand(servoId: 1, endAngle: 10);
      final b = ServoCommand(servoId: 1, endAngle: 10);
      expect(a.commandId, isNotEmpty);
      expect(a.commandId, isNot(b.commandId));
    });

    test('no raw "type" literals leak: type getters use RobotCommands', () {
      expect(ServoCommand(servoId: 1, endAngle: 0).type, RobotCommands.servo);
      expect(LinearCommand(distance: 0).type, RobotCommands.linear);
      expect(BaseCommand(degrees: 0).type, RobotCommands.base);
      expect(StopCommand().type, RobotCommands.stop);
      expect(PauseCommand().type, RobotCommands.pause);
      expect(ResumeCommand().type, RobotCommands.resume);
      expect(ModeCommand('manual').type, RobotCommands.mode);
    });
  });

  group('client-side validation boundaries', () {
    Failure? validateLeft(RobotCommand cmd) =>
        cmd.validate().fold((l) => l, (_) => null);

    test('servo: min/max accepted, outside rejected', () {
      expect(
          validateLeft(
              ServoCommand(servoId: 1, endAngle: AppConstants.minServoAngle)),
          isNull);
      expect(
          validateLeft(
              ServoCommand(servoId: 5, endAngle: AppConstants.maxServoAngle)),
          isNull);
      expect(
          validateLeft(ServoCommand(servoId: 1, endAngle: -1))?.type,
          FailureType.invalidInput);
      expect(
          validateLeft(ServoCommand(servoId: 1, endAngle: 181))?.type,
          FailureType.invalidInput);
    });

    test('servo: id outside 1-5 rejected', () {
      for (final id in [0, 6, -2]) {
        expect(validateLeft(ServoCommand(servoId: id, endAngle: 90))?.type,
            FailureType.invalidInput);
      }
    });

    test('linear: 0 and 45 accepted, below/above rejected', () {
      expect(validateLeft(LinearCommand(distance: 0.0)), isNull);
      expect(validateLeft(LinearCommand(distance: 45.0)), isNull);
      expect(validateLeft(LinearCommand(distance: -0.1))?.type,
          FailureType.invalidInput);
      expect(validateLeft(LinearCommand(distance: 45.1))?.type,
          FailureType.invalidInput);
      expect(validateLeft(LinearCommand(distance: 100.0))?.type,
          FailureType.invalidInput,
          reason: 'legacy 0-100 cm range must no longer validate');
    });

    test('base: -180 and 180 accepted, outside rejected', () {
      expect(validateLeft(BaseCommand(degrees: -180.0)), isNull);
      expect(validateLeft(BaseCommand(degrees: 180.0)), isNull);
      expect(validateLeft(BaseCommand(degrees: -180.1))?.type,
          FailureType.invalidInput);
      expect(validateLeft(BaseCommand(degrees: 180.1))?.type,
          FailureType.invalidInput);
      expect(validateLeft(BaseCommand(degrees: 360.0))?.type,
          FailureType.invalidInput,
          reason: 'legacy 0-360 range must no longer validate');
    });

    test('speed outside 1-100 rejected on motion commands', () {
      expect(validateLeft(ServoCommand(servoId: 1, endAngle: 90, speed: 0)),
          isNotNull);
      expect(validateLeft(ServoCommand(servoId: 1, endAngle: 90, speed: 101)),
          isNotNull);
      expect(validateLeft(LinearCommand(distance: 10, speed: 0)), isNotNull);
      expect(validateLeft(BaseCommand(degrees: 0, speed: 101)), isNotNull);
    });

    test('mode: manual/seq1/auto accepted, seq2 and garbage rejected', () {
      expect(validateLeft(ModeCommand('manual')), isNull);
      expect(validateLeft(ModeCommand('seq1')), isNull);
      expect(validateLeft(ModeCommand('auto')), isNull,
          reason: 'auto is a legacy alias of seq1');
      expect(validateLeft(ModeCommand('seq2')), isNotNull);
      expect(validateLeft(ModeCommand('dance')), isNotNull);
    });
  });
}
