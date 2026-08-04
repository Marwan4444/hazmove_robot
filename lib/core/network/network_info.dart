import 'package:fpdart/fpdart.dart';
import 'package:hazmove_robot/core/error/failure.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
  Future<Either<Failure, void>> checkConnection();
}

class NetworkInfoImpl implements NetworkInfo {
  NetworkInfoImpl();

  @override
  Future<bool> get isConnected async {
    try {
      // Implementation for checking network connectivity
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Either<Failure, void>> checkConnection() async {
    if (await isConnected) {
      return const Right(null);
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }
}
