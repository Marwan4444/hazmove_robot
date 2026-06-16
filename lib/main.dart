import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'core/di/main_di.dart';
import 'presentation/view/root/app.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  
  // Preserve splash screen until initialization is complete
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  // Initialize dependency injection manual GetIt locator
  await initDI();
  
  // Initialize easy localization
  await EasyLocalization.ensureInitialized();

  // Initialize Hydrated storage for theme persistence
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: await getApplicationDocumentsDirectory(),
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translation',
      fallbackLocale: const Locale('en'),
      child: const MyApp(),
    ),
  );
  
  // Remove splash screen now that app is rendering
  FlutterNativeSplash.remove();
}

