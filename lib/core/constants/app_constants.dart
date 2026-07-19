class AppConstants {
  // Network
  static const String defaultWebSocketUrl = 'ws://192.168.4.1:81';
  static const int connectionTimeout = 15000;
  static const int sendTimeout = 5000;
  
  // Robot Arm Limits
  static const int maxServoAngle = 180;
  static const int minServoAngle = 0;
  static const double maxLinearDistance = 100.0; // cm
  static const double minLinearDistance = 0.0;
  static const double maxBaseRotation = 360.0; // degrees
  static const double minBaseRotation = 0.0;
  
  // Speed Limits
  static const int maxServoSpeed = 100;
  static const int minServoSpeed = 1;
  static const int maxLinearSpeed = 100;
  static const int minLinearSpeed = 1;
  static const int maxBaseSpeed = 100;
  static const int minBaseSpeed = 1;
  
  // UI
  static const String appName = 'HazMove Robot Control';
  static const String version = '1.0.0';
  
  // Storage Keys
  static const String presetsKey = 'robot_presets';
  static const String settingsKey = 'app_settings';
  static const String connectionKey = 'connection_config';
}

class RobotCommands {
  static const String servo = 'servo';
  static const String linear = 'linear';
  static const String base = 'base';
  static const String stop = 'stop';
  static const String pause = 'pause';
  static const String resume = 'resume';
  static const String status = 'status';
}

class ServoIds {
  static const int base = 1;
  static const int shoulder = 2;
  static const int elbow = 3;
  static const int wrist = 4;
  static const int gripper = 5;
}
