import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/extensions/theme_extensions.dart';
import '../../../core/services/localization/locale_keys.g.dart';
import '../../../core/style/glass_container.dart';
import '../home/widgets/ambient_blob.dart';
import '../home/widgets/home_background.dart';
import '../root/cubit/robot_control_cubit.dart';
import '../../../modules/robot_control/domain/enums/robot_enums.dart';
import '../auto/cubit/auto_modes_cubit.dart';
import 'widgets/base_rotation_control_widget.dart';
import 'widgets/live_values_dashboard.dart';
import 'widgets/linear_rail_control_widget.dart';
import 'widgets/quick_actions_panel.dart';
import 'widgets/servo_control_widget.dart';

class ManualControlScreen extends StatefulWidget {
  const ManualControlScreen({super.key});

  @override
  State<ManualControlScreen> createState() => _ManualControlScreenState();
}

class _ManualControlScreenState extends State<ManualControlScreen> {
  String _selectedControlId = 'servo_1';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const HomeBackground(),
          Positioned(
            top: -100,
            left: -100,
            child: AmbientBlob(color: context.accentPrimary, size: 350),
          ),
          Positioned(
            bottom: 50,
            right: -80,
            child: AmbientBlob(color: context.accentSecondary, size: 300),
          ),
          Positioned(
            top: 250,
            left: 50,
            child: AmbientBlob(
              color: context.accentGreen.withOpacity(0.4),
              size: 200,
            ),
          ),
          SafeArea(
            child: BlocBuilder<RobotControlCubit, RobotControlState>(
              builder: (context, state) {
                final servos = state.robotArm?.servos ?? [];
                final hasSelectedServo = servos.any(
                  (servo) => _selectedControlId == 'servo_${servo.id}',
                );
                if (!hasSelectedServo &&
                    _selectedControlId.startsWith('servo_') &&
                    servos.isNotEmpty) {
                  _selectedControlId = 'servo_${servos.first.id}';
                }

                return Padding(
                  padding: const EdgeInsets.only(
                    top: 100,
                    left: 20,
                    right: 20,
                    bottom: 98,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: SingleChildScrollView(
                          child: LiveValuesDashboard(
                            robotArm: state.robotArm,
                            selectedId: _selectedControlId,
                            onSelected: (id) {
                              setState(() => _selectedControlId = id);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        flex: 3,
                        child: _buildSelectedControl(context, state),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: BlocBuilder<RobotControlCubit, RobotControlState>(
                builder: (context, state) {
                  return QuickActionsPanel(
                    isPaused: state.isPaused,
                    onStop: () {
                      context.read<RobotControlCubit>().stopAllMovements();
                    },
                    onPause: () {
                      context.read<RobotControlCubit>().pauseMovements();
                    },
                    onResume: () {
                      context.read<RobotControlCubit>().resumeMovements();
                    },
                  );
                },
              ),
            ),
          ),
          BlocBuilder<RobotControlCubit, RobotControlState>(
            builder: (context, state) {
              final autoModesCubit = context.watch<AutoModesCubit>();
              final runningMode = autoModesCubit.state.currentMode;
              final isAutoMode = state.robotArm?.mode == RobotMode.auto ||
                  runningMode != AutoModeType.none;
              if (!isAutoMode) return const SizedBox.shrink();

              String descText = LocaleKeys.auto_modes_manual_disabled_desc.tr();
              if (runningMode != AutoModeType.none) {
                final modeName = runningMode == AutoModeType.mode1 
                    ? LocaleKeys.auto_modes_mode1.tr() 
                    : LocaleKeys.auto_modes_mode2.tr();
                
                if (context.locale.languageCode == 'ar') {
                  descText = 'الروبوت يعمل حالياً بـ $modeName.\nيرجى إيقاف الوضع النشط أولاً للتحكم يدوياً.';
                } else {
                  descText = 'The robot is currently running in $modeName.\nPlease stop the active mode first to control manually.';
                }
              }

              return Positioned(
                top: 100,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Colors.black.withOpacity(0.75),
                  child: Center(
                    child: GlassContainer(
                      padding: const EdgeInsets.all(24),
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_outline_rounded, size: 48, color: context.accentSecondary),
                          const SizedBox(height: 16),
                          Text(
                            LocaleKeys.auto_modes_manual_disabled_title.tr(),
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            descText,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          _ManualAppBar(
            onReset: () => _resetPosition(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedControl(BuildContext context, RobotControlState state) {
    if (_selectedControlId == 'rail') {
      return SingleChildScrollView(
        child: LinearRailControlWidget(
          linearRail: state.robotArm?.linearRail,
          onPositionCommitted: (position) {
            context.read<RobotControlCubit>().setLinearPosition(position, 50);
          },
        ),
      );
    }
    if (_selectedControlId == 'base') {
      return SingleChildScrollView(
        child: BaseRotationControlWidget(
          baseRotation: state.robotArm?.baseRotation,
          // UI-only: update display while dragging
          onRotationChanged: (degrees, speed) {
            context.read<RobotControlCubit>().updateBaseRotationLocally(degrees, speed);
          },
          // Send to ESP32 only when finger is lifted
          onRotationCommitted: (degrees, speed) {
            context.read<RobotControlCubit>().setBaseRotation(degrees, speed);
          },
        ),
      );
    }

    final servos = state.robotArm?.servos ?? [];
    final selectedServo = servos.where(
      (servo) => _selectedControlId == 'servo_${servo.id}',
    );

    if (selectedServo.isEmpty) {
      return GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(18),
        child: Text(
          'Select a control card',
          style: TextStyle(color: context.textSecondary, fontSize: 14),
        ),
      );
    }

    final servo = selectedServo.first;

    return SingleChildScrollView(
      child: ServoControlWidget(
        servo: servo,
        // UI-only: update display while dragging
        onAngleChanged: (angle, speed) {
          context.read<RobotControlCubit>().updateServoAngleLocally(
                servo.id, angle, speed);
        },
        // Send to ESP32 only when finger is lifted
        onAngleCommitted: (angle, speed) {
          context.read<RobotControlCubit>().setServoAngle(
                servo.id, angle, speed);
        },
      ),
    );
  }

  void _resetPosition(BuildContext context) {
    final cubit = context.read<RobotControlCubit>();
    final home = RobotControlCubit.defaultRobotArm;

    for (final servo in home.servos) {
      cubit.setServoAngle(servo.id, servo.targetAngle, servo.speed);
    }

    cubit.setLinearPosition(
      home.linearRail.targetPosition,
      home.linearRail.speed,
    );
    cubit.setBaseRotation(
      home.baseRotation.targetDegrees,
      home.baseRotation.speed,
    );
  }
}

class _ManualAppBar extends StatelessWidget {
  final VoidCallback onReset;

  const _ManualAppBar({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            borderRadius: BorderRadius.circular(30),
            blur: 25.0,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: context.textPrimary,
                    size: 18,
                  ),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                ),
                Expanded(
                  child: Text(
                    LocaleKeys.control_manual.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onReset,
                  icon: Icon(
                    Icons.restart_alt_rounded,
                    color: context.accentPrimary,
                    size: 22,
                  ),
                  tooltip: LocaleKeys.control_reset_btn.tr(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
