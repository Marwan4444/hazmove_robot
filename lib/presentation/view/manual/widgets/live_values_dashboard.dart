import 'package:flutter/material.dart';
import '../../../../core/extensions/theme_extensions.dart';
import '../../../../core/style/glass_container.dart';
import '../../../../modules/robot_control/domain/entities/robot_arm_entity.dart';

class LiveValuesDashboard extends StatelessWidget {
  final RobotArmEntity? robotArm;
  final String selectedId;
  final ValueChanged<String> onSelected;

  const LiveValuesDashboard({
    super.key,
    required this.robotArm,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (robotArm == null) {
      return GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(18),
        child: Text(
          'No live values available',
          style: TextStyle(color: context.textSecondary, fontSize: 14),
        ),
      );
    }

    final arm = robotArm!;
    final items = [
      ...arm.servos.map(
        (servo) => _LiveValueItem(
          id: 'servo_${servo.id}',
          label: servo.name,
          value: '${servo.currentAngle}\u00b0',
          color: context.accentPrimary,
          icon: Icons.tune_rounded,
          isSelected: selectedId == 'servo_${servo.id}',
          onTap: onSelected,
        ),
      ),
      _LiveValueItem(
        id: 'rail',
        label: 'Linear Rail',
        value: '${arm.linearRail.currentPosition.toStringAsFixed(1)} cm',
        color: context.accentGreen,
        icon: Icons.straighten_rounded,
        isSelected: selectedId == 'rail',
        onTap: onSelected,
      ),
      _LiveValueItem(
        id: 'base',
        label: 'Base Rotation',
        value: '${arm.baseRotation.currentDegrees.toStringAsFixed(1)}\u00b0',
        color: context.accentSecondary,
        icon: Icons.rotate_right_rounded,
        isSelected: selectedId == 'base',
        onTap: onSelected,
      ),
    ];

    return GlassContainer(
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: context.cardBorder.withOpacity(context.isDarkMode ? 0.8 : 0.6),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth - 10) / 2;

          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final item in items) SizedBox(width: itemWidth, child: item),
            ],
          );
        },
      ),
    );
  }
}

class _LiveValueItem extends StatelessWidget {
  final String id;
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool isSelected;
  final ValueChanged<String> onTap;

  const _LiveValueItem({
    required this.id,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => onTap(id),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(isSelected ? 0.24 : 0.12),
                Colors.white.withOpacity(context.isDarkMode ? 0.03 : 0.36),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? color.withOpacity(0.85)
                  : color.withOpacity(context.isDarkMode ? 0.28 : 0.2),
              width: isSelected ? 1.4 : 1,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: color.withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color.withOpacity(isSelected ? 0.24 : 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 16),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Icon(Icons.check_circle_rounded, color: color, size: 16),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
