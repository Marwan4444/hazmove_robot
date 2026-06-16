import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/extensions/theme_extensions.dart';
import '../cubit/presets_cubit.dart';

class DeletePresetDialog extends StatelessWidget {
  final String presetId;
  const DeletePresetDialog({super.key, required this.presetId});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.dialogBg,
      title: Text('Delete Preset', style: TextStyle(color: context.textPrimary)),
      content: Text('Are you sure you want to delete this preset?', style: TextStyle(color: context.textSecondary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: context.accentPrimary)),
        ),
        TextButton(
          onPressed: () {
            context.read<PresetsCubit>().deletePreset(presetId);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Preset deleted'), backgroundColor: Colors.red),
            );
          },
          child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    );
  }
}
