import 'dart:developer' as developer;

class Logger {
  static void debug(String message, [String? tag]) {
    developer.log(
      message,
      name: tag ?? 'HazMoveRobot',
      level: 500,
    );
  }

  static void info(String message, [String? tag]) {
    developer.log(
      message,
      name: tag ?? 'HazMoveRobot',
      level: 800,
    );
  }

  static void warning(String message, [String? tag]) {
    developer.log(
      message,
      name: tag ?? 'HazMoveRobot',
      level: 900,
    );
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: 'HazMoveRobot',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }
}
