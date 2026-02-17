import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/ad.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../core/service_locator.dart';

import '../screens/equipment/post_equipment_request_screen.dart';
import '../screens/tasks/create_task_screen.dart';

class AdCard extends StatefulWidget {
  final Ad ad;

  const AdCard({super.key, required this.ad});

  @override
  State<AdCard> createState() => _AdCardState();
}

class _AdCardState extends State<AdCard> {
  @override
  void initState() {
    super.initState();
    // Track impression once when the card is built/shown
    getIt<ApiService>().trackAdImpression(widget.ad.id);
  }

  Future<void> _launchUrl() async {
    // Track click
    getIt<ApiService>().trackAdClick(widget.ad.id);
    
    if (!mounted) return;

    final actionUrl = widget.ad.actionUrl;

    // Handle internal app navigation
    if (actionUrl == 'app://create-task') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
      );
    } else if (actionUrl == 'app://create-equipment-request') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PostEquipmentRequestScreen()),
      );
    } else {
      // Launch external URL
      final Uri url = Uri.parse(actionUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        debugPrint('Could not launch $actionUrl');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero, // PageView.viewportFraction handles the gap
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.neutral200),
      ),
      child: InkWell(
        onTap: _launchUrl,
        child: Row(
          children: [
            // Image Section (Left)
            SizedBox(
              width: 120,
              height: double.infinity,
              child: Image.network(
                widget.ad.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppTheme.neutral100,
                  child: const Center(
                    child: Icon(Icons.broken_image, color: AppTheme.neutral400),
                  ),
                ),
              ),
            ),
            
            // Content Section (Right)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.neutral100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Sponsored',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppTheme.neutral600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Title
                    Text(
                      widget.ad.title,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.navy,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Description
                    Expanded(
                      child: Text(
                        widget.ad.description,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // CTA Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        height: 32,
                        child: ElevatedButton(
                          onPressed: _launchUrl,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            widget.ad.buttonText.isNotEmpty ? widget.ad.buttonText : 'View Details',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
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
