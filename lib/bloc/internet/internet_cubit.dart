import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/network/network_info.dart';

// States
abstract class InternetState extends Equatable {
  const InternetState();
  @override
  List<Object> get props => [];
}

class InternetLoading extends InternetState {}
class InternetConnected extends InternetState {}
class InternetDisconnected extends InternetState {}

// Cubit
class InternetCubit extends Cubit<InternetState> {
  final NetworkInfo networkInfo;
  StreamSubscription? _subscription;

  InternetCubit(this.networkInfo) : super(InternetLoading()) {
    _monitorInternetConnection();
  }

  void _monitorInternetConnection() {
    // Listen to updates
    _subscription = networkInfo.onConnectivityChanged.listen((results) {
      _emitState(results);
    });
    
    // Check initial
    Connectivity().checkConnectivity().then((results) => _emitState(results));
  }

  void _emitState(List<ConnectivityResult> results) {
    // Force connected state for now as monitoring is inaccurate
    emit(InternetConnected());
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
