import 'package:flutter/material.dart';

class ProjectCategory {
  final String slug;
  final String name;
  final IconData icon;
  final String description;

  const ProjectCategory({
    required this.slug,
    required this.name,
    required this.icon,
    required this.description,
  });
}

const List<ProjectCategory> projectCategories = [
  ProjectCategory(
    slug: 'project-building-services',
    name: 'Building Services',
    icon: Icons.business,
    description: 'General building and construction services',
  ),
  ProjectCategory(
    slug: 'project-civil-structural',
    name: 'Civil & Structural',
    icon: Icons.foundation,
    description: 'Foundations, structural works, and civil engineering',
  ),
  ProjectCategory(
    slug: 'project-electrical',
    name: 'Electrical',
    icon: Icons.electrical_services,
    description: 'Large scale electrical installations and wiring',
  ),
  ProjectCategory(
    slug: 'project-mechanical',
    name: 'Mechanical',
    icon: Icons.settings,
    description: 'Mechanical systems, plumbing networks, and HVAC',
  ),
  ProjectCategory(
    slug: 'project-energy',
    name: 'Energy',
    icon: Icons.solar_power,
    description: 'Solar farms, power distribution, and energy solutions',
  ),
  ProjectCategory(
    slug: 'project-other',
    name: 'Other',
    icon: Icons.more_horiz,
    description: 'Any other large scale project',
  ),
];
