import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/location_picker.dart';
import '../../widgets/posting_location_picker.dart';
import '../../widgets/pro_registration_location_picker.dart'; // For result type
import '../../widgets/gps_first_location_picker.dart';

import '../../bloc/create_task/create_task_bloc.dart';
import '../../bloc/create_task/create_task_event.dart';
import '../../bloc/create_task/create_task_state.dart';
import '../../config/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/service_locator.dart';
import '../../config/constants.dart';
import '../../bloc/category/category_bloc.dart';

import '../../bloc/category/category_state.dart';
import '../../bloc/category/category_event.dart';

import '../../models/task.dart';

class CreateTaskScreen extends StatelessWidget {
  final String? initialTitle;
  final Task? task; // Add task parameter
  
  const CreateTaskScreen({super.key, this.initialTitle, this.task});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CreateTaskBloc>(),
      child: _CreateTaskContent(initialTitle: initialTitle, task: task),
    );
  }
}

class _CreateTaskContent extends StatefulWidget {
  final String? initialTitle;
  final Task? task;
  
  const _CreateTaskContent({this.initialTitle, this.task});

  @override
  State<_CreateTaskContent> createState() => _CreateTaskContentState();
}

class _CreateTaskContentState extends State<_CreateTaskContent> {
  late final PageController _pageController;
  int _currentStep = 0;
  final int _totalSteps = 8;

  @override
  void initState() {
    super.initState();
    _currentStep = 0; // Always start with category selection
    _pageController = PageController(initialPage: _currentStep);
    
    if (widget.task != null) {
      context.read<CreateTaskBloc>().add(CreateTaskInitialize(widget.task));
    } else if (widget.initialTitle != null && widget.initialTitle!.isNotEmpty) {
      // Pre-fill title if provided from another screen
      context.read<CreateTaskBloc>().add(CreateTaskTitleChanged(widget.initialTitle!));
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutQuart,
      );
      setState(() => _currentStep++);
    }
  }

  void _prevPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutQuart,
      );
      setState(() => _currentStep--);
    } else {
      // Go back to previous screen if on first step
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        // Fallback if can't pop (e.g. direct link)
        context.go('/home');
      }
    }
  }

  void _goToStep(int step) {
    _pageController.jumpToPage(step);
    setState(() => _currentStep = step);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CreateTaskBloc, CreateTaskState>(
      listener: (context, state) {
        if (state.status == CreateTaskStatus.success) {
          // Navigate to success step
          setState(() {
            _currentStep = 8;
            _pageController.jumpToPage(8);
          });

        } else if (state.status == CreateTaskStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'Failed to post task')),
          );
        }
      },
      child: Scaffold(
        appBar: _currentStep >= 8
            ? null
            : AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _prevPage,
                ),
                title: Text('Step ${_currentStep + 1} of $_totalSteps'),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(4),
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / _totalSteps,
                    backgroundColor: AppTheme.divider,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                ),
              ),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _StepCategory(onNext: _nextPage),
            _StepTitle(onNext: _nextPage),
            _StepDescription(onNext: _nextPage),
            _StepDecideWhen(onNext: _nextPage),
            _StepLocation(onNext: _nextPage),
            _StepBudget(onNext: _nextPage),
            _StepPhotos(onNext: _nextPage),
            _StepReview(onNavigateToStep: _goToStep),
            const _StepSuccess(),
          ],
        ),
      ),
    );
  }
}

// --- Step 0: Category ---
class _StepCategory extends StatefulWidget {
  final VoidCallback onNext;
  const _StepCategory({required this.onNext});

  @override
  State<_StepCategory> createState() => _StepCategoryState();
}

class _StepCategoryState extends State<_StepCategory> {
  String? _expandedGroup;

  @override
  void initState() {
    super.initState();
    final state = context.read<CreateTaskBloc>().state;
    final catState = context.read<CategoryBloc>().state;
    
    if (state.categories.isNotEmpty && catState is CategoryLoaded) {
      // Auto-expand group based on first selected category
      final firstCategory = state.categories.first;
      if (catState.getArtisanalCategories().any((c) => c.name == firstCategory)) {
        _expandedGroup = 'Artisanal & Trades';
      } else if (catState.getProfessionalCategories().any((c) => c.name == firstCategory)) {
        _expandedGroup = 'Professional Services';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateTaskBloc, CreateTaskState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What do you need done?',
                style: GoogleFonts.oswald(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (state.categories.isNotEmpty)
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          alignment: WrapAlignment.end,
                          children: state.categories.map((cat) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    cat,
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () {
                                      context.read<CreateTaskBloc>().add(CreateTaskCategoryToggled(cat));
                                    },
                                    child: const Icon(Icons.close, size: 14, color: AppTheme.primary),
                                  )
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: BlocBuilder<CategoryBloc, CategoryState>(
                  builder: (context, catState) {
                    if (catState is CategoryLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (catState is CategoryLoaded) {
                      final groups = {
                        'Artisanal & Trades': catState.getArtisanalCategories(),
                        'Professional Services': catState.getProfessionalCategories(),
                      };

                      return ListView(
                        children: [
                          ...groups.keys.map((group) {
                            final isExpanded = _expandedGroup == group;
                            final categories = groups[group]!;
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isExpanded ? AppTheme.primary : AppTheme.divider,
                                  width: isExpanded ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: Icon(
                                      group == 'Artisanal & Trades' ? Icons.handyman : Icons.school,
                                      color: isExpanded ? AppTheme.primary : AppTheme.navy,
                                    ),
                                    title: Text(
                                      group,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isExpanded ? AppTheme.primary : AppTheme.navy,
                                      ),
                                    ),
                                    subtitle: Text(
                                      group == 'Artisanal & Trades' 
                                        ? 'Skilled labor, maintenance & repair'
                                        : 'Engineering, consulting & design',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: Icon(
                                      isExpanded ? Icons.expand_less : Icons.expand_more,
                                      color: AppTheme.navy,
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _expandedGroup = isExpanded ? null : group;
                                      });
                                    },
                                  ),
                                  if (isExpanded)
                                    Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                            ...categories.where((c) => !c.name.toLowerCase().contains('other')).map((cat) {
                                          final isSelected = state.categories.contains(cat.name);
                                          return GestureDetector(
                                            onTap: () {
                                              context.read<CreateTaskBloc>().add(CreateTaskCategoryToggled(cat.name));
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: isSelected ? AppTheme.primary : Colors.white,
                                                border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.divider),
                                                borderRadius: BorderRadius.circular(20),
                                                boxShadow: isSelected ? [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))] : null,
                                              ),
                                              child: Text(
                                                cat.name,
                                                style: TextStyle(
                                                  color: isSelected ? Colors.white : AppTheme.navy,
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                        // "Other" option for this group
                                        if (categories.any((c) => c.name.toLowerCase().contains('other')))
                                            GestureDetector(
                                                onTap: () {
                                                    final otherCat = categories.firstWhere((c) => c.name.toLowerCase().contains('other'));
                                                    _showOtherOptionsSheet(context, group, otherCat);
                                                },
                                                child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                    decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        border: Border.all(color: AppTheme.divider),
                                                        borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: const Text(
                                                        'Other',
                                                        style: TextStyle(
                                                            color: AppTheme.navy,
                                                            fontSize: 13,
                                                        ),
                                                    ),
                                                ),
                                            )
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                          
                          // Other category

                        ],
                      );
                    }
                    if (catState is CategoryError) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Error: ${catState.message}', style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                context.read<CategoryBloc>().add(LoadCategories(forceRefresh: true));
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }
                    return const Center(child: Text('Loading categories...'));
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: state.categories.isNotEmpty ? widget.onNext : null,
                  child: const Text('Next'),
                ),
              ).animate(target: state.categories.isNotEmpty ? 1 : 0)
               .scale(begin: const Offset(1, 1), end: const Offset(1.02, 1.02), duration: 400.ms, curve: Curves.easeOutBack)
               .shimmer(delay: 800.ms, duration: 1500.ms, color: Colors.white24),
            ],
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0, curve: Curves.easeOutQuad),
        );
      },
    );
  }
  void _showOtherOptionsSheet(
    BuildContext context,
    String groupName,
    dynamic parentCategory, // Category object
  ) {
    final categoryBloc = context.read<CategoryBloc>();
    final createTaskBloc = context.read<CreateTaskBloc>();
    
    List<dynamic> subCategories = [];
    if (categoryBloc.state is CategoryLoaded) {
        subCategories = (categoryBloc.state as CategoryLoaded).getSubCategories(parentCategory.id);
        subCategories.sort((a, b) {
          bool aIsOther = a.name.contains('Other');
          bool bIsOther = b.name.contains('Other');
          if (aIsOther && !bIsOther) return 1;
          if (!aIsOther && bIsOther) return -1;
          return a.name.compareTo(b.name);
        });
    }

    // Controller for custom category input
    final customCategoryController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BlocProvider.value(
        value: createTaskBloc,
        child: StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                              'More ${groupName.contains('Trade') ? 'Trades' : 'Services'}',
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
                          child: BlocBuilder<CreateTaskBloc, CreateTaskState>(
                              builder: (context, state) {
                                  return ListView(
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
                                            children: [
                                                ...subCategories.map((cat) {
                                                    final isSelected = state.categories.contains(cat.name);
                                                    return FilterChip(
                                                        label: Text(cat.name),
                                                        selected: isSelected,
                                                        onSelected: (selected) {
                                                            context.read<CreateTaskBloc>().add(CreateTaskCategoryToggled(cat.name));
                                                        },
                                                        selectedColor: AppTheme.primary.withOpacity(0.1),
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
                                                }),
                                            ],
                                        ),
                                    ],
                                    );
                                }
                            ),
                        ),
                        // Add a done button
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              child: const Text('Done'),
                            ),
                          ),
                        ),
                    ],
                ),
              );
            }
          ),
        ),
      );
    }
}

// --- Step 1: Title ---
class _StepTitle extends StatefulWidget {
  final VoidCallback onNext;
  const _StepTitle({required this.onNext});

  @override
  State<_StepTitle> createState() => _StepTitleState();
}

class _StepTitleState extends State<_StepTitle> {
  final _controller = TextEditingController();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<CreateTaskBloc>().state;
    _controller.text = state.title;
    _isValid = state.title.length >= 5;
    _controller.addListener(() {
      setState(() {
        _isValid = _controller.text.length >= 5;
      });
      context.read<CreateTaskBloc>().add(CreateTaskTitleChanged(_controller.text));
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CreateTaskBloc, CreateTaskState>(
      listenWhen: (previous, current) => previous.title != current.title && current.title != _controller.text,
      listener: (context, state) {
        _controller.text = state.title;
        _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
        setState(() {
          _isValid = _controller.text.length >= 5;
        });
      },
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Start with a title',
              style: GoogleFonts.oswald(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppTheme.navy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'In a few words, what do you need done?',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: AppTheme.navy.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'e.g. Clean my 2 bedroom apartment',
                border: UnderlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              style: const TextStyle(fontSize: 18),
              minLines: 1,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            if (_controller.text.isNotEmpty && !_isValid)
              const Text(
                'Please enter at least 5 characters',
                style: TextStyle(color: AppTheme.accentRed),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isValid ? widget.onNext : null,
                child: const Text('Next'),
              ),
            ).animate(target: _isValid ? 1 : 0)
             .scale(begin: const Offset(1, 1), end: const Offset(1.02, 1.02), duration: 400.ms, curve: Curves.easeOutBack)
             .shimmer(delay: 800.ms, duration: 1500.ms, color: Colors.white24),
          ],
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0, curve: Curves.easeOutQuad),
      ),
    );
  }
}

// --- Step 2: Description ---
class _StepDescription extends StatefulWidget {
  final VoidCallback onNext;
  const _StepDescription({required this.onNext});

  @override
  State<_StepDescription> createState() => _StepDescriptionState();
}

class _StepDescriptionState extends State<_StepDescription> {
  final _controller = TextEditingController();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<CreateTaskBloc>().state;
    _controller.text = state.description;
    _isValid = state.description.length >= 10;
    _controller.addListener(() {
      setState(() {
        _isValid = _controller.text.length >= 10;
      });
      context.read<CreateTaskBloc>().add(CreateTaskDescriptionChanged(_controller.text));
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateTaskBloc, CreateTaskState>(
      builder: (context, state) {
        // Check if category is artisanal using CategoryBloc
        final catState = context.read<CategoryBloc>().state;
        bool isArtisanal = false;
        if (catState is CategoryLoaded) {
          isArtisanal = catState.getArtisanalCategories().any((c) => state.categories.contains(c.name));
        }
        
        // Calculate validity
        final isDescValid = _controller.text.length >= 10;
        final isProvisionValid = !isArtisanal || state.provisionType != null;
        final isValid = isDescValid && isProvisionValid;

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (state.title.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Text(
                            state.title,
                            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      Text(
                        'What are the details?',
                        style: GoogleFonts.oswald(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.navy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Be as specific as you can about what needs doing.',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: AppTheme.navy.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _controller,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Describe the task in detail...',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                          contentPadding: EdgeInsets.all(12),
                        ),
                        style: const TextStyle(fontSize: 15),
                        minLines: 4,
                        maxLines: 8,
                      ),
                      const SizedBox(height: 16),
                      if (_controller.text.isNotEmpty && !isDescValid)
                        const Text(
                          'Please enter at least 10 characters',
                          style: TextStyle(color: AppTheme.accentRed),
                        ),

                      // Artisanal Task: Provision Type Selection
                      if (isArtisanal) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Materials & Labor',
                          style: GoogleFonts.oswald(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.navy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Do you need the tasker to provide materials?',
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: AppTheme.navy.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _ProvisionTypeOption(
                          title: 'Labor Only',
                          subtitle: 'I have the materials, just need the work done',
                          value: 'labour_only',
                          groupValue: state.provisionType,
                          onChanged: (val) {
                            context.read<CreateTaskBloc>().add(CreateTaskProvisionTypeChanged(val!));
                          },
                        ),
                        const SizedBox(height: 12),
                        _ProvisionTypeOption(
                          title: 'Supply & Fix',
                          subtitle: 'Tasker provides materials and labor',
                          value: 'supply_and_fix',
                          groupValue: state.provisionType,
                          onChanged: (val) {
                            context.read<CreateTaskBloc>().add(CreateTaskProvisionTypeChanged(val!));
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isValid ? widget.onNext : null,
                  child: const Text('Next'),
                ),
              ).animate(target: isValid ? 1 : 0)
               .scale(begin: const Offset(1, 1), end: const Offset(1.02, 1.02), duration: 400.ms, curve: Curves.easeOutBack)
               .shimmer(delay: 800.ms, duration: 1500.ms, color: Colors.white24),
            ],
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0, curve: Curves.easeOutQuad),
        );
      },
    );
  }

  // Wrapper for _ProvisionTypeCard to keep the UI clean
  Widget _ProvisionTypeOption({
    required String title,
    required String subtitle,
    required String value,
    required String? groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    return _ProvisionTypeCard(
      title: title,
      subtitle: subtitle,
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
    );
  }
}

// --- Step 3: Decide on When ---
class _StepDecideWhen extends StatelessWidget {
  final VoidCallback onNext;
  const _StepDecideWhen({required this.onNext});

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && context.mounted) {
      context.read<CreateTaskBloc>().add(CreateTaskDateChanged(picked));
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return 'On ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatBeforeDate(DateTime date) {
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 
                    'July', 'August', 'September', 'October', 'November', 'December'];
    String daySuffix(int day) {
      if (day >= 11 && day <= 13) return 'th';
      switch (day % 10) {
        case 1: return 'st';
        case 2: return 'nd';
        case 3: return 'rd';
        default: return 'th';
      }
    }
    return '${months[date.month - 1]} ${date.day}${daySuffix(date.day)}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateTaskBloc, CreateTaskState>(
      builder: (context, state) {
        final canContinue = state.dateType != null;
        
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Decide on when',
                        style: GoogleFonts.oswald(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.navy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'When do you need this done?',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: AppTheme.navy.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Date Type Options
                      _DateTypeButton(
                        label: state.dateType == 'on_date' && state.date != null 
                            ? _formatDate(state.date!) 
                            : 'On date',
                        isSelected: state.dateType == 'on_date',
                        onTap: () {
                          context.read<CreateTaskBloc>().add(const CreateTaskDateTypeChanged('on_date'));
                          _selectDate(context);
                        },
                      ),
                      const SizedBox(height: 12),
                      _DateTypeButton(
                        label: state.dateType == 'before_date' && state.date != null 
                            ? 'Before ${_formatBeforeDate(state.date!)}' 
                            : 'Before date',
                        isSelected: state.dateType == 'before_date',
                        onTap: () {
                          context.read<CreateTaskBloc>().add(const CreateTaskDateTypeChanged('before_date'));
                          _selectDate(context);
                        },
                      ),
                      const SizedBox(height: 12),
                      _DateTypeButton(
                        label: 'I\'m flexible',
                        isSelected: state.dateType == 'flexible',
                        onTap: () {
                          context.read<CreateTaskBloc>().add(const CreateTaskDateTypeChanged('flexible'));
                        },
                      ),
                      
                      // Time of day checkbox and options (only show when a date is set for 'on_date')
                      if (state.dateType == 'on_date' && state.date != null) ...[
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Checkbox(
                              value: state.hasSpecificTime,
                              onChanged: (val) {
                                context.read<CreateTaskBloc>().add(CreateTaskSpecificTimeToggled(val ?? false));
                              },
                              activeColor: AppTheme.primary,
                            ),
                            const SizedBox(width: 8),
                            const Flexible(
                              child: Text(
                                'I need a certain time of the day',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        
                        if (state.hasSpecificTime) ...[
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: _TimeOfDayCard(
                                  icon: Icons.wb_twilight,
                                  label: 'Morning',
                                  timeRange: 'Before 10am',
                                  isSelected: state.timeOfDay == 'morning',
                                  onTap: () {
                                    context.read<CreateTaskBloc>().add(const CreateTaskTimeOfDayChanged('morning'));
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _TimeOfDayCard(
                                  icon: Icons.wb_sunny,
                                  label: 'Midday',
                                  timeRange: '10am - 2pm',
                                  isSelected: state.timeOfDay == 'midday',
                                  onTap: () {
                                    context.read<CreateTaskBloc>().add(const CreateTaskTimeOfDayChanged('midday'));
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _TimeOfDayCard(
                                  icon: Icons.wb_sunny_outlined,
                                  label: 'Afternoon',
                                  timeRange: '2pm - 6pm',
                                  isSelected: state.timeOfDay == 'afternoon',
                                  onTap: () {
                                    context.read<CreateTaskBloc>().add(const CreateTaskTimeOfDayChanged('afternoon'));
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _TimeOfDayCard(
                                  icon: Icons.nightlight,
                                  label: 'Evening',
                                  timeRange: 'After 6pm',
                                  isSelected: state.timeOfDay == 'evening',
                                  onTap: () {
                                    context.read<CreateTaskBloc>().add(const CreateTaskTimeOfDayChanged('evening'));
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canContinue ? onNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canContinue ? AppTheme.primary : Colors.grey.shade300,
                  ),
                  child: const Text('Continue'),
                ),
              ).animate(target: canContinue ? 1 : 0)
               .scale(begin: const Offset(1, 1), end: const Offset(1.02, 1.02), duration: 400.ms, curve: Curves.easeOutBack)
               .shimmer(delay: 800.ms, duration: 1500.ms, color: Colors.white24),
            ],
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0, curve: Curves.easeOutQuad),
        );
      },
    );
  }
}

// Helper widget for date type buttons
class _DateTypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DateTypeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.grey.shade200,
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey.shade400,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.navy,
          ),
        ),
      ),
    );
  }
}

// Helper widget for time of day cards
class _TimeOfDayCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String timeRange;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeOfDayCard({
    required this.icon,
    required this.label,
    required this.timeRange,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.1) : Colors.grey.shade100,
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppTheme.primary : Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.navy : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeRange,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppTheme.navy : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Step 4: Location ---
class _StepLocation extends StatelessWidget {
  final VoidCallback onNext;
  const _StepLocation({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateTaskBloc, CreateTaskState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Text(
                'Where is the task?',
                style: GoogleFonts.oswald(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navy,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: PostingLocationPicker(
                  initialAddress: state.location,
                  initialLat: state.latitude,
                  initialLng: state.longitude,
                  onLocationSelected: (result) {
                    context.read<CreateTaskBloc>().add(CreateTaskLocationChanged(
                          result.fullAddress,
                          latitude: result.latitude,
                          longitude: result.longitude,
                          city: result.city,
                          suburb: result.suburb,
                          addressDetails: result.addressDetails,
                        ));
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: (state.location.isNotEmpty && 
                                  state.latitude != null && 
                                  state.longitude != null && 
                                  state.latitude != 0 && 
                                  state.longitude != 0) ? onNext : null,
                      child: const Text('Confirm Location'),
                    ),
                    if (state.location.isNotEmpty && (state.latitude == null || state.latitude == 0))
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Please select a location from the suggestions or tap on the map.',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ).animate(target: state.location.isNotEmpty ? 1 : 0)
               .scale(begin: const Offset(1, 1), end: const Offset(1.02, 1.02), duration: 400.ms, curve: Curves.easeOutBack)
                .shimmer(delay: 800.ms, duration: 1500.ms, color: Colors.white24),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0, curve: Curves.easeOutQuad);
      },
    );
  }
}


// --- Step 5: Budget ---
class _StepBudget extends StatefulWidget {
  final VoidCallback onNext;
  const _StepBudget({required this.onNext});

  @override
  State<_StepBudget> createState() => _StepBudgetState();
}

class _StepBudgetState extends State<_StepBudget> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = context.read<CreateTaskBloc>().state;
    if (state.budget > 0) {
      _controller.text = state.budget.toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What is your budget?',
            style: GoogleFonts.oswald(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppTheme.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Please enter the total amount you are willing to pay.',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: AppTheme.navy.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {}); // Rebuild to update button state
              if (value.isNotEmpty) {
                final val = double.tryParse(value) ?? 0;
                context.read<CreateTaskBloc>().add(CreateTaskBudgetChanged(val));
              }
            },
            decoration: const InputDecoration(
              prefixText: '\$ ',
              hintText: '0',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if ((double.tryParse(_controller.text) ?? 0) >= 5000) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'High-Value Task',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'For tasks over \$5,000, we highly recommend uploading a Bill of Quantities (BOQ) or a comprehensive document in the next step.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _controller.text.isNotEmpty ? widget.onNext : null,
              child: const Text('Next'),
            ),
          ).animate(target: _controller.text.isNotEmpty ? 1 : 0)
           .scale(begin: const Offset(1, 1), end: const Offset(1.02, 1.02), duration: 400.ms, curve: Curves.easeOutBack)
           .shimmer(delay: 800.ms, duration: 1500.ms, color: Colors.white24),
        ],
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0, curve: Curves.easeOutQuad),
    );
  }
}

// --- Step 6: Photos & Attachments ---
class _StepPhotos extends StatelessWidget {
  final VoidCallback onNext;
  const _StepPhotos({required this.onNext});

  Future<void> _pickImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
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
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Add Photo',
              style: GoogleFonts.oswald(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.navy,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.camera_alt_outlined, color: AppTheme.primary),
              ),
              title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(sheetContext);
                try {
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 70,
                    maxWidth: 1920,
                  );
                  if (image != null && context.mounted) {
                    context.read<CreateTaskBloc>().add(CreateTaskPhotoAdded(image.path));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString().contains('camera_access_denied') 
                          ? 'Camera access denied. Please enable it in settings.' 
                          : 'Camera not available on this device.'),
                        backgroundColor: AppTheme.accentRed,
                      ),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.photo_library_outlined, color: AppTheme.primary),
              ),
              title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(sheetContext);
                final List<XFile> images = await picker.pickMultiImage(
                  imageQuality: 70,
                  maxWidth: 1920,
                );
                if (images.isNotEmpty && context.mounted) {
                  for (var image in images) {
                    context.read<CreateTaskBloc>().add(CreateTaskPhotoAdded(image.path));
                  }
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDocument(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );
    
    if (result != null && result.files.single.path != null && context.mounted) {
      final file = File(result.files.single.path!);
      final sizeInMb = file.lengthSync() / (1024 * 1024);
      
      if (sizeInMb > 20) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File size must be less than 20MB')),
        );
        return;
      }
      
      context.read<CreateTaskBloc>().add(CreateTaskAttachmentAdded(result.files.single.path!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CreateTaskBloc>().state;
    
    final catState = context.read<CategoryBloc>().state;
    bool isArtisanal = false;
    if (catState is CategoryLoaded) {
      isArtisanal = catState.getArtisanalCategories().any((c) => state.categories.contains(c.name));
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pictures & Documents (Optional)',
                    style: GoogleFonts.oswald(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isArtisanal 
                        ? 'Photos and documents help Taskers understand your requirements.'
                        : 'Photos and documents (BOQs, plans) help Taskers understand your requirements.',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: AppTheme.navy.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Photos Section
                  Text(
                    'PHOTOS',
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: AppTheme.navy.withOpacity(0.6),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (state.photos.isEmpty)
                    _MediaPickerCard(
                      onTap: () => _pickImage(context),
                      icon: Icons.add_a_photo_outlined,
                      label: 'Add Photos',
                    )
                  else
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: state.photos.length + 1,
                        itemBuilder: (context, index) {
                          if (index == state.photos.length) {
                            return _MediaPickerCard(
                              onTap: () => _pickImage(context),
                              icon: Icons.add,
                              label: 'Add',
                              isSquare: true,
                            );
                          }
                          return _MediaThumbnail(
                            path: state.photos[index],
                            onDelete: () => context.read<CreateTaskBloc>().add(CreateTaskPhotoRemoved(index)),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 32),
                  
                  // Attachments Section
                  Text(
                    isArtisanal ? 'DOCUMENTS' : 'DOCUMENTS (BOQs, PLANS, ETC)',
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: AppTheme.navy.withOpacity(0.6),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (state.attachments.isEmpty)
                    _MediaPickerCard(
                      onTap: () => _pickDocument(context),
                      icon: Icons.note_add_outlined,
                      label: 'Add Documents',
                    )
                  else
                    Column(
                      children: [
                        ...state.attachments.asMap().entries.map((entry) {
                          final index = entry.key;
                          final path = entry.value;
                          final fileName = path.split('/').last;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.divider),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey.shade50,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.description_outlined, color: AppTheme.primary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    fileName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => context.read<CreateTaskBloc>().add(CreateTaskAttachmentRemoved(index)),
                                ),
                              ],
                            ),
                          );
                        }),
                        if (state.attachments.length < 5)
                          _MediaPickerCard(
                            onTap: () => _pickDocument(context),
                            icon: Icons.add,
                            label: 'Add Another Document',
                            isCompact: true,
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text('Next'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaPickerCard extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final bool isSquare;
  final bool isCompact;

  const _MediaPickerCard({
    required this.onTap,
    required this.icon,
    required this.label,
    this.isSquare = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: isCompact ? 60 : (isSquare ? 120 : 150),
        width: isSquare ? 120 : double.infinity,
        margin: isSquare ? const EdgeInsets.only(right: 12) : null,
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.divider, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: isCompact ? 24 : 32, color: AppTheme.textSecondary),
            if (!isCompact) ...[
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
            if (isCompact) ...[
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
            ]
          ],
        ),
      ),
    );
  }
}

class _MediaThumbnail extends StatelessWidget {
  final String path;
  final VoidCallback onDelete;

  const _MediaThumbnail({required this.path, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(path),
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Step 7: Review ---
class _StepReview extends StatelessWidget {
  final Function(int) onNavigateToStep;
  
  const _StepReview({required this.onNavigateToStep});

  String _formatDateDisplay(BuildContext context, CreateTaskState state) {
    if (state.date == null) return 'Flexible';
    
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    String dateStr;
    
    if (state.dateType == 'before_date') {
      dateStr = 'Before ${state.date!.day} ${months[state.date!.month - 1]} ${state.date!.year}';
    } else {
      dateStr = 'On ${state.date!.day} ${months[state.date!.month - 1]} ${state.date!.year}';
    }
    
    if (state.hasSpecificTime && state.timeOfDay != null) {
      String timeOfDayStr = state.timeOfDay!;
      dateStr += ' (${timeOfDayStr[0].toUpperCase()}${timeOfDayStr.substring(1)})';
    }
    
    return dateStr;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateTaskBloc, CreateTaskState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Alright, ready to get offers?',
                style: GoogleFonts.oswald(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Post the task when you\'re ready',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: AppTheme.navy.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _ReviewRow(
                        icon: Icons.grid_view_outlined,
                        text: state.categories.isNotEmpty ? state.categories.join(', ') : 'No category selected',
                        onTap: () => onNavigateToStep(0),
                      ),
                      _ReviewRow(
                        icon: Icons.title_outlined,
                        text: state.title,
                        onTap: () => onNavigateToStep(1),
                      ),
                      _ReviewRow(
                        icon: Icons.description_outlined,
                        text: state.description.length > 60 
                            ? '${state.description.substring(0, 60)}...'
                            : state.description,
                        onTap: () => onNavigateToStep(2),
                      ),
                      _ReviewRow(
                        icon: Icons.calendar_today_outlined,
                        text: _formatDateDisplay(context, state),
                        onTap: () => onNavigateToStep(3),
                      ),
                      _ReviewRow(
                        icon: Icons.location_on_outlined,
                        text: state.location.isNotEmpty ? state.location : 'No location set',
                        onTap: () => onNavigateToStep(4),
                      ),
                      _ReviewRow(
                        icon: Icons.attach_money_outlined,
                        text: '\$${state.budget.toStringAsFixed(0)}',
                        onTap: () => onNavigateToStep(5),
                      ),
                      if (state.photos.isNotEmpty)
                        _ReviewRow(
                          icon: Icons.photo_library_outlined,
                          text: '${state.photos.length} photos attached',
                          onTap: () => onNavigateToStep(6),
                        ),
                      if (state.attachments.isNotEmpty)
                        _ReviewRow(
                          icon: Icons.description_outlined,
                          text: '${state.attachments.length} documents attached',
                          onTap: () => onNavigateToStep(6),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: state.status == CreateTaskStatus.submitting
                      ? null
                      : () {
                          context.read<CreateTaskBloc>().add(CreateTaskSubmitted());
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: state.status == CreateTaskStatus.submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(state.isEditing ? 'Update Task' : 'Post the task', style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Helper widget for review row items
class _ReviewRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _ReviewRow({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppTheme.textSecondary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

// --- Success Step ---
// --- Step 8: Success ---
class _StepSuccess extends StatelessWidget {
  const _StepSuccess();

  @override
  Widget build(BuildContext context) {
    final state = context.read<CreateTaskBloc>().state;
    final isEditing = state.isEditing;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFCE4EC), // Light pink (Pink 50)
            Color(0xFFF8BBD0), // Slightly deeper pink (Pink 100)
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Text(
              isEditing ? 'Task Updated!' : 'Task Posted!',
              style: GoogleFonts.oswald(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isEditing 
                  ? 'Your task has been successfully updated.' 
                  : 'Your task is posted. Here\'s what\'s next:',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: AppTheme.navy.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            if (!isEditing) ...[
              const _NextStepItem(
                number: 1,
                text: 'Taskers will make offers',
              ),
              const SizedBox(height: 24),
              const _NextStepItem(
                number: 2,
                text: 'Accept an offer',
              ),
              const SizedBox(height: 24),
              const _NextStepItem(
                number: 3,
                text: 'Chat and get it done!',
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to my tasks tab
                  context.go('/home?tab=2');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Go to my tasks', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// Helper widget for next steps
class _NextStepItem extends StatelessWidget {
  final int number;
  final String text;

  const _NextStepItem({
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.navy,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProvisionTypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final String? groupValue;
  final ValueChanged<String?> onChanged;

  const _ProvisionTypeCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.05) : Colors.white,
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.divider,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: AppTheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppTheme.primary : AppTheme.navy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
