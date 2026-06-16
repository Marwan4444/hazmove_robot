import 'package:flutter/material.dart';
import 'package:hazmove_robot/core/extensions/theme_extensions.dart';
import '../../../../modules/robot_control/domain/models/movement_preset_model.dart';
import '../../../../core/style/glass_container.dart';
import 'preset_card_header.dart';
import 'preset_card_info.dart';
import 'preset_card_actions.dart';

class PresetCardWidget extends StatelessWidget {
  final MovementPresetModel preset;
  final VoidCallback onExecute;

  const PresetCardWidget({
    super.key,
    required this.preset,
    required this.onExecute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.accentPrimary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: context.accentPrimary.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(color: context.accentPrimary.withOpacity(0.4), blurRadius: 15, spreadRadius: 2),
        ],
      ),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(15),
        blur: 15.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PresetCardHeader(name: preset.name, description: preset.description),
            const SizedBox(height: 12),
            PresetCardInfo(stepsCount: preset.steps.length),
            const SizedBox(height: 16),
            PresetCardActions(onExecute: onExecute),
          ],
        ),
      ),
    );
  }
}
