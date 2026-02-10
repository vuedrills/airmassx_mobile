import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';

enum MapProvider { osm, google }

class MapSettingsState {
  final MapProvider provider;
  final bool isLoading;

  MapSettingsState({
    required this.provider,
    this.isLoading = false,
  });

  MapSettingsState copyWith({
    MapProvider? provider,
    bool? isLoading,
  }) {
    return MapSettingsState(
      provider: provider ?? this.provider,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class MapSettingsCubit extends Cubit<MapSettingsState> {
  final ApiService _apiService;

  MapSettingsCubit(this._apiService) : super(MapSettingsState(provider: MapProvider.osm)) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    emit(state.copyWith(isLoading: true));
    try {
      final providerStr = await _apiService.getMapProvider();
      final provider = providerStr == 'google' ? MapProvider.google : MapProvider.osm;
      emit(state.copyWith(provider: provider, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }

  void setProvider(MapProvider provider) {
    emit(state.copyWith(provider: provider));
  }
}
