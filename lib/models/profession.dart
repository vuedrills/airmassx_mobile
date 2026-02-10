import 'package:equatable/equatable.dart';

class Profession extends Equatable {
  final String id;
  final String name;
  final String categoryId;

  const Profession({
    required this.id,
    required this.name,
    required this.categoryId,
  });

  factory Profession.fromJson(Map<String, dynamic> json) {
    return Profession(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      categoryId: json['category_id'] ?? json['categoryId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
    };
  }

  @override
  List<Object?> get props => [id, name, categoryId];
}
