import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/user.dart';
import '../../config/theme.dart';
import '../../widgets/badge_widgets.dart';
import '../invoice/request_quote_screen.dart';
import 'reviews_screen.dart';
import '../../services/api_service.dart';
import '../../core/service_locator.dart';
import '../../widgets/user_avatar.dart';
import '../../models/review.dart';
import '../../models/profession.dart';

class PublicProfileScreen extends StatefulWidget {
  final User user;
  final bool showRequestQuoteButton;

  const PublicProfileScreen({
    super.key, 
    required this.user,
    this.showRequestQuoteButton = false,
  });

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  bool _isBioExpanded = false;
  late User _user;
  List<Profession> _allProfessions = [];

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _loadProfessions();
    // Auto-refresh profile data when entering to get latest reviews
    _checkForDemoData();
    _refreshProfile();
  }

  Future<void> _loadProfessions() async {
    try {
      final professions = await getIt<ApiService>().getProfessions();
      if (mounted) {
        setState(() {
          _allProfessions = professions;
        });
      }
    } catch (e) {
      debugPrint('Error loading professions: $e');
    }
  }

  Future<void> _refreshProfile() async {
    try {
      final updatedUser = await getIt<ApiService>().getUserById(_user.id);
      if (updatedUser != null && mounted) {
        setState(() {
          _user = updatedUser;
          _checkForDemoData();
        });
      }
    } catch (e) {
      // Silently fail refresh
    }
  }

  void _checkForDemoData() {
    if ((_user.name == 'Tendai Zvobgo' || _user.name == 'Tendai') && _user.reviews.isEmpty) {
       // Inject fake reviews for demo
       final fakeReviews = [
          Review(
            id: 'demo_1', 
            reviewerId: 'demo_r1', 
            reviewerName: 'Sarah M.', 
            reviewerAvatar: 'https://randomuser.me/api/portraits/women/44.jpg', 
            rating: 5.0, 
            comment: 'Tendai was fantastic! Fixed my plumbing issue in no time. Highly recommended.', 
            date: DateTime.now().subtract(const Duration(days: 2)),
            taskTitle: 'Leaking Pipe Repair'
          ),
          Review(
            id: 'demo_2', 
            reviewerId: 'demo_r2', 
            reviewerName: 'John D.', 
            reviewerAvatar: 'https://randomuser.me/api/portraits/men/32.jpg', 
            rating: 4.5, 
            comment: 'Great work, arrived on time and very professional.', 
            date: DateTime.now().subtract(const Duration(days: 5)),
            taskTitle: 'Electrical Wiring'
          ),
          Review(
            id: 'demo_3', 
            reviewerId: 'demo_r3', 
            reviewerName: 'Alice K.', 
            reviewerAvatar: 'https://randomuser.me/api/portraits/women/68.jpg', 
            rating: 5.0, 
            comment: 'Very polite and did a thorough job cleaning the garden.', 
            date: DateTime.now().subtract(const Duration(days: 12)),
            taskTitle: 'Garden Cleanup'
          ),
       ];
       
       _user = _user.copyWith(
          reviews: fakeReviews,
          rating: 4.9,
          totalReviews: 3,
          tasksCompleted: 15,
          tasksCompletedOnTime: 14,
       );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPosterEmptyState = _user.userType == 'poster' && _user.reviews.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_user.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        color: AppTheme.navy,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              if (isPosterEmptyState)
                _buildPosterEmptyState(context)
              else ...[
                const Divider(height: 1),
                _buildStats(context),
                const Divider(height: 1),
                if (_user.userType == 'tasker' && _user.portfolio.isNotEmpty) ...[
                  _buildPortfolioSection(context),
                  const Divider(height: 1),
                ],
                _buildVerifiedInfo(context),
                const Divider(height: 1),
                _buildAboutSection(context),
                if (_user.reviews.isNotEmpty) ...[
                  const Divider(height: 1),
                  _buildReviewsSection(context),
                ],
              ],
              const SizedBox(height: 100), // Space for bottom action bar
            ],
          ),
        ),
      ),
      bottomNavigationBar: widget.showRequestQuoteButton ? _buildBottomBar(context) : null,
    );
  }



  String? _formatAddress(User user) {
    debugPrint('PublicProfile _formatAddress: address="${user.address}", city="${user.city}", country="${user.country}"');
    if (user.address != null && user.address!.isNotEmpty) return user.address;
    final parts = [user.city, user.country].where((part) => part != null && part.isNotEmpty).toList();
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MEET',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _user.name,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.navy,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_user.badges.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          BadgeIconRow(
                            badges: _user.badges,
                            iconSize: 20,
                            spacing: -4,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Online less than a day ago',
                          style: TextStyle(
                            color: AppTheme.navy,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              UserAvatar.fromUser(
                _user,
                radius: 40,
                showBadge: false,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _formatAddress(_user) ?? 'Location not specified',
                  style: const TextStyle(
                    color: AppTheme.navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPosterEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'No reviews yet',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.navy,
                    ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.star, color: Colors.orange, size: 24),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_user.name.split(' ')[0]} has recently joined Airmass Xpress',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Placeholder for the illustration
                Center(
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: const Icon(Icons.search, size: 40, color: AppTheme.navy),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '${_user.name.split(' ')[0]} currently has no tasks open',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.navy,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'They\'re still exploring the marketplace, looking for creative ideas to check off their to-do list.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppTheme.navy,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    return Container(
      color: const Color(0xFFF6F8FD),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                  _user.rating > 0
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _user.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.navy,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.star, color: Colors.orange, size: 24),
                        ],
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'New!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Overall rating',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.navy,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.info_outline, size: 16, color: Colors.grey.shade400),
                  ],
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReviewsScreen(user: _user),
                      ),
                    );
                  },
                  child: Text(
                    '${_user.totalReviews} reviews',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.navy,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 60, color: Colors.grey.shade300),
          Expanded(
            child: Column(
              children: [
                _user.tasksCompleted > 0
                    ? Text(
                        '${((_user.tasksCompletedOnTime / _user.tasksCompleted) * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.navy,
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'New!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Completion rate',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.navy,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.info_outline, size: 16, color: Colors.grey.shade400),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_user.tasksCompleted} tasks',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.navy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildVerifiedInfo(BuildContext context) {
    final verifiedProfessions = <String>[];
    if (_user.isVerified && _user.taskerProfile != null) {
      for (final id in _user.taskerProfile!.professionIds) {
        final prof = _allProfessions.firstWhere(
          (p) => p.id == id,
          orElse: () => Profession(id: id, name: id.replaceAll('_', ' ').toUpperCase(), categoryId: ''),
        );
        verifiedProfessions.add(prof.name);
      }
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verified information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navy,
                ),
          ),
          const SizedBox(height: 16),
          _buildVerificationItem(
            context,
            Icons.verified_user,
            _user.verificationType ?? 'ID Verified',
            _user.isVerified,
          ),
          if (verifiedProfessions.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...verifiedProfessions.map((name) => _buildVerificationItem(
                  context,
                  Icons.business_center,
                  'Verified $name',
                  true,
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildVerificationItem(BuildContext context, IconData icon, String title, bool isCompleted) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCompleted ? AppTheme.success : AppTheme.neutral400,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.navy,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          if (isCompleted)
            const Icon(Icons.check_circle, color: AppTheme.success, size: 20)
          else
            const Icon(Icons.info_outline, color: AppTheme.neutral400, size: 20),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navy,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            _user.bio ?? 'No bio available.',
            style: const TextStyle(
              height: 1.5,
              fontSize: 15,
              color: AppTheme.navy,
            ),
            maxLines: _isBioExpanded ? null : 4,
            overflow: _isBioExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
          if ((_user.bio?.length ?? 0) > 100)
            GestureDetector(
              onTap: () {
                setState(() {
                  _isBioExpanded = !_isBioExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Text(
                      _isBioExpanded ? 'Read less' : 'Read more',
                      style: const TextStyle(
                        color: AppTheme.navy,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Icon(
                      _isBioExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: AppTheme.navy,
                    ),
                  ],
                ),
              ),
            ),
          if (_user.skills.isNotEmpty) ...[
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _user.skills.map((skill) {
                return Chip(
                  label: Text(skill),
                  backgroundColor: Colors.grey.shade100,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPortfolioSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Text(
            'Portfolio',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navy,
                ),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _user.portfolio.length,
            itemBuilder: (context, index) {
              final item = _user.portfolio[index];
              return Container(
                width: 200,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: GestureDetector(
                  onTap: () => _showFullScreenImage(context, item.imageUrl),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      height: 200,
                      width: 200,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 200,
                        width: 200,
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 200,
                        width: 200,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildReviewsSection(BuildContext context) {
    // Only show reviews with written comments in the preview list
    final writtenReviews = _user.reviews.where((r) => r.comment.trim().isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _user.rating > 0 ? 'Overall rating ${_user.rating.toStringAsFixed(1)}' : 'No ratings yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.navy,
                        ),
                  ),
                  if (_user.rating > 0) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.star, color: Colors.orange, size: 24),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${_user.totalReviews} reviews',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        if (writtenReviews.isNotEmpty)
          SizedBox(
            height: 220,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: writtenReviews.take(5).length,
              itemBuilder: (context, index) {
                final review = writtenReviews[index];
                return Container(
                width: 300,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: NetworkImage(review.reviewerAvatar),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            review.reviewerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.navy,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _getTimeAgo(review.date),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < review.rating ? Icons.star : Icons.star_border,
                          size: 14,
                          color: Colors.orange,
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F8FD),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          review.comment,
                          style: const TextStyle(
                            height: 1.4,
                            fontSize: 14,
                            color: AppTheme.navy,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (review.taskTitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        review.taskTitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReviewsScreen(user: _user),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                'See all ${_user.totalReviews} reviews',
                style: const TextStyle(
                  color: AppTheme.navy,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Want to work with ${_user.name.split(' ')[0]}?',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.navy,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Post a task and request a quote',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RequestQuoteScreen(
                        taskId: 'temp_task_id',
                        taskTitle: 'Task Title',
                        toUserId: _user.id,
                        toUserName: _user.name,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'Request a quote',
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
    );
  }

  String _getTimeAgo(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return 'Just now';
    }
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                placeholder: (context, url) => const CircularProgressIndicator(),
                errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
