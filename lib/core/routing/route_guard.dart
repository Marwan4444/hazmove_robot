import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hazmove_robot/presentation/view/root/cubit/robot_control_cubit.dart';

class RouteGuard {
  RouteGuard._();

  /// Checks if the robot is connected before allowing navigation.
  /// Returns true if navigation should proceed.
  static bool canNavigate(
    BuildContext context, {
    bool requireConnection = false,
  }) {
    if (!requireConnection) return true;

    final state = context.read<RobotControlCubit>().state;
    if (state.connectionStatus != ConnectionStatus.connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please connect to the robot first'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return false;
    }
    return true;
  }

  /// Navigate to a named route with an optional connection guard.
  static void navigateTo(
    BuildContext context,
    String route, {
    bool requireConnection = false,
  }) {
    if (canNavigate(context, requireConnection: requireConnection)) {
      Navigator.pushNamed(context, route);
    }
  }

  /// Navigate and replace the current route.
  static void navigateAndReplace(
    BuildContext context,
    String route, {
    bool requireConnection = false,
  }) {
    if (canNavigate(context, requireConnection: requireConnection)) {
      Navigator.pushReplacementNamed(context, route);
    }
  }
}
