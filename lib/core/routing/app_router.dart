import 'package:flutter/material.dart';

import 'package:hazmove_robot/presentation/view/auto/auto_mode_screen.dart';
import 'package:hazmove_robot/presentation/view/manual/manual_control_screen.dart';
import 'package:hazmove_robot/presentation/view/settings/settings_screen.dart';
import '../../presentation/view/home/home_screen.dart';


class AppRouter {
  AppRouter._();

  // ─── Route Names ───
  static const String home = '/';
  static const String manual = '/manual';
  static const String auto = '/auto';
  static const String settings = '/settings';

  // ─── Route Generator ───
  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case manual:
        return MaterialPageRoute(builder: (_) => const ManualControlScreen());
      case auto:
        return MaterialPageRoute(builder: (_) => const AutoModeScreen());
      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
    }
  }
}
