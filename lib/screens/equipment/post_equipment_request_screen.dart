import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../bloc/create_task/create_task_bloc.dart';
import '../../bloc/create_task/create_task_event.dart';
import '../../bloc/create_task/create_task_state.dart';
import '../../config/theme.dart';
import '../../constants/equipment.dart';
import '../../core/service_locator.dart';
import '../../services/api_service.dart';
import '../../widgets/enhanced_location_picker.dart';


/// Equipment Request Screen - Award-winning UX for posting equipment hire requests
class PostEquipmentRequestScreen extends StatelessWidget {
  const PostEquipmentRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = getIt<CreateTaskBloc>();
        bloc.add(const CreateTaskReset(taskType: 'equipment'));
        bloc.add(const CreateTaskTypeChanged('equipment'));
        return bloc;
      },
      child: const _PostEquipmentRequestContent(),
    );
  }
}

class _PostEquipmentRequestContent extends StatefulWidget {
  const _PostEquipmentRequestContent();

  @override
  State<_PostEquipmentRequestContent> createState() => _PostEquipmentRequestContentState();
}

class _PostEquipmentRequestContentState extends State<_PostEquipmentRequestContent> {
  late final PageController _pageController;
  int _currentStep = 0;
  final int _totalSteps = 4;

  final List<String> _stepTitles = [
    'Machine Specs',
    'Where is the equipment needed?',
    'Timing & Budget',
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
              content: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Equipment request posted!'),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        } else if (state.status == CreateTaskStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Failed to post request'),
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
            icon: Icon(Icons.arrow_back, color: AppTheme.primary),
            onPressed: _prevPage,
          ),
          leadingWidth: 40,
          titleSpacing: 0,
          title: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _stepTitles[_currentStep],
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.navy,
                ),
              ),
              Text(
                'Step ${_currentStep + 1} of $_totalSteps',
                textAlign: TextAlign.center,
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
            child: ClipRRect(
              borderRadius: BorderRadius.zero,
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / _totalSteps,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                minHeight: 6,
              ),
            ),
          ),
        ),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _StepMachineSpecs(onNext: _nextPage),
            _StepLocation(onNext: _nextPage),
            _StepTimingBudget(onNext: _nextPage),
            const _StepReview(),
          ],
        ),
      ),
    );
  }
}

// ============ Step 1: Machine Specs (Dropdown-based) ============
class _StepMachineSpecs extends StatefulWidget {
  final VoidCallback onNext;
  const _StepMachineSpecs({required this.onNext});

  @override
  State<_StepMachineSpecs> createState() => _StepMachineSpecsState();
}

class _StepMachineSpecsState extends State<_StepMachineSpecs> {
  final _descriptionController = TextEditingController();
  final _customUnitController = TextEditingController();
  List<Map<String, dynamic>> _units = [];
  bool _isLoadingUnits = true;

  @override
  void initState() {
    super.initState();
    final state = context.read<CreateTaskBloc>().state;
    _descriptionController.text = state.description;
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    final api = getIt<ApiService>();
    final data = await api.getUnitsOfMeasurement(status: 'approved');
    if (mounted) {
      setState(() {
        _units = data;
        _isLoadingUnits = false;
        
        final state = context.read<CreateTaskBloc>().state;
        if (state.capacityUnit != null) {
          final unitNames = _units.map((u) => u['name'] as String).toList();
          if (!unitNames.contains(state.capacityUnit) && state.capacityUnit != 'Other...') {
             _customUnitController.text = state.capacityUnit!;
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _customUnitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unitNames = _units.map((u) => u['name'] as String).toList();
    final allDropdownUnits = [...unitNames, 'Other...'];

    return BlocBuilder<CreateTaskBloc, CreateTaskState>(
      builder: (context, state) {
        final canContinue = state.categories.isNotEmpty && state.description.length >= 10;
        final currentCategory = state.categories.isNotEmpty ? state.categories.first : '';
        final capacityPresets = getCapacityPresets(currentCategory);
        final selectedType = getEquipmentType(currentCategory);
        
        final bool isOtherUnit = state.capacityUnit != null && 
                                 state.capacityUnit!.isNotEmpty && 
                                 !unitNames.contains(state.capacityUnit) && 
                                 state.capacityUnit != 'Other...';
        
        final String? currentUnit;
        if (state.capacityUnit == null) {
          currentUnit = null;
        } else if (state.capacityUnit!.isEmpty || isOtherUnit) {
          currentUnit = 'Other...';
        } else {
          currentUnit = state.capacityUnit;
        }
        
        // Validate that the selected capacity ID exists in current presets
        final validCapacityIds = capacityPresets.map((c) => c['id'] as String).toSet();
        final currentCapacityId = state.requiredCapacityId != null && 
            validCapacityIds.contains(state.requiredCapacityId)
            ? state.requiredCapacityId
            : null;

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Equipment Type Dropdown
                    _SectionTitle(title: 'Equipment Type', subtitle: 'What machinery do you need?'),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        value: state.categories.isEmpty ? null : state.categories.first,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            selectedType?.icon ?? Icons.construction,
                            color: AppTheme.primary,
                          ),
                          hintText: 'Select equipment type',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        dropdownColor: Colors.white,
                        isExpanded: true,
                        menuMaxHeight: 400,
                        icon: Icon(Icons.keyboard_arrow_down, color: AppTheme.primary),
                        // Show only text when selected (icon is in prefixIcon)
                        selectedItemBuilder: (context) {
                          return equipmentTypes.map((type) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                type.name,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList();
                        },
                        items: equipmentTypes.map((type) {
                          return DropdownMenuItem(
                            value: type.name,
                            child: Row(
                              children: [
                                Icon(type.icon, size: 20, color: AppTheme.primary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    type.name,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            context.read<CreateTaskBloc>().add(CreateTaskCategoryToggled(value));
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Manual Capacity / Size Selection
                    _SectionTitle(title: 'Size / Capacity', subtitle: 'Enter the specific size you need'),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // capacityValue input
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextFormField(
                              initialValue: state.capacityValue?.toString() ?? '',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: 'Value',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              onChanged: (value) {
                                final val = double.tryParse(value);
                                context.read<CreateTaskBloc>().add(CreateTaskCapacityValueChanged(val));
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // capacityUnit dropdown
                        Expanded(
                          flex: 3,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: DropdownButtonFormField<String>(
                              value: currentUnit,
                              hint: const Text('Unit'),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              icon: Icon(Icons.keyboard_arrow_down, color: AppTheme.primary, size: 20),
                              items: allDropdownUnits.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                              onChanged: (value) {
                                if (value == 'Other...') {
                                  context.read<CreateTaskBloc>().add(const CreateTaskCapacityUnitChanged(''));
                                } else {
                                  context.read<CreateTaskBloc>().add(CreateTaskCapacityUnitChanged(value));
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Custom Unit Input (shown when 'Other...' is selected)
                    if (state.capacityUnit == '' || currentUnit == 'Other...') ...[
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          initialValue: isOtherUnit ? state.capacityUnit : '',
                          decoration: InputDecoration(
                            hintText: 'Enter custom unit (e.g. psi, kg)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          onChanged: (value) {
                            context.read<CreateTaskBloc>().add(CreateTaskCapacityUnitChanged(value));
                          },
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          'New units will be reviewed by admin.',
                          style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Job Description
                    _SectionTitle(
                      title: 'Job Description', 
                      subtitleWidget: Text.rich(
                        TextSpan(
                          text: 'Describe the work, site conditions, and any ',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          children: [
                            TextSpan(
                              text: 'special specs of the equipment',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _descriptionController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'e.g., Need excavator for foundation digging. Site is on a slope, good access from main road...',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        onChanged: (value) {
                          context.read<CreateTaskBloc>().add(CreateTaskDescriptionChanged(value));
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _descriptionController.text.length >= 10 
                            ? Icons.check_circle 
                            : Icons.info_outline,
                          size: 16,
                          color: _descriptionController.text.length >= 10 
                            ? Colors.green 
                            : Colors.grey.shade500,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_descriptionController.text.length}/10 characters minimum',
                          style: TextStyle(
                            fontSize: 12,
                            color: _descriptionController.text.length >= 10 
                              ? Colors.green 
                              : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 80),
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

// ============ Step 2: Location (with GPS, Map, and Autocomplete) ============
class _StepLocation extends StatelessWidget {
  final VoidCallback onNext;
  const _StepLocation({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateTaskBloc, CreateTaskState>(
      builder: (context, state) {
        final hasValidLocation = state.location.isNotEmpty && 
            state.latitude != null && state.longitude != null;

        return Column(
          children: [
            Expanded(
              child: EnhancedLocationPicker(
                initialAddress: state.location.isNotEmpty ? state.location : null,
                initialLat: state.latitude,
                initialLng: state.longitude,
                initialCity: state.city,
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
            _BottomCTA(
              label: 'Continue',
              onPressed: hasValidLocation ? onNext : null,
              isEnabled: hasValidLocation,
            ),
          ],
        );
      },
    );
  }
}

// ============ Step 3: Timing & Budget ============
class _StepTimingBudget extends StatefulWidget {
  final VoidCallback onNext;
  const _StepTimingBudget({required this.onNext});

  @override
  State<_StepTimingBudget> createState() => _StepTimingBudgetState();
}

class _StepTimingBudgetState extends State<_StepTimingBudget> {
  final _budgetController = TextEditingController();
  final _hoursController = TextEditingController();
  final _durationController = TextEditingController();
  final _unitsController = TextEditingController();
  final _numberOfTripsController = TextEditingController();
  final _distancePerTripController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = context.read<CreateTaskBloc>().state;
    if (state.budget > 0) {
      _budgetController.text = state.budget.toStringAsFixed(0);
    }
    if (state.equipmentUnits != null) {
      _unitsController.text = state.equipmentUnits.toString();
    } else {
      _unitsController.text = '1';
    }
    if (state.numberOfTrips != null) {
      _numberOfTripsController.text = state.numberOfTrips.toString();
    }
    if (state.distancePerTrip != null) {
      _distancePerTripController.text = state.distancePerTrip.toString();
    }
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Number of Units (how many machines needed)
                    _SectionTitle(title: 'Number of Units', subtitle: 'How many machines do you need?'),
                    const SizedBox(height: 12),
                    _PremiumTextField(
                      controller: _unitsController,
                      hintText: 'e.g., 1',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.construction,
                      onChanged: (value) {
                        final num = int.tryParse(value);
                        context.read<CreateTaskBloc>().add(CreateTaskEquipmentUnitsChanged(num ?? 1));
                      },
                    ),
                    const SizedBox(height: 24),

                    // Costing Basis
                    _SectionTitle(title: 'Charge Basis', subtitle: 'How will the price be calculated?'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _DurationCard(
                          icon: Icons.schedule,
                          label: 'Time',
                          isSelected: state.costingBasis == 'time',
                          onTap: () => context.read<CreateTaskBloc>().add(
                            const CreateTaskCostingBasisChanged('time'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _DurationCard(
                          icon: Icons.route,
                          label: 'Distance',
                          isSelected: state.costingBasis == 'distance',
                          onTap: () => context.read<CreateTaskBloc>().add(
                            const CreateTaskCostingBasisChanged('distance'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _DurationCard(
                          icon: Icons.local_shipping,
                          label: 'Per Load',
                          isSelected: state.costingBasis == 'per_load',
                          onTap: () => context.read<CreateTaskBloc>().add(
                            const CreateTaskCostingBasisChanged('per_load'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Specific Parameter Selection
                    if (state.costingBasis == 'time') ...[
                      _SectionTitle(title: 'Hire Duration Type', subtitle: 'How will you be charged?'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _DurationCard(
                            icon: Icons.schedule,
                            label: 'Hourly',
                            isSelected: state.hireDurationType == 'hourly',
                            onTap: () => context.read<CreateTaskBloc>().add(
                              const CreateTaskHireDurationTypeChanged('hourly'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _DurationCard(
                            icon: Icons.today,
                            label: 'Daily',
                            isSelected: state.hireDurationType == 'daily',
                            onTap: () => context.read<CreateTaskBloc>().add(
                              const CreateTaskHireDurationTypeChanged('daily'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _DurationCard(
                            icon: Icons.date_range,
                            label: 'Weekly',
                            isSelected: state.hireDurationType == 'weekly',
                            onTap: () => context.read<CreateTaskBloc>().add(
                              const CreateTaskHireDurationTypeChanged('weekly'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _DurationCard(
                            icon: Icons.calendar_month,
                            label: 'Monthly',
                            isSelected: state.hireDurationType == 'monthly',
                            onTap: () => context.read<CreateTaskBloc>().add(
                              const CreateTaskHireDurationTypeChanged('monthly'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Time duration input
                      if (state.hireDurationType != null) ...[
                        _SectionTitle(
                          title: _getDurationInputTitle(state.hireDurationType!),
                          subtitle: _getDurationInputSubtitle(state.hireDurationType!),
                        ),
                        const SizedBox(height: 12),
                        _PremiumTextField(
                          controller: state.hireDurationType == 'hourly' ? _hoursController : _durationController,
                          hintText: _getDurationHint(state.hireDurationType!),
                          keyboardType: TextInputType.number,
                          prefixIcon: _getDurationIcon(state.hireDurationType!),
                          onChanged: (value) {
                            final num = double.tryParse(value);
                            if (state.hireDurationType == 'hourly') {
                              context.read<CreateTaskBloc>().add(CreateTaskEstimatedHoursChanged(num));
                            } else {
                              context.read<CreateTaskBloc>().add(CreateTaskEstimatedDurationChanged(num));
                            }
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    ] else if (state.costingBasis == 'distance') ...[
                      // Distance-based costing
                      _SectionTitle(title: 'Distance Details', subtitle: 'Specify distance and trips'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Distance per trip (km)', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                const SizedBox(height: 6),
                                _PremiumTextField(
                                  controller: _distancePerTripController,
                                  hintText: 'e.g., 20',
                                  keyboardType: TextInputType.number,
                                  prefixIcon: Icons.straighten,
                                  onChanged: (value) {
                                    final num = double.tryParse(value);
                                    context.read<CreateTaskBloc>().add(CreateTaskDistancePerTripChanged(num));
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Number of trips', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                const SizedBox(height: 6),
                                _PremiumTextField(
                                  controller: _numberOfTripsController,
                                  hintText: 'e.g., 5',
                                  keyboardType: TextInputType.number,
                                  prefixIcon: Icons.repeat,
                                  onChanged: (value) {
                                    final num = int.tryParse(value);
                                    context.read<CreateTaskBloc>().add(CreateTaskNumberOfTripsChanged(num));
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (state.distancePerTrip != null && state.numberOfTrips != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calculate, size: 18, color: AppTheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Total: ${state.distancePerTrip! * state.numberOfTrips!} km',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ] else if (state.costingBasis == 'per_load') ...[
                      // Per-load costing
                      _SectionTitle(title: 'Load Details', subtitle: 'How many loads and approximate distance?'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Number of loads', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                const SizedBox(height: 6),
                                _PremiumTextField(
                                  controller: _numberOfTripsController,
                                  hintText: 'e.g., 5',
                                  keyboardType: TextInputType.number,
                                  prefixIcon: Icons.local_shipping,
                                  onChanged: (value) {
                                    final num = double.tryParse(value);
                                    context.read<CreateTaskBloc>().add(CreateTaskNumberOfTripsChanged(num?.toInt()));
                                    context.read<CreateTaskBloc>().add(CreateTaskEstimatedDurationChanged(num));
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Approx. distance (km)', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                const SizedBox(height: 6),
                                _PremiumTextField(
                                  controller: _distancePerTripController,
                                  hintText: 'e.g., 20',
                                  keyboardType: TextInputType.number,
                                  prefixIcon: Icons.straighten,
                                  onChanged: (value) {
                                    final num = double.tryParse(value);
                                    context.read<CreateTaskBloc>().add(CreateTaskDistancePerTripChanged(num));
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],


                    /*
                    // Operator Preference
                    _SectionTitle(title: 'Operator', subtitle: 'Do you need an operator with the equipment?'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _OperatorCard(
                          icon: Icons.person,
                          label: 'Required',
                          description: 'Must include',
                          isSelected: state.operatorPreference == 'required',
                          onTap: () => context.read<CreateTaskBloc>().add(
                            const CreateTaskOperatorPreferenceChanged('required'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _OperatorCard(
                          icon: Icons.thumb_up_outlined,
                          label: 'Preferred',
                          description: 'If available',
                          isSelected: state.operatorPreference == 'preferred',
                          onTap: () => context.read<CreateTaskBloc>().add(
                            const CreateTaskOperatorPreferenceChanged('preferred'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _OperatorCard(
                          icon: Icons.build_outlined,
                          label: 'Dry Rate',
                          description: 'I have operator',
                          isSelected: state.operatorPreference == 'not_needed',
                          onTap: () => context.read<CreateTaskBloc>().add(
                            const CreateTaskOperatorPreferenceChanged('not_needed'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    */

                    // When do you need it
                    _SectionTitle(title: 'Start Date', subtitle: 'When should work begin?'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _DateCard(
                            icon: Icons.update,
                            label: 'Flexible',
                            description: 'ASAP',
                            isSelected: state.dateType == 'flexible',
                            onTap: () => context.read<CreateTaskBloc>().add(
                              const CreateTaskDateTypeChanged('flexible'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateCard(
                            icon: Icons.event,
                            label: state.date != null 
                              ? '${state.date!.day}/${state.date!.month}'
                              : 'Pick Date',
                            description: 'Specific',
                            isSelected: state.dateType == 'on_date',
                            onTap: () async {
                              context.read<CreateTaskBloc>().add(
                                const CreateTaskDateTypeChanged('on_date'),
                              );
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null && context.mounted) {
                                context.read<CreateTaskBloc>().add(CreateTaskDateChanged(date));
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Fuel Option (Move above budget)
                    _SectionTitle(title: 'Hire Type', subtitle: 'Is fuel included in your request?'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _OperatorCard(
                          icon: Icons.water_drop_outlined,
                          label: 'Dry Rate',
                          description: 'Equipment only',
                          isSelected: !state.fuelIncluded,
                          onTap: () => context.read<CreateTaskBloc>().add(
                            const CreateTaskFuelIncludedChanged(false),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _OperatorCard(
                          icon: Icons.local_gas_station,
                          label: 'Wet Rate',
                          description: 'Fuel included',
                          isSelected: state.fuelIncluded,
                          onTap: () => context.read<CreateTaskBloc>().add(
                            const CreateTaskFuelIncludedChanged(true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Budget
                    _SectionTitle(title: 'Your Budget', subtitle: 'Total amount you\'re willing to pay'),
                    const SizedBox(height: 12),
                    _PremiumTextField(
                      controller: _budgetController,
                      hintText: '0.00',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.attach_money,
                      onChanged: (value) {
                        final budget = double.tryParse(value) ?? 0;
                        context.read<CreateTaskBloc>().add(CreateTaskBudgetChanged(budget));
                      },
                    ),
                    const SizedBox(height: 16),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            _BottomCTA(
              label: 'Review Request',
              onPressed: canContinue ? widget.onNext : null,
              isEnabled: canContinue,
            ),
          ],
        );
      },
    );
  }
}

class _DurationCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DurationCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primary : Colors.grey.shade200,
            ),
            boxShadow: isSelected ? [
              BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 8),
            ] : null,
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: isSelected ? Colors.white : AppTheme.primary),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppTheme.navy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OperatorCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _OperatorCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primary : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 26, color: isSelected ? AppTheme.primary : Colors.grey.shade600),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppTheme.navy : Colors.grey.shade800,
                ),
              ),
              Text(
                description,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _DateCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: isSelected ? AppTheme.primary : Colors.grey.shade600),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.navy : Colors.grey.shade800,
              ),
            ),
            Text(
              description,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ Step 4: Review ============
class _StepReview extends StatelessWidget {
  const _StepReview();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateTaskBloc, CreateTaskState>(
      builder: (context, state) {
        final isSubmitting = state.status == CreateTaskStatus.submitting;
        final selectedType = getEquipmentType(state.categories.isNotEmpty ? state.categories.first : '');

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Equipment Summary Title
                    Text(
                      state.categories.isNotEmpty ? state.categories.first : 'Equipment',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${state.budget.toStringAsFixed(0)} Budget',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Details
                    _ReviewSection(title: 'Details', children: [
                      _ReviewItem(icon: Icons.location_on, label: 'Location', value: state.location),
                      if (state.equipmentUnits != null)
                        _ReviewItem(
                          icon: Icons.construction, 
                          label: 'Number of Units', 
                          value: '${state.equipmentUnits} ${state.equipmentUnits == 1 ? "Machine" : "Machines"}',
                        ),
                      if (state.capacityValue != null && state.capacityUnit != null)
                        _ReviewItem(
                          icon: Icons.straighten, 
                          label: 'Capacity', 
                          value: '${state.capacityValue} ${state.capacityUnit}',
                        ),
                      if (state.hireDurationType != null)
                        _ReviewItem(
                          icon: _getDurationIcon(state.hireDurationType!),
                          label: 'Charge Basis',
                          value: _getDurationReviewValue(state),
                        ),
                      _ReviewItem(
                        icon: Icons.local_gas_station,
                        label: 'Hire Type',
                        value: state.fuelIncluded ? 'Wet Rate' : 'Dry Rate',
                      ),
                      /*
                      if (state.operatorPreference != null)
                        _ReviewItem(
                          icon: Icons.person,
                          label: 'Operator',
                          value: state.operatorPreference == 'required' ? 'Required'
                            : state.operatorPreference == 'preferred' ? 'Preferred'
                            : 'Dry Rate',
                        ),
                      */
                      _ReviewItem(
                        icon: Icons.calendar_today,
                        label: 'When',
                        value: state.dateType == 'flexible' ? 'Flexible / ASAP'
                          : state.date != null ? '${state.date!.day}/${state.date!.month}/${state.date!.year}'
                          : 'Not specified',
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // Description
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.description, color: Colors.grey.shade600, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Job Description',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            state.description,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            _BottomCTA(
              label: isSubmitting ? 'Posting...' : 'Post Request',
              onPressed: isSubmitting ? null : () {
                context.read<CreateTaskBloc>().add(CreateTaskSubmitted());
              },
              isEnabled: !isSubmitting,
              isLoading: isSubmitting,
            ),
          ],
        );
      },
    );
  }
}

class _ReviewSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ReviewSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppTheme.navy,
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          ...children,
        ],
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ReviewItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value, 
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}


// ============ Shared Widgets ============
class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;

  const _SectionTitle({required this.title, this.subtitle, this.subtitleWidget});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.navy,
          ),
        ),
        const SizedBox(height: 4),
        if (subtitleWidget != null)
          subtitleWidget!
        else if (subtitle != null)
          Text(
            subtitle!,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
      ],
    );
  }
}

class _PremiumTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final IconData prefixIcon;
  final ValueChanged<String> onChanged;

  const _PremiumTextField({
    required this.controller,
    required this.hintText,
    required this.keyboardType,
    required this.prefixIcon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(prefixIcon, color: AppTheme.primary),
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: onChanged,
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
    required this.onPressed,
    this.isEnabled = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isEnabled ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isEnabled ? AppTheme.primary : Colors.grey.shade300,
              foregroundColor: Colors.white,
              elevation: isEnabled ? 4 : 0,
              shadowColor: AppTheme.primary.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          ),
        ),
      ),
    );
  }
}

// ============ Helper Functions ============
String _getDurationInputTitle(String type) {
  switch (type) {
    case 'hourly': return 'Estimated Hours';
    case 'daily': return 'Estimated Days';
    case 'weekly': return 'Estimated Weeks';
    case 'monthly': return 'Estimated Months';
    case 'kilometers': return 'Total Distance';
    case 'loads': return 'Number of Loads';
    case 'units': return 'Number of Units';
    default: return 'Estimated Duration';
  }
}

String _getDurationInputSubtitle(String type) {
  switch (type) {
    case 'kilometers': return 'How many kilometers is the transport?';
    case 'loads': return 'How many loads need to be moved?';
    case 'units': return 'How many units are involved?';
    default: return 'How long do you need the equipment?';
  }
}

String _getDurationHint(String type) {
  switch (type) {
    case 'hourly': return 'e.g., 8';
    case 'kilometers': return 'e.g., 50';
    case 'loads': return 'e.g., 10';
    case 'units': return 'e.g., 5';
    default: return 'e.g., 3';
  }
}

IconData _getDurationIcon(String type) {
  switch (type) {
    case 'kilometers': return Icons.straighten;
    case 'loads': return Icons.local_shipping;
    case 'units': return Icons.inventory;
    default: return Icons.access_time;
  }
}

String _getDurationReviewValue(CreateTaskState state) {
  final type = state.hireDurationType;
  if (type == null) return 'N/A';
  
  final count = type == 'hourly' ? state.estimatedHours : state.estimatedDuration;
  if (count == null) return type;

  switch (type) {
    case 'hourly': return '$count Hours';
    case 'daily': return '$count Days';
    case 'weekly': return '$count Weeks';
    case 'monthly': return '$count Months';
    case 'kilometers': return '$count Kilometers';
    case 'loads': return '$count Loads';
    case 'units': return '$count Units';
    default: return '$count $type';
  }
}
