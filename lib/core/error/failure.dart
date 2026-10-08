import 'package:equatable/equatable.dart';
import '../services/localization/locale_keys.g.dart';

enum FailureType {
  badRequest,
  authentication,
  forbidden,
  notFound,
  invalidInput,
  serv,
  timeout,
  noInternet,
  bluetooth,
  unknown,

  /// Firmware explicitly refused the command (REJECT frame).
  /// e.g. OUT_OF_RANGE, INVALID_SERVO_ID, BUSY, INVALID_MODE.
  rejected,

  /// Firmware accepted then failed the command (ERROR frame).
  firmwareError,

  /// No live WebSocket channel to the robot.
  disconnected,

  /// Local preset execution was cancelled by the user.
  cancelled,
}

class Failure extends Equatable {
  final String message;
  final FailureType type;

  const Failure(this.message, {this.type = FailureType.unknown});

  /// Localization key for fixed-text failures. When non-null, the UI shows
  /// `messageKey.tr()` instead of [message]. Failures carrying dynamic
  /// detail (invalid input values, firmware reject reasons) return `null`
  /// and fall back to the English [message].
  String? get messageKey {
    switch (type) {
      case FailureType.noInternet:
        return LocaleKeys.errors_no_connection;
      case FailureType.disconnected:
        return LocaleKeys.errors_disconnected;
      case FailureType.timeout:
        return LocaleKeys.errors_timeout;
      case FailureType.cancelled:
        return LocaleKeys.errors_cancelled;
      case FailureType.firmwareError:
        return LocaleKeys.errors_firmware_error;
      case FailureType.unknown:
        return LocaleKeys.errors_unknown;
      default:
        return null;
    }
  }

  /// User-facing message: safe to show in a SnackBar. Never exposes raw
  /// transport dumps; keeps the technical [message] for logs.
  String get userMessage {
    switch (type) {
      case FailureType.noInternet:
        return 'No connection to the robot. Check Wi-Fi and reconnect.';
      case FailureType.disconnected:
        return 'Robot is not connected. Connect first, then retry.';
      case FailureType.timeout:
        return 'Robot did not respond in time. Check the connection and retry.';
      case FailureType.invalidInput:
        return message;
      case FailureType.rejected:
        return message;
      case FailureType.firmwareError:
        return 'Robot reported an error: $message';
      case FailureType.cancelled:
        return 'Movement cancelled.';
      case FailureType.bluetooth:
        return 'Bluetooth error: $message';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  List<Object?> get props => [message, type];

  factory Failure.fromException(dynamic exception) {
    if (exception is Failure) {
      return exception;
    }
    // Simple custom exception mapper
    final message = exception.toString().replaceAll('Exception: ', '');
    if (message.contains('SocketException') || message.contains('Network')) {
      return Failure(message, type: FailureType.noInternet);
    } else if (message.contains('Timeout') || message.contains('timeout')) {
      return Failure(message, type: FailureType.timeout);
    } else if (message.contains('Bluetooth') || message.contains('bluetooth')) {
      return Failure(message, type: FailureType.bluetooth);
    }
    return Failure(message, type: FailureType.unknown);
  }
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message) : super(type: FailureType.noInternet);
}

