/// Represents a badge that can be earned by users
class Badge {
  final String id;
  final String name;
  final String description;
  final String? iconUrl;
  final String color; // Hex color

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    this.iconUrl,
    required this.color,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      iconUrl: json['icon_url'] as String?,
      color: json['color'] as String? ?? '#10B981',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_url': iconUrl,
      'color': color,
    };
  }
}

/// Represents a badge granted to a specific user
class UserBadge {
  final String id;
  final String badgeId;
  final DateTime grantedAt;
  final String? notes;
  final Badge badge;

  const UserBadge({
    required this.id,
    required this.badgeId,
    required this.grantedAt,
    this.notes,
    required this.badge,
  });

  factory UserBadge.fromJson(Map<String, dynamic> json) {
    return UserBadge(
      id: json['id'] as String,
      badgeId: json['badge_id'] as String,
      grantedAt: DateTime.parse(json['granted_at'] as String),
      notes: json['notes'] as String?,
      badge: Badge.fromJson(json['badge'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'badge_id': badgeId,
      'granted_at': grantedAt.toIso8601String(),
      'notes': notes,
      'badge': badge.toJson(),
    };
  }

  // Helper getters
  String get name => badge.name;
  String get description => badge.description;
  String get color => badge.color;
}

// Badge ID constants for easy reference
class BadgeIds {
  static const String idVerified = 'id_verified';
  static const String artisan = 'artisan';
  static const String professional = 'professional';
  static const String certified = 'certified';
}
