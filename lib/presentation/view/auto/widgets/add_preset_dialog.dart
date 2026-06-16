import 'package:flutter/material.dart';
import '../../../../core/extensions/theme_extensions.dart';

class AddPresetDialog extends StatelessWidget {
  const AddPresetDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.dialogBg,
      title: Text('Create New Preset', style: TextStyle(color: context.textPrimary)),
      content: Text('Preset creation feature coming soon!', style: TextStyle(color: context.textSecondary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK', style: TextStyle(color: context.accentPrimary)),
        ),
      ],
    );
  }
}
