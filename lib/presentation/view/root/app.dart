import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hazmove_robot/core/di/main_di.dart';
import 'package:hazmove_robot/core/routing/app_router.dart';
import 'package:hazmove_robot/core/style/theme_cubit.dart';

import 'cubit/robot_control_cubit.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(
          create: (context) => getIt<ThemeCubit>(),
        ),
        BlocProvider<RobotControlCubit>(
          create: (context) => getIt<RobotControlCubit>()..loadStatus(),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              return MaterialApp(
                title: 'HazMove Robot Control',
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                debugShowCheckedModeBanner: false,
                themeMode: themeMode,
                theme: ThemeData(
                  brightness: Brightness.light,
                  primarySwatch: Colors.orange,
                  scaffoldBackgroundColor: const Color(0xFFF8FAFC),
                  useMaterial3: true,
                  cardTheme: CardThemeData(
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Color(0xFF0F172A),
                    elevation: 0,
                    centerTitle: true,
                  ),
                  dialogTheme: const DialogThemeData(
                    backgroundColor: Colors.white,
                    elevation: 8,
                    titleTextStyle: TextStyle(color: Color(0xFF0F172A), fontSize: 20, fontWeight: FontWeight.bold),
                    contentTextStyle: TextStyle(color: Color(0xFF475569), fontSize: 16),
                  ),
                ),
                darkTheme: ThemeData(
                  brightness: Brightness.dark,
                  primarySwatch: Colors.orange,
                  scaffoldBackgroundColor: const Color(0xFF0F1115),
                  useMaterial3: true,
                  cardTheme: CardThemeData(
                    color: const Color(0xFF222731),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    centerTitle: true,
                  ),
                  dialogTheme: const DialogThemeData(
                    backgroundColor: Color(0xFF222731),
                    elevation: 8,
                    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    contentTextStyle: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
                initialRoute: AppRouter.home,
                onGenerateRoute: AppRouter.onGenerateRoute,
              );
            },
          );
        },
      ),
    );
  }
}
