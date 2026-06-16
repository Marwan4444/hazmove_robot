import 'package:flutter/material.dart';
import '../../../../core/extensions/theme_extensions.dart';
import '../../../../core/style/glass_container.dart';
import 'add_preset_dialog.dart';

class AutoFab extends StatelessWidget {
  const AutoFab({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog(context: context, builder: (_) => const AddPresetDialog()),
      child: Container(
        decoration: BoxDecoration(
          color: context.accentPrimary.withOpacity(0.25),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: context.accentPrimary.withOpacity(0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: context.accentPrimary.withOpacity(0.6),
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ],
        ),
        child: GlassContainer(
          padding: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(30),
          blur: 25.0,
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}
