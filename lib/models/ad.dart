class Ad {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String buttonText;
  final String actionUrl;
  final String type;
  final String placement;
  final int priority;
  final String? backgroundColor;
  final bool isActive;

  Ad({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.buttonText,
    required this.actionUrl,
    required this.type,
    required this.placement,
    required this.priority,
    this.backgroundColor,
    required this.isActive,
  });

  factory Ad.fromJson(Map<String, dynamic> json) {
    return Ad(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String,
      buttonText: json['button_text'] as String? ?? 'View Details',
      actionUrl: json['action_url'] as String,
      type: json['type'] as String? ?? 'external',
      placement: json['placement'] as String? ?? 'home_feed',
      priority: json['priority'] as int? ?? 0,
      backgroundColor: json['background_color'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
