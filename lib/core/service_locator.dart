import 'package:get_it/get_it.dart';
import '../services/api_service.dart';
import '../services/realtime_service.dart';
import '../services/notification_service.dart';
import '../services/ad_service.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/task/task_bloc.dart';
import '../bloc/create_task/create_task_bloc.dart';
import '../bloc/offer/offer_bloc.dart';
import '../bloc/offer/offer_list_bloc.dart';
import '../bloc/message/message_bloc.dart';
import '../bloc/profile/profile_bloc.dart';
import '../bloc/question/question_bloc.dart';
import '../bloc/browse/browse_bloc.dart';
import '../bloc/search/search_bloc.dart';
import '../bloc/filter/filter_bloc.dart';
import '../bloc/invoice/invoice_bloc.dart';
import '../bloc/inventory/inventory_bloc.dart';
import '../bloc/category/category_bloc.dart';
import '../core/network/network_info.dart';
import '../bloc/internet/internet_cubit.dart';
import '../bloc/map_settings/map_settings_cubit.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  // Core
  getIt.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(Connectivity()));
  
  // Register services - using real API service
  getIt.registerLazySingleton<ApiService>(() => ApiService());
  getIt.registerLazySingleton<RealtimeService>(() => RealtimeService());  
  getIt.registerLazySingleton<NotificationService>(() => NotificationService());
  getIt.registerLazySingleton<AdService>(() => AdService());
  // Register BLoCs - all now use ApiService for real backend data
  getIt.registerSingleton<AuthBloc>(AuthBloc()); // Singleton for go_router
  getIt.registerLazySingleton<TaskBloc>(() => TaskBloc(getIt<ApiService>())); // Singleton to preserve state
  getIt.registerFactory(() => CreateTaskBloc(getIt<ApiService>()));
  getIt.registerFactory(() => OfferBloc());
  getIt.registerFactory(() => OfferListBloc(getIt<ApiService>()));
  getIt.registerFactory(() => MessageBloc(getIt<ApiService>()));
  getIt.registerLazySingleton<ProfileBloc>(() => ProfileBloc(getIt<ApiService>()));
  getIt.registerFactory(() => QuestionBloc(getIt<ApiService>()));
  getIt.registerFactory(() => BrowseBloc(getIt<ApiService>()));
  getIt.registerFactory(() => SearchBloc(getIt<ApiService>()));
  getIt.registerFactory(() => FilterBloc());
  getIt.registerFactory(() => InvoiceBloc());
  getIt.registerFactory(() => InventoryBloc());

  getIt.registerLazySingleton<CategoryBloc>(() => CategoryBloc(getIt<ApiService>()));
  getIt.registerSingleton<InternetCubit>(InternetCubit(getIt<NetworkInfo>()));
  getIt.registerSingleton<MapSettingsCubit>(MapSettingsCubit(getIt<ApiService>()));
}
