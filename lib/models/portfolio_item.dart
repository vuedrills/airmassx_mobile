import 'package:equatable/equatable.dart';

class PortfolioItem extends Equatable {
  final String id;
  final String imageUrl;
  final String title;
  final String? description;

  const PortfolioItem({
    required this.id,
    required this.imageUrl,
    required this.title,
    this.description,
  });

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    return PortfolioItem(
      id: json['id'] as String,
      imageUrl: json['imageUrl'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'title': title,
      'description': description,
    };
  }

  @override
  List<Object?> get props => [id, imageUrl, title, description];
}
