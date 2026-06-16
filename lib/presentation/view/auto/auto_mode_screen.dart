import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/main_di.dart';
import '../../../core/extensions/theme_extensions.dart';
import '../home/widgets/ambient_blob.dart';
import '../home/widgets/home_background.dart';
import 'cubit/presets_cubit.dart';
import 'widgets/auto_app_bar.dart';
import 'widgets/auto_presets_list.dart';

class AutoModeScreen extends StatelessWidget {
  const AutoModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<PresetsCubit>()..loadPresets(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            const HomeBackground(),
            Positioned(top: -100, left: -100, child: AmbientBlob(color: context.accentPrimary, size: 350)),
            Positioned(bottom: 50, right: -80, child: AmbientBlob(color: context.accentSecondary, size: 300)),
            Positioned(top: 250, left: 50, child: AmbientBlob(color: context.accentGreen.withOpacity(0.4), size: 200)),
            const SafeArea(
              child: Padding(
                padding: EdgeInsets.only(top: 110, left: 20, right: 20, bottom: 20),
                child: Column(children: [Expanded(child: AutoPresetsList())]),
              ),
            ),
            const AutoAppBar(),
          ],
        ),
      ),
    );
  }
}
