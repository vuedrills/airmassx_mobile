import 'package:equatable/equatable.dart';
import '../../models/equipment.dart';

abstract class InventoryEvent extends Equatable {
  const InventoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadInventory extends InventoryEvent {}

class AddInventoryItem extends InventoryEvent {
  final Map<String, dynamic> data;
  const AddInventoryItem(this.data);

  @override
  List<Object?> get props => [data];
}

class UpdateInventoryItem extends InventoryEvent {
  final String id;
  final Map<String, dynamic> data;
  const UpdateInventoryItem(this.id, this.data);

  @override
  List<Object?> get props => [id, data];
}

class DeleteInventoryItem extends InventoryEvent {
  final String id;
  const DeleteInventoryItem(this.id);

  @override
  List<Object?> get props => [id];
}
