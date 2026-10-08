import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazmove_robot/modules/robot_control/domain/entities/base_rotation_entity.dart';
import 'package:hazmove_robot/modules/robot_control/domain/entities/servo_entity.dart';
import 'package:hazmove_robot/presentation/view/manual/widgets/base_rotation_control_widget.dart';
import 'package:hazmove_robot/presentation/view/manual/widgets/movement_status_widget.dart';
import 'package:hazmove_robot/presentation/view/manual/widgets/servo_control_widget.dart';
import 'package:hazmove_robot/presentation/view/settings/widgets/robot_limits_section.dart';

Widget harness(Widget child) =>
    MaterialApp(home: Scaffold(body: child));

const testServo = ServoEntity(
    id: 1,
    name: 'Base Servo',
    currentAngle: 90,
    targetAngle: 90,
    speed: 50,
    isMoving: false);

void main() {
  group('manual control widgets', () {
    testWidgets('servo slider is interactive when idle',
        (WidgetTester tester) async {
      int? committed;
      await tester.pumpWidget(harness(ServoControlWidget(
        servo: testServo,
        onAngleChanged: (_, __) {},
        onAngleCommitted: (angle, _) => committed = angle,
      )));
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.onChanged, isNotNull);
      expect(slider.onChangeEnd, isNotNull);
      expect(find.text('Base Servo'), findsOneWidget);
      expect(committed, isNull);
    });

    testWidgets('servo slider is disabled while moving',
        (WidgetTester tester) async {
      await tester.pumpWidget(harness(ServoControlWidget(
        servo: testServo.copyWith(isMoving: true),
        onAngleChanged: (_, __) {},
        onAngleCommitted: (_, __) {},
      )));
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.onChanged, isNull);
      expect(slider.onChangeEnd, isNull);
      expect(find.text('Moving...'), findsOneWidget);
    });

    testWidgets('base slider is disabled while moving',
        (WidgetTester tester) async {
      await tester.pumpWidget(harness(BaseRotationControlWidget(
        baseRotation: const BaseRotationEntity(
            currentDegrees: 0,
            targetDegrees: 10,
            speed: 50,
            isMoving: true),
        onRotationChanged: (_, __) {},
        onRotationCommitted: (_, __) {},
      )));
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.onChanged, isNull);
      expect(slider.onChangeEnd, isNull);
      expect(find.text('Moving...'), findsOneWidget);
    });

    testWidgets('base slider honors the -180..180 firmware range',
        (WidgetTester tester) async {
      await tester.pumpWidget(harness(BaseRotationControlWidget(
        baseRotation: const BaseRotationEntity(
            currentDegrees: 0,
            targetDegrees: 0,
            speed: 50,
            isMoving: false),
        onRotationChanged: (_, __) {},
        onRotationCommitted: (_, __) {},
      )));
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.min, -180.0);
      expect(slider.max, 180.0);
    });

    testWidgets('movement status reflects idle / moving / paused',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          harness(const MovementStatusWidget(isMoving: false, isPaused: false)));
      expect(find.text('IDLE'), findsOneWidget);

      await tester.pumpWidget(
          harness(const MovementStatusWidget(isMoving: true, isPaused: false)));
      expect(find.text('MOVING'), findsOneWidget);

      await tester.pumpWidget(
          harness(const MovementStatusWidget(isMoving: true, isPaused: true)));
      expect(find.text('PAUSED'), findsOneWidget);
    });
  });

  group('settings limits match the verified firmware bounds', () {
    testWidgets('shows 0-45 cm and -180..180°', (WidgetTester tester) async {
      await tester.pumpWidget(harness(const RobotLimitsSection()));
      expect(find.text('0 - 45 cm'), findsOneWidget);
      expect(find.text('-180° - 180°'), findsOneWidget);
      expect(find.text('0° - 180°'), findsOneWidget);
      // Legacy wrong ranges must be gone.
      expect(find.text('0 - 100 cm'), findsNothing);
      expect(find.text('0° - 360°'), findsNothing);
    });
  });
}
