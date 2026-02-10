import 'package:equatable/equatable.dart';

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadCategories extends CategoryEvent {
  final bool forceRefresh;
  const LoadCategories({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}
