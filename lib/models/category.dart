import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

/// Task category model reflecting backend schema
class Category extends Equatable {
  final String id;
  final String slug;
  final String name;
  final String iconName;
  final String type; // service, equipment
  final String tier; // artisanal, professional, automotive, equipment
  final String verificationLevel;
  final bool isActive;
  final String? parentId;
  final List<Category>? children;

  const Category({
    required this.id,
    required this.slug,
    required this.name,
    required this.iconName,
    this.type = 'service',
    required this.tier,
    required this.verificationLevel,
    this.isActive = true,
    this.parentId,
    this.children,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      slug: json['slug'] ?? '',
      name: json['name'] ?? '',
      iconName: json['icon'] ?? 'help-outline',
      type: json['type'] ?? 'service',
      tier: json['tier'] ?? 'artisanal',
      verificationLevel: json['verification_level'] ?? 'basic',
      isActive: json['is_active'] ?? true,
      parentId: json['parent_id'],
      children: json['children'] != null 
          ? (json['children'] as List).map((i) => Category.fromJson(i)).toList() 
          : null,
    );
  }

  IconData get icon {
    switch (iconName) {
      // Service icons
      case 'hammer-outline': return Ionicons.hammer_outline;
      case 'bulb-outline': return Ionicons.bulb_outline;
      case 'bulb': return Ionicons.bulb_outline;
      case 'color-palette-outline': return Ionicons.color_palette_outline;
      case 'brush-outline': return Ionicons.brush_outline;
      case 'brush': return Ionicons.brush_outline;
      case 'cube-outline': return Ionicons.cube_outline;
      case 'leaf-outline': return Ionicons.leaf_outline;
      case 'leaf': return Ionicons.leaf_outline;
      case 'storefront-outline': return Ionicons.storefront_outline;
      case 'storefront': return Ionicons.storefront_outline;
      case 'sunny-outline': return Ionicons.sunny_outline;
      case 'sunny': return Ionicons.sunny_outline;
      case 'apps-outline': return Ionicons.apps_outline;
      case 'flash-outline': return Ionicons.flash_outline;
      case 'help-buoy-outline': return Ionicons.help_buoy_outline;
      case 'camera-outline': return Ionicons.camera_outline;
      case 'camera': return Ionicons.camera_outline;
      case 'file-tray-stacked-outline': return Ionicons.file_tray_stacked_outline;
      case 'cog-outline': return Ionicons.cog_outline;
      case 'cog': return Ionicons.cog_outline;
      case 'construct-outline': return Ionicons.construct_outline;
      case 'construct': return Ionicons.construct_outline;
      case 'business-outline': return Ionicons.business_outline;
      case 'thermometer-outline': return Ionicons.thermometer_outline;
      case 'water-outline': return Ionicons.water_outline;
      case 'snow-outline': return Ionicons.snow_outline;
      case 'grid-outline': return Ionicons.grid_outline;
      case 'ellipsis-horizontal-outline': return Ionicons.ellipsis_horizontal_outline;
      case 'car-outline': return Ionicons.car_outline;
      case 'map-outline': return Ionicons.map_outline;
      case 'calculator-outline': return Ionicons.calculator_outline;
      case 'earth-outline': return Ionicons.earth_outline;
      case 'sparkles': return Ionicons.sparkles_outline;
      case 'flame': return Ionicons.flame_outline;
      
      // Equipment icons
      case 'speedometer-outline': return Ionicons.speedometer_outline;
      case 'sync-outline': return Ionicons.sync_outline;
      case 'square-outline': return Ionicons.square_outline;
      case 'arrow-up-outline': return Ionicons.arrow_up_outline;
      case 'bus-outline': return Ionicons.bus_outline;
      case 'train-outline': return Ionicons.train_outline;
      case 'git-pull-request-outline': return Ionicons.git_pull_request_outline;
      case 'remove-outline': return Ionicons.remove_outline;
      case 'tablet-landscape-outline': return Ionicons.tablet_landscape_outline;
      case 'car-sport-outline': return Ionicons.car_sport_outline;
      case 'ellipse-outline': return Ionicons.ellipse_outline;
      case 'caret-up-outline': return Ionicons.caret_up_outline;
      case 'cellular-outline': return Ionicons.cellular_outline;
      
      default: return Ionicons.construct_outline;
    }
  }

  @override
  List<Object?> get props => [id, slug, name, type, tier, isActive];
}
