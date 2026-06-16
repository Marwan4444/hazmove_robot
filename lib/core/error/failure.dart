import 'package:equatable/equatable.dart';

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
  unknown
}

class Failure extends Equatable {
  final String message;
  final FailureType type;

  const Failure(this.message, {this.type = FailureType.unknown});

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

