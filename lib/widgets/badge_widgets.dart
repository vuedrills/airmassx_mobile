import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/badge.dart';
import '../../config/theme.dart';

/// Compact badge icon for display next to avatars
class BadgeIcon extends StatelessWidget {
  final String badgeId;
  final double size;

  const BadgeIcon({
    super.key,
    required this.badgeId,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getColor(),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          _getIcon(),
          size: size * 0.65,
          color: Colors.white,
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (badgeId) {
      case BadgeIds.idVerified:
        return Icons.verified_user;
      case BadgeIds.artisan:
        return Icons.construction;
      case BadgeIds.professional:
        return LucideIcons.badgeCheck;
      case BadgeIds.certified:
        return Icons.military_tech;
      default:
        return Icons.star;
    }
  }

  Color _getColor() {
    switch (badgeId) {
      case BadgeIds.idVerified:
        return const Color(0xFF10B981); // Green
      case BadgeIds.artisan:
        return const Color(0xFFF59E0B); // Amber
      case BadgeIds.professional:
        return const Color(0xFF3B82F6); // Blue
      case BadgeIds.certified:
        return const Color(0xFF8B5CF6); // Purple
      default:
        return AppTheme.neutral400;
    }
  }
}

/// Row of compact badge icons, typically shown next to avatars
class BadgeIconRow extends StatelessWidget {
  final List<UserBadge> badges;
  final double iconSize;
  final double spacing;
  final int maxVisible;

  const BadgeIconRow({
    super.key,
    required this.badges,
    this.iconSize = 22,
    this.spacing = -4, // Less overlap for better visibility
    this.maxVisible = 8, // Show more badges
  });

  @override
  Widget build(BuildContext context) {
    final hasHighTierBadge = badges.any((b) => 
      b.badgeId == BadgeIds.professional || b.badgeId == BadgeIds.artisan);
    
    final filteredBadges = hasHighTierBadge 
      ? badges.where((b) => b.badgeId != BadgeIds.idVerified).toList() 
      : badges;

    final visibleBadges = filteredBadges.take(maxVisible).toList();

    return SizedBox(
      height: iconSize + 4,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (int i = 0; i < visibleBadges.length; i++)
            Transform.translate(
              offset: Offset(i * spacing, 0),
              child: BadgeIcon(
                badgeId: visibleBadges[i].badgeId,
                size: iconSize,
              ),
            ),
        ],
      ),
    );
  }
}

/// Detailed badge card for profile pages
class BadgeCard extends StatelessWidget {
  final UserBadge badge;

  const BadgeCard({
    super.key,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          BadgeIcon(badgeId: badge.badgeId, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  badge.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  badge.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal scrollable badge row for profile pages
class BadgeRow extends StatelessWidget {
  final List<UserBadge> badges;

  const BadgeRow({
    super.key,
    required this.badges,
  });

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) return const SizedBox.shrink();

    final hasHighTierBadge = badges.any((b) => 
      b.badgeId == BadgeIds.professional || b.badgeId == BadgeIds.artisan);
    
    final filteredBadges = hasHighTierBadge 
      ? badges.where((b) => b.badgeId != BadgeIds.idVerified).toList() 
      : badges;

    return SizedBox(
      height: 110,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: filteredBadges.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => BadgeCard(badge: filteredBadges[index]),
      ),
    );
  }
}
