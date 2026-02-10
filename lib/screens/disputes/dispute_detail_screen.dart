import 'package:flutter/material.dart';
import '../../models/dispute.dart';
import '../../services/api_service.dart';
import '../../core/service_locator.dart';
import '../../config/theme.dart';
import '../../widgets/user_avatar.dart';
import 'package:timeago/timeago.dart' as timeago;

class DisputeDetailScreen extends StatefulWidget {
  final String disputeId;

  const DisputeDetailScreen({super.key, required this.disputeId});

  @override
  State<DisputeDetailScreen> createState() => _DisputeDetailScreenState();
}

class _DisputeDetailScreenState extends State<DisputeDetailScreen> {
  final ApiService _apiService = getIt<ApiService>();
  Dispute? _dispute;
  List<DisputeMessage> _messages = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dispute = await _apiService.getDisputeById(widget.disputeId);
      final messages = await _apiService.getDisputeMessages(widget.disputeId);
      if (mounted) {
        setState(() {
          _dispute = dispute;
          _messages = messages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load dispute details: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      final text = _messageController.text.trim();
      _messageController.clear();
      await _apiService.sendDisputeMessage(widget.disputeId, text);
      // Refresh messages
      final messages = await _apiService.getDisputeMessages(widget.disputeId);
      if (mounted) {
        setState(() {
          _messages = messages;
          _isSending = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispute Details'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _dispute == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error ?? 'Dispute not found'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchDetails,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildDisputeInfo(),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    'COMMUNICATION',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              if (_messages.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No messages yet. Send a message to the support team or the other party.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final message = _messages[index];
                      return _buildMessageItem(message);
                    },
                    childCount: _messages.length,
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
            ],
          ),
        ),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildDisputeInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusBadge(_dispute!.status),
              Text(
                'Case #${_dispute!.id.substring(0, 8).toUpperCase()}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _dispute!.taskTitle ?? 'Task Dispute',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.help_outline, 'Reason', _dispute!.displayReason),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.calendar_today, 'Filed', timeago.format(_dispute!.createdAt)),
          const SizedBox(height: 16),
          const Text(
            'DESCRIPTION',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(_dispute!.description),
          if (_dispute!.resolution != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.success.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RESOLUTION',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.success),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _dispute!.resolution!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (_dispute!.resolutionNotes != null) ...[
                    const SizedBox(height: 4),
                    Text(_dispute!.resolutionNotes!),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildMessageItem(DisputeMessage message) {
    final bool isAdmin = message.isAdmin;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: isAdmin ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (!isAdmin) ...[
                UserAvatar(
                  name: message.senderName ?? 'U',
                  radius: 12,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                isAdmin ? 'SUPPORT AGENT' : (message.senderName ?? 'User'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isAdmin ? Colors.blue : AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                timeago.format(message.createdAt, locale: 'en_short'),
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isAdmin ? Colors.blue.withOpacity(0.05) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: isAdmin ? Border.all(color: Colors.blue.withOpacity(0.2)) : null,
            ),
            child: Text(message.message),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    if (_dispute!.status == 'resolved' || _dispute!.status == 'closed') {
      return Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        color: Colors.white,
        child: const Center(
          child: Text(
            'This dispute has been resolved and is now closed.',
            style: TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
              ),
              maxLines: null,
            ),
          ),
          IconButton(
            icon: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send, color: AppTheme.primary),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'open':
        color = Colors.blue;
        label = 'Open';
        break;
      case 'under_review':
        color = Colors.orange;
        label = 'Under Review';
        break;
      case 'resolved':
        color = Colors.green;
        label = 'Resolved';
        break;
      case 'closed':
        color = Colors.grey;
        label = 'Closed';
        break;
      case 'escalated':
        color = Colors.red;
        label = 'Escalated';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
