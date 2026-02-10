import 'package:equatable/equatable.dart';
import '../../models/equipment.dart';

abstract class InventoryState extends Equatable {
  const InventoryState();

  @override
  List<Object?> get props => [];
}

class InventoryInitial extends InventoryState {}

class InventoryLoading extends InventoryState {}

class InventoryLoaded extends InventoryState {
  final List<Equipment> items;
  const InventoryLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

class InventoryError extends InventoryState {
  final String message;
  const InventoryError(this.message);

  @override
  List<Object?> get props => [message];
}

class InventoryOperationSuccess extends InventoryState {
  final String message;
  const InventoryOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
