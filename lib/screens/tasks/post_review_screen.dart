import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/api_service.dart';
import '../../core/service_locator.dart';
import '../../config/theme.dart';
import '../../config/app_spacing.dart';

class PostReviewScreen extends StatefulWidget {
  final Task task;
  final bool isForced;
  final Function(bool)? onReviewSubmitted;

  const PostReviewScreen({
    super.key, 
    required this.task,
    this.isForced = false,
    this.onReviewSubmitted,
  });

  @override
  State<PostReviewScreen> createState() => _PostReviewScreenState();
}

class _PostReviewScreenState extends State<PostReviewScreen> {
  int _communicationRating = 5;
  int _timeRating = 5;
  int _professionalismRating = 5;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  bool _reviewSubmitted = false; // Prevents double submission
  bool _canPop = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    // Prevent double submission
    if (_isSubmitting || _reviewSubmitted) return;
    
    setState(() => _isSubmitting = true);
    try {
      final apiService = getIt<ApiService>();
      await apiService.createReview(
        taskId: widget.task.id,
        communication: _communicationRating,
        time: _timeRating,
        professionalism: _professionalismRating,
        comment: _commentController.text,
      );
      if (mounted) {
        // Mark as submitted to prevent any further submissions
        setState(() {
          _reviewSubmitted = true;
          _canPop = true;
        });
        if (widget.onReviewSubmitted != null) {
          widget.onReviewSubmitted!(true);
        }
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        // Only reset _isSubmitting on error, not on success
        setState(() => _isSubmitting = false);
        
        String errorMessage = e.toString();
        
        // Handle "already reviewed" case gracefully
        if (errorMessage.contains('already reviewed') || errorMessage.contains('409')) {
          if (mounted) {
            setState(() {
              _reviewSubmitted = true;
              _canPop = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This task was already reviewed.'),
                backgroundColor: Colors.blue,
                behavior: SnackBarBehavior.floating,
              ),
            );
            if (widget.onReviewSubmitted != null) {
              widget.onReviewSubmitted!(true);
            }
            Navigator.pop(context, true);
          }
          return;
        }

        if (errorMessage.contains('401') || errorMessage.contains('Unauthorized')) {
          errorMessage = 'Session expired. Please log in again.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    // Removed 'finally' block - we don't reset _isSubmitting after success
    // to keep the button disabled until navigation completes
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => _canPop,
      child: Scaffold(
        backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Leave a Review'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task info
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppTheme.neutral50,
                borderRadius: AppRadius.mdAll,
                border: Border.all(color: AppTheme.neutral200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How was your experience with',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.neutral500,
                              ),
                        ),
                        Text(
                          widget.task.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.neutral900,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.vLg,

            _buildRatingSection('Communication', _communicationRating, (val) {
              setState(() => _communicationRating = val);
            }),
            AppSpacing.vLg,
            _buildRatingSection('Timeliness', _timeRating, (val) {
              setState(() => _timeRating = val);
            }),
            AppSpacing.vLg,
            _buildRatingSection('Professionalism', _professionalismRating, (val) {
              setState(() => _professionalismRating = val);
            }),
            AppSpacing.vXl,

            Text(
              'Comments',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.neutral900,
                  ),
            ),
            AppSpacing.vSm,
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Share more details about your experience...',
                filled: true,
                fillColor: AppTheme.neutral50,
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.mdAll,
                  borderSide: const BorderSide(color: AppTheme.neutral200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.mdAll,
                  borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                ),
              ),
            ),
            AppSpacing.vXxl,

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isSubmitting || _reviewSubmitted) ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _reviewSubmitted ? Colors.green : null,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : _reviewSubmitted
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Review Submitted!',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          )
                        : const Text(
                            'Submit Review',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingSection(String title, int currentRating, Function(int) onRatingChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.neutral900,
              ),
        ),
        AppSpacing.vSm,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (index) {
            final starValue = index + 1;
            return IconButton(
              onPressed: () => onRatingChanged(starValue),
              icon: Icon(
                starValue <= currentRating ? Icons.star : Icons.star_border,
                color: starValue <= currentRating ? Colors.amber : AppTheme.neutral300,
                size: 32,
              ),
            );
          }),
        ),
      ],
    );
  }
}
