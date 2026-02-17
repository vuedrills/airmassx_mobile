import 'package:equatable/equatable.dart';

class PortfolioItem extends Equatable {
  final String title;
  final String url;
  final String type; // 'image' or 'link'
  final String? description;

  const PortfolioItem({
    required this.title,
    required this.url,
    required this.type,
    this.description,
  });

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    String type = json['type'] ?? '';
    final String url = json['url'] ?? '';

    // If type is missing or invalid, try to derive it from URL
    if (type.isEmpty || (type != 'image' && type != 'link')) {
       final lowerUrl = url.toLowerCase();
       final isImageExtension = lowerUrl.endsWith('.jpg') || 
                                lowerUrl.endsWith('.jpeg') || 
                                lowerUrl.endsWith('.png') || 
                                lowerUrl.endsWith('.gif') || 
                                lowerUrl.endsWith('.webp') ||
                                lowerUrl.endsWith('.heic');
       final isR2 = lowerUrl.contains('r2.dev') || lowerUrl.contains('r2.cloudflarestorage.com');
       
       type = (isImageExtension || isR2) ? 'image' : 'link';
    }

    return PortfolioItem(
      title: json['title'] ?? '',
      url: url,
      type: type,
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'type': type,
      'description': description,
    };
  }

  @override
  List<Object?> get props => [title, url, type, description];
}
