import 'package:card_fusion/screens/analytics/activity_list_screen.dart';
import 'package:flutter/material.dart';
import '../../services/analytics_service.dart';
import '../../models/card_model.dart';
import '../../config/theme.dart';
import 'analytics_charts.dart';
import '../../utils/app_error.dart';
import '../../utils/error_display.dart';

class CardAnalyticsScreen extends StatefulWidget {
  final DigitalCard card;

  const CardAnalyticsScreen({super.key, required this.card});

  @override
  State<CardAnalyticsScreen> createState() => _CardAnalyticsScreenState();
}

class _CardAnalyticsScreenState extends State<CardAnalyticsScreen> {
  final _analyticsService = AnalyticsService();
  bool _isLoading = true;
  List<CardAnalytics> _analytics = [];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      setState(() => _isLoading = true);
      final analytics = await _analyticsService.getCardAnalytics(widget.card.id);
      if (analytics.isEmpty) {
        throw AppError(
            message: 'Failed to load analytics data',
            type: ErrorType.analytics);
      }

      if (mounted) {
        setState(() {
          _analytics = analytics;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      final error = AppError.handleError(e, stackTrace);
      if (mounted) {
        ErrorDisplay.showError(context, error);
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_analytics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 80,
              color: AppColors.secondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No analytics available',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadAnalytics,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Scans',
                  _analytics[0].totalScans.toString(),
                  Icons.qr_code_scanner,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Total Views',
                  _analytics[0].totalViews.toString(),
                  Icons.visibility,
                  AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Saves',
                  _analytics[0].totalSaves.toString(),
                  Icons.bookmark,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Unique Users',
                  _analytics[0].uniqueScanners.toString(),
                  Icons.people,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          AnalyticsCharts(
            cardId: widget.card.id,
            analytics: _analytics[0],
          ),
          const SizedBox(height: 24),
          _buildLastInteractionCard(),
          const SizedBox(height: 24),
          _buildDetailedAnalytics(),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32, color: Colors.white),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastInteractionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.access_time,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Last Interaction',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(_analytics[0].lastInteraction),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedAnalytics() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.history,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ActivityListScreen(card: widget.card),
                      ),
                    );
                  },
                  child: Text(
                    'See All',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _analyticsService.getDetailedAnalytics(widget.card.id,
                limit: 5),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final activities = snapshot.data!;
              if (activities.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'No recent activity',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activities.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getEventColor(activity['event_type'])
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getEventIcon(activity['event_type']),
                        color: _getEventColor(activity['event_type']),
                      ),
                    ),
                    title: Text(
                      _getEventTitle(activity),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      _formatDate(DateTime.parse(activity['created_at'])),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    trailing: activity['scanner_email'] != null
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              activity['scanner_email']!,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                              ),
                            ),
                          )
                        : const Text(
                            'Anonymous',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType) {
      case 'scan':
        return Icons.qr_code_scanner;
      case 'save':
        return Icons.bookmark;
      case 'view':
        return Icons.visibility;
      case 'share':
        return Icons.share;
      default:
        return Icons.info;
    }
  }

  String _getEventTitle(Map<String, dynamic> activity) {
    final eventType = activity['event_type'];
    final deviceInfo = activity['device_info'] as Map?;
    final platform = deviceInfo?['platform'] ?? 'Unknown';

    switch (eventType) {
      case 'scan':
        return 'Scanned from $platform';
      case 'save':
        return 'Saved to collection';
      case 'view':
        return 'Viewed card details';
      case 'share':
        return 'Shared card';
      default:
        return 'Unknown activity';
    }
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _getEventColor(activity['event_type']).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getEventIcon(activity['event_type']),
          color: _getEventColor(activity['event_type']),
        ),
      ),
      title: Text(
        _getEventTitle(activity),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        _formatDate(DateTime.parse(activity['created_at'])),
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: activity['scanner_email'] != null
          ? Text(activity['scanner_email'],
              style: const TextStyle(fontSize: 12))
          : const Text('Anonymous',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
    );
  }
}
