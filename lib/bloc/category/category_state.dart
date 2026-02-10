import 'package:equatable/equatable.dart';
import '../../models/category.dart';

abstract class CategoryState extends Equatable {
  const CategoryState();
  
  @override
  List<Object?> get props => [];
}

class CategoryInitial extends CategoryState {}

class CategoryLoading extends CategoryState {}

class CategoryLoaded extends CategoryState {
  final List<Category> categories;
  
  const CategoryLoaded(this.categories);

  // ONLY return top-level categories (parentId == null)
  List<Category> getServiceCategories() => 
    categories.where((c) => c.type == 'service' && c.parentId == null).toList();
  
  List<Category> getEquipmentCategories() => 
    categories.where((c) => c.type == 'equipment' && c.parentId == null).toList();
    
  List<Category> getProfessionalCategories() => 
    categories.where((c) => c.tier.toLowerCase() == 'professional' && c.parentId == null).toList();

  List<Category> getArtisanalCategories() => 
    categories.where((c) => c.tier.toLowerCase() == 'artisanal' && c.parentId == null).toList();

  // Helper to find children of a specific category
  List<Category> getSubCategories(String parentId) =>
      categories.where((c) => c.parentId == parentId).toList();

  @override
  List<Object?> get props => [categories];
}

class CategoryError extends CategoryState {
  final String message;
  const CategoryError(this.message);

  @override
  List<Object?> get props => [message];
}
