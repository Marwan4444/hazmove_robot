import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hazmove_robot/core/error/failure.dart';
import 'package:hazmove_robot/presentation/view/home/widgets/connection_status_card.dart';
import 'package:hazmove_robot/presentation/view/root/cubit/robot_control_cubit.dart';

import '../fakes.dart';

// NOTE: package assets (translation JSON) are not served under
// `flutter test`, so `.tr()` falls back to the key itself. Asserting on the
// key still verifies the connected/disconnected/connecting branch logic.
const connectedKey = 'connection.connected';
const disconnectedKey = 'connection.disconnected';
const connectingKey = 'connection.connecting';

Widget harness(RobotControlState state) => EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translation',
      fallbackLocale: const Locale('en'),
      child: MaterialApp(
        home: Scaffold(body: ConnectionStatusCard(state: state)),
      ),
    );

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('ConnectionStatusCard', () {
    testWidgets('shows connected state with wifi icon',
        (WidgetTester tester) async {
      await tester.pumpWidget(harness(const RobotControlState(
        connectionStatus: ConnectionStatus.connected,
        robotArm: null,
      )));
      await tester.pump();
      expect(find.text(connectedKey), findsOneWidget);
      expect(find.byIcon(Icons.wifi), findsOneWidget);
    });

    testWidgets('shows disconnected state with wifi_off icon',
        (WidgetTester tester) async {
      await tester.pumpWidget(harness(const RobotControlState(
        connectionStatus: ConnectionStatus.disconnected,
        robotArm: null,
      )));
      await tester.pump();
      expect(find.text(disconnectedKey), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });

    testWidgets('surfaces failure messages for rejected commands',
        (WidgetTester tester) async {
      const state = RobotControlState(
        connectionStatus: ConnectionStatus.connected,
        robotArm: null,
        failure: Failure('Target is outside the robot safety limits.',
            type: FailureType.rejected),
      );
      await tester.pumpWidget(harness(state));
      await tester.pump();
      expect(find.text('Target is outside the robot safety limits.'),
          findsOneWidget);
    });

    testWidgets('live arm state does not break the card',
        (WidgetTester tester) async {
      await tester.pumpWidget(harness(RobotControlState(
        connectionStatus: ConnectionStatus.connected,
        robotArm: testArm(),
      )));
      await tester.pump();
      expect(find.text(connectedKey), findsOneWidget);
    });
  });
}
