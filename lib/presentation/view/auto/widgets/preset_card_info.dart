import 'package:flutter/material.dart';
import '../../../../core/extensions/theme_extensions.dart';

class PresetCardInfo extends StatelessWidget {
  final int stepsCount;

  const PresetCardInfo({super.key, required this.stepsCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.list, color: context.accentPrimary, size: 16),
        const SizedBox(width: 6),
        Text(
          '$stepsCount steps',
          style: TextStyle(color: context.accentPrimary, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
