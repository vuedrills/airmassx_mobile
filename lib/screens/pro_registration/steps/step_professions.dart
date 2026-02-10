import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../bloc/pro_registration/pro_registration_bloc.dart';
import '../../../bloc/pro_registration/pro_registration_event.dart';
import '../../../bloc/pro_registration/pro_registration_state.dart';
import '../../../config/theme.dart';

import '../../../bloc/category/category_bloc.dart';
import '../../../bloc/category/category_state.dart';

class StepProfessions extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const StepProfessions({super.key, required this.onNext, required this.onBack});

  @override
  State<StepProfessions> createState() => _StepProfessionsState();
}

class _StepProfessionsState extends State<StepProfessions> with TickerProviderStateMixin {
  final Map<String, List<String>> _customProfessionsPerSection = {};

  late AnimationController _animationController;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;
  
  // ... (Same additional categories constants as before)


  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimations = List.generate(6, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(index * 0.1, 0.5 + index * 0.1, curve: Curves.easeOut),
        ),
      );
    });

    _slideAnimations = List.generate(6, (index) {
      return Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(index * 0.1, 0.5 + index * 0.1, curve: Curves.easeOut),
        ),
      );
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }



  void _toggleProfession(String profession, bool selected) {
    final bloc = context.read<ProRegistrationBloc>();
    final updatedIds = List<String>.from(bloc.state.professionIds);
    if (selected) {
      if (!updatedIds.contains(profession)) {
        updatedIds.add(profession);
      }
    } else {
      updatedIds.remove(profession);
    }
    bloc.add(ProRegistrationProfessionsUpdated(updatedIds));
  }

  void _addCustomProfession(String profession, String sectionTitle) {
    if (profession.trim().isEmpty) return;
    final cleanName = profession.trim();
    
    setState(() {
      if (!_customProfessionsPerSection.containsKey(sectionTitle)) {
        _customProfessionsPerSection[sectionTitle] = [];
      }
      if (!_customProfessionsPerSection[sectionTitle]!.contains(cleanName)) {
        _customProfessionsPerSection[sectionTitle]!.add(cleanName);
      }
    });
    
    _toggleProfession(cleanName, true);
  }



  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProRegistrationBloc, ProRegistrationState>(
      builder: (context, state) {
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeTransition(
                      opacity: _fadeAnimations[0],
                      child: SlideTransition(
                        position: _slideAnimations[0],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select all the services you offer. This helps clients find you.',
                              style: TextStyle(
                                color: AppTheme.neutral600,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    const SizedBox(height: 24),

                    BlocBuilder<CategoryBloc, CategoryState>(
                      builder: (context, catState) {
                        if (catState is CategoryLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (catState is CategoryLoaded) {
                          final categoriesGrouped = {
                            'Trades & Artisanal': catState.getArtisanalCategories(),
                            'Professional Services': catState.getProfessionalCategories(),
                          };

                          return Column(
                            children: categoriesGrouped.entries.toList().asMap().entries.map((entry) {
                              final index = entry.key;
                              final categoryEntry = entry.value;
                              return FadeTransition(
                                opacity: _fadeAnimations[(index + 1).clamp(0, 5)],
                                child: SlideTransition(
                                  position: _slideAnimations[(index + 1).clamp(0, 5)],
                                  child: _buildCategorySection(
                                    context,
                                    state,
                                    sectionTitle: categoryEntry.key,
                                    mainProfessions: categoryEntry.value, // List<Category>
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        }
                        return const Center(child: Text('Failed to load categories'));
                      },
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            // Bottom buttons
            FadeTransition(
              opacity: _fadeAnimations[5],
              child: SlideTransition(
                position: _slideAnimations[5],
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onBack,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          child: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navy)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: _buildGradientButton(
                          onPressed: state.isStep3Valid ? widget.onNext : null,
                          text: 'Continue',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    ProRegistrationState state, {
    required String sectionTitle,
    required List<dynamic> mainProfessions, // Assuming List<Category> but keeping dynamic for safety
  }) {
    // Cast to List<Category>
    final categories = mainProfessions.cast<dynamic>().map((e) => e as dynamic).toList();
    
    // Find the "Other" category object
    final otherCategory = categories.firstWhere(
      (c) => c.name == 'Other',
      orElse: () => null,
    );

    // Get selected items from custom additions
    final customForThisSection = _customProfessionsPerSection[sectionTitle] ?? [];
    
    // Get all selected items that belong to "Other" subcategories OR are custom
    // We need to check if selected ID matches any child of otherCategory
    
    List<String> subcategoryNames = [];
    if (otherCategory != null) {
        final bloc = context.read<CategoryBloc>();
        if (bloc.state is CategoryLoaded) {
             final subcats = (bloc.state as CategoryLoaded).getSubCategories(otherCategory.id);
             subcategoryNames = subcats.map((c) => c.name).toList();
        }
    }

    final selectedFromDropdownOrCustom = state.professionIds
        .where((p) => (subcategoryNames.contains(p) || customForThisSection.contains(p)) && p != 'Other')
        .toList();

    // Filter main professions to remove any hardcoded "Other" entries to avoid duplicates
    // Filter main professions to remove "Other" from chips
    final filteredMainProfessions = categories.where((p) => p.name != 'Other').map((c) => c.name as String).toList();
    
    // Check if any "Other" items are selected
    final hasOtherSelections = selectedFromDropdownOrCustom.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Text(
                sectionTitle,
                style: GoogleFonts.oswald(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Divider(color: AppTheme.navy.withValues(alpha: 0.1), thickness: 1.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Main profession chips + "Other" chip - COMPACT spacing
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Main professions
              ...filteredMainProfessions.map((profession) {
                final isSelected = state.professionIds.contains(profession);
                return FilterChip(
                  label: Text(profession),
                  selected: isSelected,
                  onSelected: (selected) => _toggleProfession(profession, selected),
                  selectedColor: AppTheme.primary.withValues(alpha: 0.1),
                  checkmarkColor: AppTheme.primary,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.primary : AppTheme.neutral700,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? AppTheme.primary : Colors.grey[300]!,
                    ),
                  ),
                  backgroundColor: Colors.white,
                );
              }),
              
              // "Other" chip that opens bottom sheet
              ActionChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Other'),
                    if (hasOtherSelections) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${selectedFromDropdownOrCustom.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                onPressed: () {
                    if (otherCategory != null) {
                        _showOtherOptionsSheet(context, sectionTitle, otherCategory);
                    }
                },
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                labelStyle: TextStyle(
                  color: hasOtherSelections ? AppTheme.primary : AppTheme.neutral700,
                  fontWeight: hasOtherSelections ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: hasOtherSelections ? AppTheme.primary : Colors.grey[300]!,
                  ),
                ),
                backgroundColor: hasOtherSelections ? AppTheme.primary.withValues(alpha: 0.1) : Colors.white,
              ),
            ],
          ),
          
          // Show selected "Other" items as small removable chips
          if (selectedFromDropdownOrCustom.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: selectedFromDropdownOrCustom.map((p) => Container(
                padding: const EdgeInsets.only(left: 10, right: 4, top: 2, bottom: 2),
                decoration: BoxDecoration(
                  color: AppTheme.neutral100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.neutral200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(p, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.neutral700)),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => _toggleProfession(p, false),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 10, color: AppTheme.primary),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ... (Keeping _showOtherOptionsSheet and _showCustomProfessionDialog as before)
  void _showOtherOptionsSheet(
    BuildContext context,
    String sectionTitle,
    dynamic parentCategory, // Category object
  ) {
    final bloc = context.read<ProRegistrationBloc>();
    final categoryBloc = context.read<CategoryBloc>();
    
    List<dynamic> subCategories = [];
    if (categoryBloc.state is CategoryLoaded) {
        subCategories = (categoryBloc.state as CategoryLoaded).getSubCategories(parentCategory.id);
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BlocProvider.value(
        value: bloc,
        child: BlocBuilder<ProRegistrationBloc, ProRegistrationState>(
          builder: (context, state) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'More ${sectionTitle.contains('Trade') ? 'Trades' : 'Services'}',
                          style: GoogleFonts.oswald(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.navy),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: [

                          if (subCategories.isEmpty)
                            const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Text('No additional categories found.'),
                            )
                          else
                            Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: subCategories.map((cat) {
                                    final profession = cat.name as String;
                                    final isSelected = state.professionIds.contains(profession);
                                    return FilterChip(
                                    label: Text(profession),
                                    selected: isSelected,
                                    onSelected: (selected) => _toggleProfession(profession, selected),
                                    selectedColor: AppTheme.primary.withValues(alpha: 0.1),
                                    checkmarkColor: AppTheme.primary,
                                    visualDensity: VisualDensity.compact,
                                    labelStyle: TextStyle(
                                        color: isSelected ? AppTheme.primary : AppTheme.neutral700,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        fontSize: 13,
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                        color: isSelected ? AppTheme.primary : Colors.grey[200]!,
                                        ),
                                    ),
                                    backgroundColor: Colors.white,
                                    );
                                }).toList(),
                            ),
                        // Final "Other" section for custom entries
                        const Padding(
                          padding: EdgeInsets.only(top: 24, bottom: 10),
                          child: Text(
                            'NOT LISTED?',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.neutral500,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ActionChip(
                            label: const Text('Other / Custom Service'),
                            onPressed: () => _showCustomProfessionDialog(sheetContext, sectionTitle),
                            avatar: const Icon(Icons.add, size: 16, color: AppTheme.primary),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            labelStyle: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppTheme.primary),
                            ),
                            backgroundColor: AppTheme.primary.withValues(alpha: 0.05),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: _buildGradientButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      text: 'Done',
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showCustomProfessionDialog(BuildContext context, String sectionTitle) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Add Custom ${sectionTitle.contains('Trade') ? 'Trade' : 'Service'}',
          style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.navy),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Enter name (e.g. Interior Designer)',
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            filled: true,
            fillColor: AppTheme.neutral100,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.neutral500)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _addCustomProfession(controller.text, sectionTitle);
                Navigator.pop(dialogContext);
              }
            },
            style: ElevatedButton.styleFrom(
               backgroundColor: AppTheme.navy,
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required String text,
  }) {
    final bool isDisabled = onPressed == null;
    
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: isDisabled ? null : const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryLight],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        color: isDisabled ? Colors.grey[300] : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isDisabled ? null : [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}
