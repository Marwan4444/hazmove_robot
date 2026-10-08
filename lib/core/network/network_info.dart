import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:hazmove_robot/core/error/failure.dart';

/// Distinguishes **network availability** from **robot reachability**.
///
/// - [isConnected] reports whether the device has a usable local network
///   (any non-loopback IPv4 interface). This is `true` on the ESP32 soft-AP
///   even though that network has no internet access — by design, because
///   the robot is a local Wi-Fi device.
/// - The **authoritative** robot connection state is always the WebSocket
///   connection itself ([RobotControlRepo.connectionStatus]); this class is
///   advisory (fail fast with a friendly message, never a connection verdict).
///
/// No third-party plugin is used: `connectivity_plus` reports the uplink
/// type but cannot prove the ESP32 is reachable either, while
/// `NetworkInterface` works offline and covers the AP-without-internet case.
abstract class NetworkInfo {
  Future<bool> get isConnected;
  Future<Either<Failure, void>> checkConnection();
}

class NetworkInfoImpl implements NetworkInfo {
  /// Injectable for tests. Defaults to the real interface enumeration.
  final Future<List<NetworkInterface>> Function() listInterfaces;

  NetworkInfoImpl({Future<List<NetworkInterface>> Function()? listInterfaces})
      : listInterfaces = listInterfaces ??
            (() => NetworkInterface.list(
                includeLoopback: false, type: InternetAddressType.IPv4));

  @override
  Future<bool> get isConnected async {
    try {
      final interfaces = await listInterfaces();
      return interfaces.any((iface) => iface.addresses.any((addr) =>
          addr.type == InternetAddressType.IPv4 && !addr.isLoopback));
    } catch (_) {
      // Fail-open: on platforms that cannot enumerate interfaces (e.g. web)
      // absence of proof is not proof of absence. The WebSocket handshake
      // remains authoritative and will surface a real failure if needed.
      return true;
    }
  }

  @override
  Future<Either<Failure, void>> checkConnection() async {
    if (await isConnected) {
      return const Right(null);
    } else {
      return const Left(
          NetworkFailure('No local network. Join the robot Wi-Fi first.'));
    }
  }
}
