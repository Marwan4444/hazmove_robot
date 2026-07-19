import 'package:get_it/get_it.dart';
import '../../modules/robot_control/data/robot_control_remote_data_source.dart';
import '../../modules/robot_control/data/robot_control_local_data_source.dart';
import '../../modules/robot_control/data/providers/robot_control_remote_data_source_api_imp.dart';
import '../../modules/robot_control/data/providers/robot_control_local_data_source_imp.dart';
import '../../modules/robot_control/domain/repo/robot_control_repo.dart';
import '../../modules/robot_control/data/providers/robot_control_repo_impl.dart';
import '../../presentation/view/root/cubit/robot_control_cubit.dart';
import '../../presentation/view/auto/cubit/presets_cubit.dart';
import '../../presentation/view/auto/cubit/auto_modes_cubit.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import '../network/network_info.dart';
import '../style/theme_cubit.dart';

final getIt = GetIt.instance;

Future<void> initDI() async {
  // Services & Cubits (Theme)
  getIt.registerLazySingleton<ThemeCubit>(() => ThemeCubit());

  getIt.registerLazySingleton<InternetConnection>(() => InternetConnection());
  getIt.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(getIt<InternetConnection>()),
  );

  // Data Sources
  getIt.registerLazySingleton<RobotRemoteDataSource>(
    () => RobotRemoteDataSourceApiImp(),
  );
  getIt.registerLazySingleton<RobotLocalDataSource>(
    () => RobotLocalDataSourceImp(),
  );

  // Repositories
  getIt.registerFactory<RobotControlRepo>(
    () => RobotControlRepoImpl(
      remoteDataSource: getIt<RobotRemoteDataSource>(),
      localDataSource: getIt<RobotLocalDataSource>(),
    ),
  );

  // Cubits
  getIt.registerFactory<RobotControlCubit>(
    () => RobotControlCubit(repository: getIt<RobotControlRepo>()),
  );
  
  getIt.registerFactory<PresetsCubit>(
    () => PresetsCubit(repository: getIt<RobotControlRepo>()),
  );

  getIt.registerFactory<AutoModesCubit>(
    () => AutoModesCubit(repository: getIt<RobotControlRepo>()),
  );
}
