import 'package:flutter/material.dart';
import '../../../../core/extensions/theme_extensions.dart';

class PresetCardHeader extends StatelessWidget {
  final String name;
  final String description;

  const PresetCardHeader({super.key, required this.name, required this.description});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(color: context.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
