import 'package:flutter_test/flutter_test.dart';
import 'package:hazmove_robot/core/error/failure.dart';
import 'package:hazmove_robot/core/network/network_info.dart';

void main() {
  group('NetworkInfo', () {
    test('reports connected when the probe finds a network', () async {
      final info = NetworkInfoImpl(probeNetwork: () async => true);
      expect(await info.isConnected, isTrue);
      expect((await info.checkConnection()).isRight(), isTrue);
    });

    test('reports disconnected with no network, mapping to a Failure',
        () async {
      final info = NetworkInfoImpl(probeNetwork: () async => false);
      expect(await info.isConnected, isFalse);
      final result = await info.checkConnection();
      expect(result.isLeft(), isTrue);
      expect(result.fold((l) => l, (_) => null)?.type,
          FailureType.noInternet);
    });

    test('default probe runs against real interfaces without throwing',
        () async {
      final info = NetworkInfoImpl();
      final connected = await info.isConnected;
      expect(connected, isA<bool>());
    });
  });
}
