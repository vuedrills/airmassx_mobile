import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/user.dart';
import '../config/theme.dart';
import 'badge_widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/badge.dart';

class UserAvatar extends StatelessWidget {
  final String? profileImage;
  final String name;
  final double radius;
  final bool isVerified;
  final String? status;
  final String? professionalType;
  final List<UserBadge> badges;
  final double badgeSize;
  final bool showBadge;

  const UserAvatar({
    super.key,
    this.profileImage,
    required this.name,
    this.radius = 24,
    this.isVerified = false,
    this.status,
    this.professionalType,
    this.badges = const [],
    this.badgeSize = 20,
    this.showBadge = false,
  });

  /// Factory constructor to create from a User object
  factory UserAvatar.fromUser(User user, {double radius = 24, double badgeSize = 14, bool showBadge = true}) {
    return UserAvatar(
      profileImage: user.profileImage,
      name: user.name,
      radius: radius,
      isVerified: user.isVerified,
      status: user.taskerProfile?.status,
      professionalType: user.taskerProfile?.professionalType,
      badges: user.badges,
      badgeSize: radius >= 45 ? 28 : (radius >= 35 ? 24 : (radius >= 25 ? 20 : 16)),
      showBadge: showBadge,
    );
  }

  /// Factory constructor to create from a UserProfile object
  factory UserAvatar.fromProfile(UserProfile profile, {double radius = 24, double badgeSize = 14, bool showBadge = true}) {
    return UserAvatar(
      profileImage: profile.profileImage,
      name: profile.name,
      radius: radius,
      isVerified: profile.isVerified,
      status: profile.taskerProfile?.status,
      professionalType: profile.taskerProfile?.professionalType,
      badges: profile.badges,
      badgeSize: radius >= 45 ? 28 : (radius >= 35 ? 24 : (radius >= 25 ? 20 : 16)),
      showBadge: showBadge,
    );
  }

  @override
  Widget build(BuildContext context) {
    String? topBadgeId;
    
    if (showBadge) {
      // 1. Check for explicit priority badges in the badges list
      final hasCertified = badges.any((b) => b.badgeId == BadgeIds.certified);
      final hasProfessionalBadge = badges.any((b) => b.badgeId == BadgeIds.professional);
      final hasArtisanBadge = badges.any((b) => b.badgeId == BadgeIds.artisan);

      if (hasCertified) {
        topBadgeId = BadgeIds.certified;
      } else if (hasProfessionalBadge) {
        topBadgeId = BadgeIds.professional;
      } else if (hasArtisanBadge) {
        topBadgeId = BadgeIds.artisan;
      } else if (status == 'approved') {
        // 2. Fallback to professionalType if no explicit badge found
        if (professionalType == 'white_collar' || professionalType == 'professional') {
          topBadgeId = BadgeIds.professional;
        } else if (professionalType == 'artisanal' || professionalType == 'artisan') {
          topBadgeId = BadgeIds.artisan;
        }
      }

      // 3. Last fallback: if user isVerified but has no higher tier badge, show ID verified badge
      if (topBadgeId == null && isVerified) {
        topBadgeId = BadgeIds.idVerified;
      }
    }

    return Stack(
      children: [
        if (profileImage != null && profileImage!.isNotEmpty)
          CachedNetworkImage(
            imageUrl: profileImage!,
            imageBuilder: (context, imageProvider) => CircleAvatar(
              radius: radius,
              backgroundImage: imageProvider,
              backgroundColor: AppTheme.neutral100,
            ),
            placeholder: (context, url) => CircleAvatar(
              radius: radius,
              backgroundColor: AppTheme.neutral100,
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (context, url, error) => _buildFallbackAvatar(),
          )
        else
          _buildFallbackAvatar(),
        if (topBadgeId != null)
          Positioned(
            right: 0,
            bottom: 0,
            child: BadgeIcon(
              badgeId: topBadgeId,
              size: badgeSize,
            ),
          ),
      ],
    );
  }

  Widget _buildFallbackAvatar() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.neutral100,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
          color: AppTheme.navy,
        ),
      ),
    );
  }
}
