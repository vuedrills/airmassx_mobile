import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../bloc/create_task/create_task_bloc.dart';
import '../../bloc/create_task/create_task_event.dart';
import '../../bloc/create_task/create_task_state.dart';
import '../../config/theme.dart';
import '../../constants/projects.dart';
import '../../core/service_locator.dart';
import '../../services/api_service.dart';
import '../../widgets/enhanced_location_picker.dart';

class PostProjectScreen extends StatelessWidget {
  const PostProjectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = getIt<CreateTaskBloc>();
        bloc.add(const CreateTaskReset(taskType: 'project'));
        bloc.add(const CreateTaskTypeChanged('project'));
        return bloc;
      },
      child: const _PostProjectContent(),
    );
  }
}

class _PostProjectContent extends StatefulWidget {
  const _PostProjectContent();

  @override
  State<_PostProjectContent> createState() => _PostProjectContentState();
}

class _PostProjectContentState extends State<_PostProjectContent> {
  late final PageController _pageController;
  int _currentStep = 0;
  final int _totalSteps = 5;

  final List<String> _stepTitles = [
    'Project Detail',
    'Documents & Plans',
    'Location',
    'Budget & Timing',
    'Review',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _prevPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CreateTaskBloc, CreateTaskState>(
      listener: (context, state) {
        if (state.status == CreateTaskStatus.success) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Project request posted successfully!'),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        } else if (state.status == CreateTaskStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Failed to post project'),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.navy),
            onPressed: _prevPage,
          ),
          title: Column(
            children: [
              Text(
                _stepTitles[_currentStep],
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.navy,
                ),
              ),
              Text(
                'Step ${_currentStep + 1} of $_totalSteps',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(6),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / _totalSteps,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  minHeight: 6,
                ),
              ),
            ),
          ),
        ),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _StepProjectDetails(onNext: _nextPage),
            _StepDocuments(onNext: _nextPage),
            _StepLocation(onNext: _nextPage),
            _StepBudgetTiming(onNext: _nextPage),
            const _StepReview(),
          ],
        ),
      ),
    );
  }
}

// ============ Step 1: Project Details ============
class _StepProjectDetails extends StatefulWidget {
  final VoidCallback onNext;
  const _StepProjectDetails({required this.onNext});

  @override
  State<_StepProjectDetails> createState() => _StepProjectDetailsState();
}

class _StepProjectDetailsState extends State<_StepProjectDetails> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = context.read<CreateTaskBloc>().state;
    _titleController.text = state.title;
    _descriptionController.text = state.description;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateTaskBloc, CreateTaskState>(
      builder: (context, state) {
        final canContinue = state.title.isNotEmpty && 
                           state.description.length >= 20 && 
                           state.categories.isNotEmpty;

        final isTechnical = state.categories.any((c) => ['Electrical', 'Mechanical', 'Energy', 'Other'].contains(c));

        final sizeOptions = isTechnical 
          ? ['Small Residential', 'Commercial', 'Industrial', 'Utility Scale']
          : ['Small (e.g. Single Room)', 'Medium (e.g. Small House)', 'Large (e.g. Commercial)', 'Mega (e.g. Infrastructure)'];

        final statusOptions = isTechnical
          ? ['New Installation', 'System Upgrade', 'Maintenance / Repair', 'Consultation & Design']
          : ['Raw Land', 'Cleared / Levelled', 'Under Construction', 'Renovation / Extension'];

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(
                      title: 'Project Category',
                      subtitle: 'Select a category below',
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.3,
                      ),
                      itemCount: projectCategories.length,
                      itemBuilder: (context, index) {
                        final cat = projectCategories[index];
                        final isSelected = state.categories.contains(cat.name);
                        return _CategoryCard(
                          category: cat,
                          isSelected: isSelected,
                          onTap: () => context.read<CreateTaskBloc>().add(
                            CreateTaskCategoryToggled(cat.name),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    _SectionTitle(
                      title: 'Project Title',
                      subtitle: 'Give your project a clear, concise name',
                    ),
                    const SizedBox(height: 12),
                    _PremiumTextField(
                      controller: _titleController,
                      hintText: 'e.g. 3-Bedroom House Construction',
                      onChanged: (val) => context.read<CreateTaskBloc>().add(
                        CreateTaskTitleChanged(val),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _SectionTitle(
                      title: 'Detailed Description',
                      subtitle: 'Describe the scope of work and requirements',
                    ),
                    const SizedBox(height: 12),
                    _PremiumTextField(
                      controller: _descriptionController,
                      hintText: 'Provide as much detail as possible...',
                      maxLines: 5,
                      onChanged: (val) => context.read<CreateTaskBloc>().add(
                        CreateTaskDescriptionChanged(val),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            _BottomCTA(
              label: 'Continue',
              onPressed: canContinue ? widget.onNext : null,
              isEnabled: canContinue,
            ),
          ],
        );
      },
    );
  }
}

// ============ Step 2: Documents & Plans ============
class _StepDocuments extends StatelessWidget {
  final VoidCallback onNext;
  const _StepDocuments({required this.onNext});

  Future<void> _pickFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      if (context.mounted) {
        context.read<CreateTaskBloc>().add(
          CreateTaskAttachmentAdded(result.files.single.path!),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateTaskBloc, CreateTaskState>(
      builder: (context, state) {
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(
                      title: 'Bill of Quantities / Requirements (Optional)',
                      subtitle: 'Upload your BOQ or a detailed list of project requirements',
                    ),
                    const SizedBox(height: 16),
                    if (state.boqPath != null)
                      _UploadedFileCard(
                        path: state.boqPath!,
                        onRemove: () => context.read<CreateTaskBloc>().add(const CreateTaskBOQChanged(null)),
                      )
                    else
                      _UploadCard(
                        title: 'Upload BOQ / Requirements',
                        icon: Icons.description_outlined,
                        onTap: () async {
                          final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'doc', 'docx']);
                          if (result != null) {
                            context.read<CreateTaskBloc>().add(CreateTaskBOQChanged(result.files.single.path));
                          }
                        },
                      ),
                    const SizedBox(height: 32),
                    _SectionTitle(
                      title: 'Architectural Plans & Other Files (Optional)',
                      subtitle: 'Upload house plans, site maps, or any other relevant documents',
                    ),
                    const SizedBox(height: 16),
                    _UploadCard(
                      title: 'Upload Plans & Documents',
                      icon: Icons.map_outlined,
                      onTap: () async {
                        final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'png'], allowMultiple: true);
                        if (result != null) {
                          for (var path in result.paths) {
                            if (path != null) {
                              context.read<CreateTaskBloc>().add(CreateTaskPlansAdded(path));
                            }
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    if (state.plansPaths.isNotEmpty) ...[
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.plansPaths.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          return _UploadedFileCard(
                            path: state.plansPaths[index],
                            onRemove: () => context.read<CreateTaskBloc>().add(CreateTaskPlansRemoved(index)),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            _BottomCTA(
              label: 'Continue',
              onPressed: onNext,
              isEnabled: true,
            ),
          ],
        );
      },
    );
  }
}

// ============ Step 3: Location ============
class _StepLocation extends StatelessWidget {
  final VoidCallback onNext;
  const _StepLocation({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateTaskBloc, CreateTaskState>(
      builder: (context, state) {
        final canContinue = state.location.isNotEmpty && state.city != null && state.suburb != null;

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: _SectionTitle(
                        title: 'Project Location',
                        subtitle: '',
                      ),
                    ),
                    EnhancedLocationPicker(
                      initialAddress: state.location,
                      initialLat: state.latitude,
                      initialLng: state.longitude,
                      onLocationSelected: (result) {
                        context.read<CreateTaskBloc>().add(
                          CreateTaskLocationChanged(
                            result.fullAddress,
                            latitude: result.latitude,
                            longitude: result.longitude,
                            city: result.city,
                            suburb: result.suburb,
                            addressDetails: result.addressDetails,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            _BottomCTA(
              label: 'Continue',
              onPressed: canContinue ? onNext : null,
              isEnabled: canContinue,
            ),
          ],
        );
      },
    );
  }
}

// ============ Step 4: Budget & Timing ============
class _StepBudgetTiming extends StatefulWidget {
  final VoidCallback onNext;
  const _StepBudgetTiming({required this.onNext});

  @override
  State<_StepBudgetTiming> createState() => _StepBudgetTimingState();
}

class _StepBudgetTimingState extends State<_StepBudgetTiming> {
  final _budgetController = TextEditingController();
  final _siteVisitAddressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = context.read<CreateTaskBloc>().state;
    if (state.budget > 0) {
      _budgetController.text = state.budget.toStringAsFixed(0);
    }
    if (state.siteVisitAddress != null) {
      _siteVisitAddressController.text = state.siteVisitAddress!;
    }
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _siteVisitAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateTaskBloc, CreateTaskState>(
      builder: (context, state) {
        final canContinue = state.budget > 0;

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(
                      title: 'Estimated Budget',
                      subtitle: 'What is your estimated budget for this project?',
                    ),
                    const SizedBox(height: 12),
                    _PremiumTextField(
                      controller: _budgetController,
                      hintText: '0.00',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.attach_money,
                      onChanged: (val) {
                        final b = double.tryParse(val) ?? 0;
                        context.read<CreateTaskBloc>().add(CreateTaskBudgetChanged(b));
                      },
                    ),
                    const SizedBox(height: 32),
                    _SectionTitle(
                      title: 'Project Timeline',
                      subtitle: 'Specify when the project should start and finish',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now().add(const Duration(days: 7)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 730)),
                              );
                              if (date != null && context.mounted) {
                                context.read<CreateTaskBloc>().add(CreateTaskDateChanged(date));
                              }
                            },
                            child: _DateCard(
                              label: 'Start Date',
                              date: state.date,
                              icon: Icons.calendar_today,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: (state.date ?? DateTime.now()).add(const Duration(days: 30)),
                                firstDate: state.date ?? DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 3650)),
                              );
                              if (date != null && context.mounted) {
                                context.read<CreateTaskBloc>().add(CreateTaskTimelineEndChanged(date));
                              }
                            },
                            child: _DateCard(
                              label: 'End Date',
                              date: state.timelineEnd,
                              icon: Icons.event_available,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ],
                  ),
                ),
              ),
              _BottomCTA(
                label: 'Review Project',
              onPressed: canContinue ? widget.onNext : null,
              isEnabled: canContinue,
            ),
          ],
        );
      },
    );
  }
}

// ============ Step 5: Review ============
class _StepReview extends StatelessWidget {
  const _StepReview();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateTaskBloc, CreateTaskState>(
      builder: (context, state) {
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ReviewItem(label: 'Category', value: state.categories.join(', ')),
                    _ReviewItem(label: 'Title', value: state.title),
                    _ReviewItem(label: 'Description', value: state.description),

                    _ReviewItem(label: 'Location', value: state.location),
                    _ReviewItem(label: 'Budget', value: '\$${state.budget.toStringAsFixed(2)}'),
                    _ReviewItem(
                      label: 'Target Start', 
                      value: state.date != null ? DateFormat('MMMM dd, yyyy').format(state.date!) : 'Flexible',
                    ),
                    _ReviewItem(
                      label: 'Target Completion', 
                      value: state.timelineEnd != null ? DateFormat('MMMM dd, yyyy').format(state.timelineEnd!) : 'Not specified',
                    ),
                    _ReviewItem(
                      label: 'Documents', 
                      value: '${(state.boqPath != null ? 1 : 0) + state.plansPaths.length} files attached',
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: AppTheme.primary),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Only verified and licensed contractors will be able to submit formal quotes for this project.',
                              style: TextStyle(fontSize: 13, color: AppTheme.navy, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _BottomCTA(
              label: 'Post Project Request',
              onPressed: state.status == CreateTaskStatus.submitting 
                ? null 
                : () => context.read<CreateTaskBloc>().add(CreateTaskSubmitted()),
              isEnabled: state.status != CreateTaskStatus.submitting,
              isLoading: state.status == CreateTaskStatus.submitting,
            ),
          ],
        );
      },
    );
  }
}

// ============ Helper Widgets ============

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.navy,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final ProjectCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
          ] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category.icon,
              size: 32,
              color: isSelected ? Colors.white : AppTheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppTheme.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final ValueChanged<String>? onChanged;

  const _PremiumTextField({
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 16, color: AppTheme.navy),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppTheme.primary, size: 20) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}

class _UploadedFileCard extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;

  const _UploadedFileCard({required this.path, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final fileName = path.split('/').last;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: Colors.red),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _UploadCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _UploadCard({required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primary.withOpacity(0.2), style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primary, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'PDF, DOC, JPG or PNG (Max 10MB)',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleCard({
    required this.title,
    required this.description,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.navy),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: isSelected,
              onChanged: (_) => onTap(),
              activeColor: AppTheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final String label;
  final String value;
  const _ReviewItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.navy, height: 1.4),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade200, height: 1),
        ],
      ),
    );
  }
}

class _BottomCTA extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final bool isLoading;

  const _BottomCTA({
    required this.label,
    this.onPressed,
    this.isEnabled = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: isLoading 
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(
              label,
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
            ),
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  final String label;
  final DateTime? date;
  final IconData icon;

  const _DateCard({required this.label, this.date, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                date != null ? DateFormat('MMM dd, yyyy').format(date!) : 'Select',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: date != null ? AppTheme.navy : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeCard extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final IconData icon;

  const _TimeCard({required this.label, this.time, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                time != null ? time!.format(context) : 'Select',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: time != null ? AppTheme.navy : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
