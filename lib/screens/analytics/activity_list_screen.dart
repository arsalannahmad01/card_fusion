import 'package:flutter/material.dart';
import '../../models/card_model.dart';
import '../../services/analytics_service.dart';
import '../../config/theme.dart';
import '../../utils/error_display.dart';
import '../../utils/app_error.dart';

class ActivityListScreen extends StatefulWidget {
  final DigitalCard card;
  
  const ActivityListScreen({
    super.key,
    required this.card,
  });

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  final _analyticsService = AnalyticsService();
  final _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasMore = true;
  List<Map<String, dynamic>> _activities = [];
  int _page = 0;
  static const _itemsPerPage = 15;

  @override
  void initState() {
    super.initState();
    _loadActivities();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading &&
        _hasMore) {
      _loadActivities();
    }
  }

  Future<void> _loadActivities() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final activities = await _analyticsService.getDetailedAnalytics(
        widget.card.id,
        offset: _page * _itemsPerPage,
        limit: _itemsPerPage,
      );

      setState(() {
        _activities.addAll(activities);
        _hasMore = activities.length == _itemsPerPage;
        _page++;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ErrorDisplay.showError(context, AppError.handleError(e));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Activity History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _activities.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _activities.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final activity = _activities[index];
          return _buildActivityItem(activity);
        },
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getEventColor(activity['event_type']).withOpacity(0.1),
          child: Icon(
            _getEventIcon(activity['event_type']),
            color: _getEventColor(activity['event_type']),
          ),
        ),
        title: Text(
          _getEventTitle(activity['event_type']),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (activity['scanner_email'] != null)
              Text('by ${activity['scanner_email']}'),
            Text(
              _formatDate(DateTime.parse(activity['created_at'])),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getEventTitle(String eventType) {
    switch (eventType) {
      case 'view':
        return 'Card Viewed';
      case 'scan':
        return 'Card Scanned';
      case 'save':
        return 'Card Saved';
      default:
        return 'Card Interaction';
    }
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType) {
      case 'view':
        return Icons.visibility;
      case 'scan':
        return Icons.qr_code_scanner;
      case 'save':
        return Icons.bookmark;
      default:
        return Icons.touch_app;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  Color _getEventColor(String eventType) {
    switch (eventType) {
      case 'scan':
        return AppColors.primary;
      case 'save':
        return Colors.orange;
      case 'view':
        return AppColors.secondary;
      default:
        return Colors.grey;
    }
  }
} 