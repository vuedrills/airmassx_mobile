import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/inventory/inventory_bloc.dart';
import '../../bloc/inventory/inventory_event.dart';
import '../../bloc/inventory/inventory_state.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../bloc/category/category_bloc.dart';
import '../../bloc/category/category_state.dart';
import '../../models/equipment.dart';
import '../../core/ui_utils.dart';
import '../../core/service_locator.dart';
import '../../services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddInventoryItemScreen extends StatefulWidget {
  final Equipment? editingItem;
  const AddInventoryItemScreen({super.key, this.editingItem});

  @override
  State<AddInventoryItemScreen> createState() => _AddInventoryItemScreenState();
}

class _AddInventoryItemScreenState extends State<AddInventoryItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _dailyRateController;
  late TextEditingController _weeklyRateController;
  late String? _category;
  late bool _isAvailable;
  late List<String> _photos;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.editingItem?.title ?? '');
    _locationController = TextEditingController(text: widget.editingItem?.location ?? '');
    _dailyRateController = TextEditingController(text: widget.editingItem?.pricePerDay.toString() ?? '');
    _weeklyRateController = TextEditingController(text: widget.editingItem?.pricePerWeek.toString() ?? '');
    
    _category = widget.editingItem?.category;
    
    _isAvailable = widget.editingItem?.status.toLowerCase() == 'available' || widget.editingItem == null;
    _photos = List<String>.from(widget.editingItem?.photos ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _dailyRateController.dispose();
    _weeklyRateController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final data = {
        'name': _nameController.text,
        'category': _category ?? '',
        'location': _locationController.text,
        'daily_rate': double.parse(_dailyRateController.text),
        'hourly_rate': double.parse(_dailyRateController.text) / 8, // Simplified
        'weekly_rate': double.tryParse(_weeklyRateController.text) ?? 0.0,
        'is_available': _isAvailable,
        'status': _isAvailable ? 'available' : 'unavailable',
        'photos': _photos,
      };

      if (widget.editingItem != null) {
        context.read<InventoryBloc>().add(UpdateInventoryItem(widget.editingItem!.id, data));
      } else {
        context.read<InventoryBloc>().add(AddInventoryItem(data));
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    
    if (image != null) {
      setState(() => _isUploading = true);
      try {
        final url = await getIt<ApiService>().uploadInventoryFile(File(image.path));
        setState(() {
          _photos.add(url);
          _isUploading = false;
        });
      } catch (e) {
        setState(() => _isUploading = false);
        if (mounted) UIUtils.showSnackBar(context, 'Failed to upload image', isError: true);
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.editingItem != null;

    return BlocListener<InventoryBloc, InventoryState>(
      listener: (context, state) {
        if (state is InventoryOperationSuccess) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.white,
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Equipment' : 'Add Equipment'),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: AppTheme.navy,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Basic Information'),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Equipment Name / Model',
                  controller: _nameController,
                  hint: 'e.g. CAT 320 Excavator',
                  validator: (v) => v!.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 20),
                BlocBuilder<CategoryBloc, CategoryState>(
                  builder: (context, catState) {
                    List<String> equipmentCats = ['Other'];
                    if (catState is CategoryLoaded) {
                      equipmentCats = catState.getEquipmentCategories().map((c) => c.name).toList();
                      if (equipmentCats.isEmpty) equipmentCats = ['Other'];
                      
                      // Initialize _category if null or not in list
                      if (_category == null || !equipmentCats.contains(_category)) {
                        _category = equipmentCats.first;
                      }
                    }

                    return _buildDropdownField(
                      label: 'Category',
                      value: _category ?? equipmentCats.first,
                      items: equipmentCats,
                      onChanged: (v) => setState(() => _category = v!),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  label: 'Base Location',
                  controller: _locationController,
                  hint: 'e.g. Harare, Msasa',
                  icon: Icons.location_on_outlined,
                  validator: (v) => v!.isEmpty ? 'Location is required' : null,
                ),
                const SizedBox(height: 32),
                _buildSectionTitle('Pricing & Availability'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'Daily Rate (USD)',
                        controller: _dailyRateController,
                        hint: '0.00',
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        label: 'Weekly Rate (USD)',
                        controller: _weeklyRateController,
                        hint: '0.00',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildSectionTitle('Photos'),
                const SizedBox(height: 16),
                _buildPhotoSection(),
                const SizedBox(height: 20),
                SwitchListTile(
                  title: const Text(
                    'Available for Hire',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.navy),
                  ),
                  subtitle: const Text('Is this item currently ready for hire?'),
                  value: _isAvailable,
                  activeColor: AppTheme.navy,
                  onChanged: (v) => setState(() => _isAvailable = v),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.navy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: BlocBuilder<InventoryBloc, InventoryState>(
                      builder: (context, state) {
                        if (state is InventoryLoading) {
                          return const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          );
                        }
                        return Text(
                          isEditing ? 'Update Equipment' : 'Add to Inventory',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.navy,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    IconData? icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.neutral700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon, size: 20) : null,
            filled: true,
            fillColor: AppTheme.neutral50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.navy, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.neutral700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.neutral50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.navy),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_photos.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _photos.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(_photos[index], fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removePhoto(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        if (_photos.isNotEmpty) const SizedBox(height: 12),
        GestureDetector(
          onTap: _isUploading ? null : _pickImage,
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.neutral50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.neutral200, style: BorderStyle.solid),
            ),
            child: _isUploading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade600),
                      const SizedBox(height: 4),
                      Text('Add Photo', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
