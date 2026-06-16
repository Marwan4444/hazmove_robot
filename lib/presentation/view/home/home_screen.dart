import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hazmove_robot/presentation/view/root/cubit/robot_control_cubit.dart';
import '../../../../core/services/localization/locale_keys.g.dart';
import '../../../../core/extensions/theme_extensions.dart';
import 'widgets/animated_robotic_arm.dart';
import 'widgets/premium_animated_text.dart';
import 'widgets/control_buttons.dart';
import 'widgets/home_background.dart';
import 'widgets/ambient_blob.dart';
import 'widgets/home_app_bar.dart';
import 'widgets/home_navigation.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const HomeBackground(),
          Positioned(top: -100, left: -100, child: AmbientBlob(color: context.accentPrimary, size: 350)),
          Positioned(bottom: 50, right: -80, child: AmbientBlob(color: context.accentSecondary, size: 300)),
          Positioned(top: 250, left: 50, child: AmbientBlob(color: context.accentGreen.withOpacity(0.4), size: 200)),
          
          SafeArea(
            child: BlocBuilder<RobotControlCubit, RobotControlState>(
              builder: (context, state) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 100, left: 20, right: 20, bottom: 20),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 30, bottom: 10),
                        child: const AnimatedRoboticArm(),
                      ),
                      const PremiumAnimatedText(text: 'Hazmove'),
                      const SizedBox(height: 20),
                      Center(child: _buildConnectionIndicator(state)),
                      const SizedBox(height: 30),
                      ControlButtons(
                        isConnected: state.connectionStatus == ConnectionStatus.connected,
                        isPaused: state.isPaused,
                        isLoading: state.isLoading,
                        onPause: () => context.read<RobotControlCubit>().pauseMovements(),
                        onResume: () => context.read<RobotControlCubit>().resumeMovements(),
                        onStop: () => context.read<RobotControlCubit>().stopAllMovements(),
                      ),
                      const SizedBox(height: 30),
                      const HomeNavigation(),
                    ],
                  ),
                );
              },
            ),
          ),
          
          const HomeAppBar(),
        ],
      ),
    );
  }

  Widget _buildConnectionIndicator(RobotControlState state) {
    Color color;
    String text;
    IconData icon;

    switch (state.connectionStatus) {
      case ConnectionStatus.connected:
        color = Colors.greenAccent;
        text = LocaleKeys.connection_connected.tr();
        icon = Icons.bluetooth_connected;
        break;
      case ConnectionStatus.connecting:
        color = Colors.orange;
        text = LocaleKeys.connection_connecting.tr();
        icon = Icons.bluetooth_searching;
        break;
      case ConnectionStatus.disconnected:
        color = Colors.redAccent;
        text = LocaleKeys.connection_disconnected.tr();
        icon = Icons.bluetooth_disabled;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
