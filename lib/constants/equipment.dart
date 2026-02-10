import 'package:flutter/material.dart';

/// Equipment categories for the equipment hire marketplace with icons
class EquipmentType {
  final String name;
  final IconData icon;
  final String description;

  const EquipmentType({
    required this.name,
    required this.icon,
    required this.description,
  });
}

const List<EquipmentType> equipmentTypes = [
  EquipmentType(name: "Excavator", icon: Icons.construction, description: "Digging & earthmoving"),
  EquipmentType(name: "Bulldozer", icon: Icons.agriculture, description: "Grading & pushing"),
  EquipmentType(name: "Loader", icon: Icons.local_shipping, description: "Loading & material handling"),
  EquipmentType(name: "TLB (Backhoe Loader)", icon: Icons.build, description: "Digging & loading"),
  EquipmentType(name: "Tipper (Dump Truck)", icon: Icons.fire_truck, description: "Hauling & dumping"),
  EquipmentType(name: "Mobile Crane", icon: Icons.precision_manufacturing, description: "Heavy lifting"),
  EquipmentType(name: "Tower Crane", icon: Icons.cell_tower, description: "Construction lifting"),
  EquipmentType(name: "Roller Compactor", icon: Icons.circle, description: "Soil & asphalt compaction"),
  EquipmentType(name: "Plate Compactor", icon: Icons.square, description: "Small area compaction"),
  EquipmentType(name: "Water Bowser", icon: Icons.water_drop, description: "Dust suppression & water supply"),
  EquipmentType(name: "Compressor", icon: Icons.air, description: "Pneumatic tools & air supply"),
  EquipmentType(name: "Generator", icon: Icons.bolt, description: "Power supply"),
  EquipmentType(name: "Forklift", icon: Icons.upload, description: "Lifting & stacking"),
  EquipmentType(name: "Motor Grader", icon: Icons.straighten, description: "Road grading & leveling"),
  EquipmentType(name: "Lowbed (all sizes)", icon: Icons.rv_hookup, description: "Heavy equipment transport"),
  EquipmentType(name: "Rigid Truck", icon: Icons.local_shipping, description: "General transport"),
  EquipmentType(name: "Horse and Trailor", icon: Icons.airport_shuttle, description: "Long haul transport"),
  EquipmentType(name: "Concrete Mixer", icon: Icons.blender, description: "Concrete mixing & delivery"),
  EquipmentType(name: "Scaffolds", icon: Icons.view_column, description: "Access & working platforms"),
  EquipmentType(name: "Deck pan", icon: Icons.dashboard, description: "Temporary flooring"),
];

/// Simple list of equipment category names
const List<String> equipmentCategories = [
  "Excavator",
  "Bulldozer",
  "Loader",
  "TLB (Backhoe Loader)",
  "Tipper (Dump Truck)",
  "Mobile Crane",
  "Tower Crane",
  "Roller Compactor",
  "Plate Compactor",
  "Water Bowser",
  "Compressor",
  "Generator",
  "Forklift",
  "Motor Grader",
  "Lowbed (all sizes)",
  "Rigid Truck",
  "Horse and Trailor",
  "Concrete Mixer",
  "Scaffolds",
  "Deck pan",
];

/// Hire duration types
enum HireDurationType {
  hourly,
  daily,
  weekly,
  monthly;

  String get displayName {
    switch (this) {
      case HireDurationType.hourly:
        return 'Hourly';
      case HireDurationType.daily:
        return 'Daily';
      case HireDurationType.weekly:
        return 'Weekly';
      case HireDurationType.monthly:
        return 'Monthly';
    }
  }

  String get durationLabel {
    switch (this) {
      case HireDurationType.hourly:
        return 'Hours';
      case HireDurationType.daily:
        return 'Days';
      case HireDurationType.weekly:
        return 'Weeks';
      case HireDurationType.monthly:
        return 'Months';
    }
  }
}

/// Operator preference options
enum OperatorPreference {
  required,
  preferred,
  notNeeded;

  String get displayName {
    switch (this) {
      case OperatorPreference.required:
        return 'Required';
      case OperatorPreference.preferred:
        return 'Preferred';
      case OperatorPreference.notNeeded:
        return 'Not Required';
    }
  }

  String get description {
    switch (this) {
      case OperatorPreference.required:
        return 'Must include operator';
      case OperatorPreference.preferred:
        return "Owner's choice";
      case OperatorPreference.notNeeded:
        return 'I have my own operator';
    }
  }

  String get value {
    switch (this) {
      case OperatorPreference.required:
        return 'required';
      case OperatorPreference.preferred:
        return 'preferred';
      case OperatorPreference.notNeeded:
        return 'not_needed';
    }
  }
}

/// Equipment capacity model
class EquipmentCapacity {
  final String id;
  final String equipmentType;
  final String capacityCode;
  final String displayName;
  final double? minWeightTons;
  final double? maxWeightTons;
  final int sortOrder;

  const EquipmentCapacity({
    required this.id,
    required this.equipmentType,
    required this.capacityCode,
    required this.displayName,
    this.minWeightTons,
    this.maxWeightTons,
    required this.sortOrder,
  });

  factory EquipmentCapacity.fromJson(Map<String, dynamic> json) {
    return EquipmentCapacity(
      id: json['id'] as String,
      equipmentType: json['equipment_type'] as String,
      capacityCode: json['capacity_code'] as String,
      displayName: json['display_name'] as String,
      minWeightTons: (json['min_weight_tons'] as num?)?.toDouble(),
      maxWeightTons: (json['max_weight_tons'] as num?)?.toDouble(),
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}

/// Get icon for equipment type
IconData getEquipmentIcon(String equipmentType) {
  final type = equipmentTypes.firstWhere(
    (t) => t.name == equipmentType,
    orElse: () => const EquipmentType(name: "", icon: Icons.construction, description: ""),
  );
  return type.icon;
}

/// Get equipment type object
EquipmentType? getEquipmentType(String name) {
  try {
    return equipmentTypes.firstWhere((t) => t.name == name);
  } catch (_) {
    return null;
  }
}

/// Comprehensive capacities for ALL equipment types
const Map<String, List<Map<String, dynamic>>> equipmentCapacityPresets = {
  // ========== EARTHMOVING ==========
  "Excavator": [
    {"id": "exc-mini", "capacityCode": "Mini", "displayName": "Mini (1-3T)", "popular": true},
    {"id": "exc-05t", "capacityCode": "5T", "displayName": "5T Compact"},
    {"id": "exc-08t", "capacityCode": "8T", "displayName": "8T Midi"},
    {"id": "exc-12t", "capacityCode": "12T", "displayName": "12T Standard", "popular": true},
    {"id": "exc-20t", "capacityCode": "20T", "displayName": "20T Large"},
    {"id": "exc-30t", "capacityCode": "30T", "displayName": "30T Heavy"},
    {"id": "exc-40t", "capacityCode": "40T+", "displayName": "40T+ Super Heavy"},
  ],
  "Bulldozer": [
    {"id": "dozer-d3", "capacityCode": "D3/D4", "displayName": "Small (D3/D4)"},
    {"id": "dozer-d5", "capacityCode": "D5", "displayName": "Medium (D5)", "popular": true},
    {"id": "dozer-d6", "capacityCode": "D6/D7", "displayName": "Large (D6/D7)"},
    {"id": "dozer-d8", "capacityCode": "D8+", "displayName": "Super Heavy (D8+)"},
  ],
  "Loader": [
    {"id": "loader-skid", "capacityCode": "Skid", "displayName": "Skid Steer"},
    {"id": "loader-1m3", "capacityCode": "1m³", "displayName": "1m³ Bucket"},
    {"id": "loader-2m3", "capacityCode": "2m³", "displayName": "2m³ Bucket", "popular": true},
    {"id": "loader-3m3", "capacityCode": "3m³", "displayName": "3m³ Bucket"},
    {"id": "loader-5m3", "capacityCode": "5m³+", "displayName": "5m³+ Large"},
  ],
  "Motor Grader": [
    {"id": "grader-120", "capacityCode": "120HP", "displayName": "120HP Small"},
    {"id": "grader-140", "capacityCode": "140HP", "displayName": "140HP Medium", "popular": true},
    {"id": "grader-180", "capacityCode": "180HP", "displayName": "180HP Large"},
    {"id": "grader-220", "capacityCode": "220HP+", "displayName": "220HP+ Extra Large"},
  ],
  "TLB (Backhoe Loader)": [
    {"id": "tlb-standard", "capacityCode": "Std", "displayName": "Standard", "popular": true},
    {"id": "tlb-4in1", "capacityCode": "4-in-1", "displayName": "4-in-1 Bucket"},
    {"id": "tlb-extenda", "capacityCode": "Extendahoe", "displayName": "Extendahoe"},
    {"id": "tlb-4wd", "capacityCode": "4WD", "displayName": "4WD Heavy Duty"},
  ],

  // ========== CRANES ==========
  "Mobile Crane": [
    {"id": "crane-12t", "capacityCode": "12T", "displayName": "12T Compact"},
    {"id": "crane-25t", "capacityCode": "25T", "displayName": "25T City Crane", "popular": true},
    {"id": "crane-50t", "capacityCode": "50T", "displayName": "50T All Terrain"},
    {"id": "crane-80t", "capacityCode": "80T", "displayName": "80T Heavy Lift"},
    {"id": "crane-100t", "capacityCode": "100T+", "displayName": "100T+ Super Heavy"},
  ],
  "Tower Crane": [
    {"id": "tower-4t", "capacityCode": "4T", "displayName": "4T Self-Erecting"},
    {"id": "tower-6t", "capacityCode": "6T", "displayName": "6T Standard", "popular": true},
    {"id": "tower-10t", "capacityCode": "10T", "displayName": "10T Heavy"},
    {"id": "tower-16t", "capacityCode": "16T+", "displayName": "16T+ Luffing Jib"},
  ],

  // ========== TRUCKS ==========
  "Tipper (Dump Truck)": [
    {"id": "tipper-6m3", "capacityCode": "6m³", "displayName": "6m³ Small"},
    {"id": "tipper-10m3", "capacityCode": "10m³", "displayName": "10m³ Standard", "popular": true},
    {"id": "tipper-15m3", "capacityCode": "15m³", "displayName": "15m³ Large"},
    {"id": "tipper-20m3", "capacityCode": "20m³", "displayName": "20m³ Extra Large"},
    {"id": "tipper-artic", "capacityCode": "Artic", "displayName": "Articulated Dump Truck"},
  ],
  "Rigid Truck": [
    {"id": "rigid-4t", "capacityCode": "4T", "displayName": "4T Light"},
    {"id": "rigid-8t", "capacityCode": "8T", "displayName": "8T Medium", "popular": true},
    {"id": "rigid-14t", "capacityCode": "14T", "displayName": "14T Heavy"},
    {"id": "rigid-26t", "capacityCode": "26T+", "displayName": "26T+ Extra Heavy"},
  ],
  "Horse and Trailor": [
    {"id": "horse-34t", "capacityCode": "34T", "displayName": "34T Interlink", "popular": true},
    {"id": "horse-taut", "capacityCode": "Taut", "displayName": "Tautliner"},
    {"id": "horse-flat", "capacityCode": "Flat", "displayName": "Flat Deck"},
    {"id": "horse-side", "capacityCode": "Side", "displayName": "Side Tipper"},
    {"id": "horse-tanker", "capacityCode": "Tanker", "displayName": "Tanker Trailer"},
  ],
  "Lowbed (all sizes)": [
    {"id": "lowbed-10m", "capacityCode": "10m", "displayName": "10m (30T Payload)"},
    {"id": "lowbed-13m", "capacityCode": "13m", "displayName": "13m (45T Payload)", "popular": true},
    {"id": "lowbed-18m", "capacityCode": "18m", "displayName": "18m (60T Payload)"},
    {"id": "lowbed-ext", "capacityCode": "Ext", "displayName": "Extendable (80T+)"},
  ],

  // ========== COMPACTION ==========
  "Roller Compactor": [
    {"id": "roller-walk", "capacityCode": "Walk", "displayName": "Walk-Behind"},
    {"id": "roller-3t", "capacityCode": "3T", "displayName": "3T Smooth Drum"},
    {"id": "roller-8t", "capacityCode": "8T", "displayName": "8T Vibratory", "popular": true},
    {"id": "roller-12t", "capacityCode": "12T", "displayName": "12T Padfoot"},
    {"id": "roller-18t", "capacityCode": "18T+", "displayName": "18T+ Heavy"},
  ],
  "Plate Compactor": [
    {"id": "plate-50kg", "capacityCode": "50kg", "displayName": "50kg Light"},
    {"id": "plate-70kg", "capacityCode": "70kg", "displayName": "70kg Forward"},
    {"id": "plate-120kg", "capacityCode": "120kg", "displayName": "120kg Standard", "popular": true},
    {"id": "plate-200kg", "capacityCode": "200kg", "displayName": "200kg Reversible"},
    {"id": "plate-400kg", "capacityCode": "400kg+", "displayName": "400kg+ Heavy"},
  ],

  // ========== UTILITIES ==========
  "Water Bowser": [
    {"id": "bowser-2500l", "capacityCode": "2,500L", "displayName": "2,500L Trailer"},
    {"id": "bowser-5000l", "capacityCode": "5,000L", "displayName": "5,000L Small"},
    {"id": "bowser-10000l", "capacityCode": "10,000L", "displayName": "10,000L Standard", "popular": true},
    {"id": "bowser-18000l", "capacityCode": "18,000L", "displayName": "18,000L Large"},
    {"id": "bowser-30000l", "capacityCode": "30,000L+", "displayName": "30,000L+ Super"},
  ],
  "Compressor": [
    {"id": "comp-100cfm", "capacityCode": "100cfm", "displayName": "100 cfm Portable"},
    {"id": "comp-175cfm", "capacityCode": "175cfm", "displayName": "175 cfm Towable", "popular": true},
    {"id": "comp-250cfm", "capacityCode": "250cfm", "displayName": "250 cfm Medium"},
    {"id": "comp-400cfm", "capacityCode": "400cfm", "displayName": "400 cfm High Pressure"},
    {"id": "comp-750cfm", "capacityCode": "750cfm+", "displayName": "750 cfm+ Industrial"},
  ],
  "Generator": [
    {"id": "gen-3kva", "capacityCode": "3kVA", "displayName": "3kVA Portable"},
    {"id": "gen-5kva", "capacityCode": "5kVA", "displayName": "5kVA Small"},
    {"id": "gen-20kva", "capacityCode": "20kVA", "displayName": "20kVA Site", "popular": true},
    {"id": "gen-50kva", "capacityCode": "50kVA", "displayName": "50kVA Industrial"},
    {"id": "gen-100kva", "capacityCode": "100kVA", "displayName": "100kVA Heavy"},
    {"id": "gen-250kva", "capacityCode": "250kVA+", "displayName": "250kVA+ Commercial"},
  ],
  "Forklift": [
    {"id": "fork-1.5t", "capacityCode": "1.5T", "displayName": "1.5T Warehouse"},
    {"id": "fork-2t", "capacityCode": "2T", "displayName": "2T Standard"},
    {"id": "fork-3t", "capacityCode": "3T", "displayName": "3T Diesel", "popular": true},
    {"id": "fork-5t", "capacityCode": "5T", "displayName": "5T Heavy"},
    {"id": "fork-10t", "capacityCode": "10T+", "displayName": "10T+ Super Heavy"},
    {"id": "fork-reach", "capacityCode": "Reach", "displayName": "Reach Truck"},
    {"id": "fork-telehandler", "capacityCode": "Tele", "displayName": "Telehandler"},
  ],

  // ========== CONCRETE ==========
  "Concrete Mixer": [
    {"id": "mixer-port", "capacityCode": "Portable", "displayName": "Portable (0.5m³)"},
    {"id": "mixer-3m3", "capacityCode": "3m³", "displayName": "3m³ Small"},
    {"id": "mixer-6m3", "capacityCode": "6m³", "displayName": "6m³ Standard", "popular": true},
    {"id": "mixer-9m3", "capacityCode": "9m³", "displayName": "9m³ Large"},
    {"id": "mixer-pump", "capacityCode": "Pump", "displayName": "Mixer with Pump"},
  ],

  // ========== ACCESS & SCAFFOLDING ==========
  "Scaffolds": [
    {"id": "scaff-mobile", "capacityCode": "Mobile", "displayName": "Mobile Tower (per unit)", "popular": true},
    {"id": "scaff-frame", "capacityCode": "Frame", "displayName": "Frame Scaffold (per m²)"},
    {"id": "scaff-modular", "capacityCode": "Modular", "displayName": "Modular System (per m²)"},
    {"id": "scaff-ring", "capacityCode": "Ringlock", "displayName": "Ringlock (per m²)"},
    {"id": "scaff-hanging", "capacityCode": "Hanging", "displayName": "Hanging Scaffold"},
  ],
  "Deck pan": [
    {"id": "deck-600", "capacityCode": "600mm", "displayName": "600mm Wide (per m²)"},
    {"id": "deck-1200", "capacityCode": "1200mm", "displayName": "1200mm Wide (per m²)", "popular": true},
    {"id": "deck-1800", "capacityCode": "1800mm", "displayName": "1800mm Wide (per m²)"},
    {"id": "deck-heavy", "capacityCode": "HD", "displayName": "Heavy Duty (per m²)"},
  ],
};

/// Check if equipment type has capacity presets
bool hasCapacityPresets(String equipmentType) {
  return equipmentCapacityPresets.containsKey(equipmentType);
}

/// Get capacity presets for equipment type
List<Map<String, dynamic>> getCapacityPresets(String equipmentType) {
  return equipmentCapacityPresets[equipmentType] ?? [];
}

/// Get popular capacity for equipment type (for quick selection)
Map<String, dynamic>? getPopularCapacity(String equipmentType) {
  final presets = getCapacityPresets(equipmentType);
  try {
    return presets.firstWhere((p) => p['popular'] == true);
  } catch (_) {
    return presets.isNotEmpty ? presets.first : null;
  }
}
