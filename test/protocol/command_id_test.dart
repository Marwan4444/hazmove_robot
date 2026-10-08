import 'package:flutter_test/flutter_test.dart';
import 'package:hazmove_robot/modules/robot_control/data/protocol/command_id.dart';

void main() {
  group('CommandId', () {
    test('generates non-empty unique ids', () {
      CommandId.resetForTest();
      final ids = List.generate(200, (_) => CommandId.newId());
      expect(ids.every((id) => id.isNotEmpty), isTrue);
      expect(ids.toSet().length, 200);
    });

    test('ids are strings safe for JSON transport', () {
      final id = CommandId.newId();
      expect(id, isNot(contains(' ')));
      expect(id, isNot(contains('"')));
    });
  });
}
