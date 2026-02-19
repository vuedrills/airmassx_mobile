import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/category/category_bloc.dart';
import '../../bloc/category/category_state.dart';
import '../../models/equipment.dart';
import '../../config/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/service_locator.dart';
import '../../services/api_service.dart';
import '../../core/ui_utils.dart';
import '../../models/equipment.dart';

class EquipmentBrowseScreen extends StatefulWidget {
  const EquipmentBrowseScreen({super.key});

  @override
  State<EquipmentBrowseScreen> createState() => _EquipmentBrowseScreenState();
}

class _EquipmentBrowseScreenState extends State<EquipmentBrowseScreen> {
  String selectedCategory = 'All';
  final categories = ['All', 'Power Tools', 'Hand Tools', 'Vehicles', 'Garden', 'Construction', 'Other'];
  
  // Sample equipment data - will be replaced by API calls
  final List<Equipment> _equipmentList = [
    Equipment(
      id: '1',
      ownerId: 'user1',
      ownerName: 'John Smith',
      ownerImage: 'https://randomuser.me/api/portraits/men/1.jpg',
      title: 'Power Drill',
      description: 'Professional grade power drill with accessories',
      category: 'Power Tools',
      pricePerDay: 25.0,
      pricePerWeek: 150.0,
      location: 'Harare',
      photos: ['https://images.unsplash.com/photo-1504148455328-c376907d081c?w=400'],
      status: 'available',
      rating: 4.8,
      reviewCount: 12,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Equipment(
      id: '2',
      ownerId: 'user2',
      ownerName: 'Mary Johnson',
      ownerImage: 'https://randomuser.me/api/portraits/women/2.jpg',
      title: 'Lawn Mower',
      description: 'Petrol lawn mower, perfect for medium-sized gardens',
      category: 'Garden',
      pricePerDay: 40.0,
      pricePerWeek: 220.0,
      location: 'Borrowdale',
      photos: ['https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400'],
      status: 'available',
      rating: 4.5,
      reviewCount: 8,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Equipment(
      id: '3',
      ownerId: 'user3',
      ownerName: 'Peter Ncube',
      ownerImage: 'https://randomuser.me/api/portraits/men/3.jpg',
      title: 'Portable Generator',
      description: '5kVA generator, ideal for construction sites',
      category: 'Construction',
      pricePerDay: 80.0,
      pricePerWeek: 450.0,
      location: 'Avondale',
      photos: ['https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=400'],
      status: 'available',
      rating: 4.9,
      reviewCount: 15,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, catState) {
        final List<String> serverCategories = catState is CategoryLoaded 
            ? ['All', ...catState.getEquipmentCategories().map((c) => c.name)]
            : ['All'];

        final filteredEquipment = selectedCategory == 'All'
            ? _equipmentList
            : _equipmentList.where((e) => e.category == selectedCategory).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Equipment Rental'),
            backgroundColor: AppTheme.navy,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PostEquipmentScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Category filter
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: serverCategories.length,
                  itemBuilder: (context, index) {
                    final category = serverCategories[index];
                    final isSelected = category == selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: ChoiceChip(
                        label: Text(category),
                      selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            selectedCategory = category;
                          });
                        },
                        selectedColor: AppTheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Equipment grid
              Expanded(
                child: filteredEquipment.isEmpty
                    ? const Center(
                        child: Text('No equipment found in this category'),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: filteredEquipment.length,
                        itemBuilder: (context, index) {
                          return _EquipmentCard(equipment: filteredEquipment[index]);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  final Equipment equipment;

  const _EquipmentCard({required this.equipment});

  @override
  Widget build(BuildContext context) {
    return Card(
      // Elevation and shape now inherit from AppTheme.cardTheme
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EquipmentDetailScreen(equipment: equipment),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: equipment.photos.isNotEmpty
                  ? Image.network(
                      equipment.photos.first,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 120,
                          color: Colors.grey[200],
                          child: const Icon(Icons.build, size: 40, color: Colors.grey),
                        );
                      },
                    )
                  : Container(
                      height: 120,
                      color: Colors.grey[200],
                      child: const Icon(Icons.build, size: 40, color: Colors.grey),
                    ),
            ),
            
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      equipment.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                      Text(
                        '\$${equipment.pricePerDay.toStringAsFixed(0)}/day',
                        style: const TextStyle(
                          color: AppTheme.navy,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const Spacer(),
                    Row(
                      children: [
                        equipment.rating > 0
                          ? Row(
                              children: [
                                Icon(Icons.star, size: 14, color: Colors.amber[700]),
                                const SizedBox(width: 2),
                                Text(
                                  equipment.rating.toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'New!',
                                style: TextStyle(
                                  color: Colors.purple.shade700,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        const Spacer(),
                        Icon(
                          equipment.status == 'available'
                              ? Icons.check_circle
                              : Icons.cancel,
                          size: 14,
                          color: equipment.status == 'available'
                              ? Colors.green
                              : Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EquipmentDetailScreen extends StatelessWidget {
  final Equipment equipment;

  const EquipmentDetailScreen({super.key, required this.equipment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(equipment.title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.navy,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image carousel with padding
            Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 250,
                  child: equipment.photos.isNotEmpty
                      ? PageView.builder(
                          itemCount: equipment.photos.length,
                          itemBuilder: (context, index) {
                            return CachedNetworkImage(
                              imageUrl: equipment.photos[index],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                child: const Center(child: CircularProgressIndicator()),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.build, size: 60, color: Colors.grey),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.build, size: 60, color: Colors.grey),
                        ),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  equipment.title,
                                  style: GoogleFonts.oswald(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.navy,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  equipment.status.toUpperCase(),
                                  style: const TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              equipment.rating > 0
                                ? Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 20),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${equipment.rating}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  )
                                : Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'New!',
                                      style: TextStyle(
                                        color: Colors.purple.shade700,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              Text(
                                ' (${equipment.reviewCount} reviews)',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                              if (equipment.location != null) ...[
                                const Spacer(),
                                const Icon(Icons.location_on, color: Colors.grey, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  equipment.location!,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                              ],
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Divider(height: 1),
                          ),

                          // Rental Budget Box
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Daily Rate',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '\$${equipment.pricePerDay.toStringAsFixed(0)}',
                                      style: GoogleFonts.oswald(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.navy,
                                      ),
                                    ),
                                    const Text(' / day', style: TextStyle(color: Colors.grey, fontSize: 16)),
                                  ],
                                ),
                                if (equipment.pricePerWeek > 0) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    '\$${equipment.pricePerWeek.toStringAsFixed(0)} per week',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: equipment.status == 'available'
                                        ? () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Rental request sent!')),
                                            );
                                          }
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      equipment.status == 'available' ? 'Request Rental' : 'Not Available',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Divider(height: 1),
                          ),

                          const Text(
                            'Description',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.navy),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            equipment.description,
                            style: TextStyle(color: Colors.grey.shade700, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Owner Card
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.grey.shade100,
                            backgroundImage: equipment.ownerImage != null
                                ? NetworkImage(equipment.ownerImage!)
                                : null,
                            child: equipment.ownerImage == null
                                ? Text(equipment.ownerName.isNotEmpty ? equipment.ownerName[0] : 'U', style: const TextStyle(color: AppTheme.navy))
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                equipment.ownerName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Text('Verified Owner', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            ],
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.message_outlined, color: AppTheme.navy),
                            onPressed: () {},
                          ),
                        ],
                      ),
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

class PostEquipmentScreen extends StatefulWidget {
  const PostEquipmentScreen({super.key});

  @override
  State<PostEquipmentScreen> createState() => _PostEquipmentScreenState();
}

class _PostEquipmentScreenState extends State<PostEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pricePerDayController = TextEditingController();
  final _pricePerWeekController = TextEditingController();
  final _locationController = TextEditingController();
  String _selectedCategory = 'Power Tools';
  List<String> _photos = [];
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pricePerDayController.dispose();
    _pricePerWeekController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Equipment'),
        backgroundColor: AppTheme.navy,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Equipment Title',
                  hintText: 'e.g., Power Drill, Lawn Mower',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category
              BlocBuilder<CategoryBloc, CategoryState>(
                builder: (context, catState) {
                  final serverCategories = catState is CategoryLoaded 
                      ? catState.getEquipmentCategories().map((c) => c.name).toList()
                      : <String>[];
                  
                  // Ensure current selection is valid or default it
                  if (serverCategories.isNotEmpty && !serverCategories.contains(_selectedCategory)) {
                    _selectedCategory = serverCategories.first;
                  }

                  return DropdownButtonFormField<String>(
                    value: _selectedCategory.isEmpty && serverCategories.isNotEmpty ? serverCategories.first : _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: serverCategories.map((c) => DropdownMenuItem<String>(
                      value: c,
                      child: Text(c),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe your equipment...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Pricing
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _pricePerDayController,
                      decoration: const InputDecoration(
                        labelText: 'Price per Day (\$)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _pricePerWeekController,
                      decoration: const InputDecoration(
                        labelText: 'Price per Week (\$)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'Where is the equipment located?',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 24),

              // Photo upload section
              const Text(
                'Photos',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.navy),
              ),
              const SizedBox(height: 12),
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
                            onTap: () => setState(() => _photos.removeAt(index)),
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
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: Center(
                    child: _isUploading 
                      ? const CircularProgressIndicator()
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 40, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'Add Photos',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() => _isUploading = true);
                      try {
                        final data = {
                          'name': _titleController.text.trim(),
                          'category': _selectedCategory,
                          'description': _descriptionController.text.trim(),
                          'daily_rate': double.parse(_pricePerDayController.text),
                          'weekly_rate': double.tryParse(_pricePerWeekController.text) ?? 0.0,
                          'location': _locationController.text.trim(),
                          'photos': _photos,
                          'is_available': true,
                        };
                        
                        await getIt<ApiService>().createInventoryItem(data);
                        
                        if (mounted) {
                          UIUtils.showSnackBar(context, 'Equipment posted successfully!');
                          Navigator.pop(context);
                        }
                      } catch (e) {
                          if (mounted) UIUtils.showSnackBar(context, 'Failed to post equipment', isError: true);
                      } finally {
                        if (mounted) setState(() => _isUploading = false);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Post Equipment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 70,
      maxWidth: 1920,
    );
    
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
}
