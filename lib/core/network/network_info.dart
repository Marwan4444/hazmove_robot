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
  /// Injectable probe for tests. The default enumerates real interfaces:
  /// `true` when any non-loopback IPv4 interface exists (covers the
  /// ESP32-AP-without-internet case), fail-open `true` when enumeration
  /// itself throws (e.g. web) since the WebSocket handshake stays
  /// authoritative.
  final Future<bool> Function() probeNetwork;

  NetworkInfoImpl({Future<bool> Function()? probeNetwork})
      : probeNetwork = probeNetwork ?? _defaultProbe;

  static Future<bool> _defaultProbe() async {
    try {
      final interfaces = await NetworkInterface.list(
          includeLoopback: false, type: InternetAddressType.IPv4);
      return interfaces.any((iface) => iface.addresses.any((addr) =>
          addr.type == InternetAddressType.IPv4 && !addr.isLoopback));
    } catch (_) {
      return true;
    }
  }

  @override
  Future<bool> get isConnected => probeNetwork();

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
