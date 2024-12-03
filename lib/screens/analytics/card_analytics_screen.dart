import 'package:flutter/material.dart';
import '../../services/analytics_service.dart';
import '../../models/card_model.dart';

class CardAnalyticsScreen extends StatefulWidget {
  final DigitalCard card;

  const CardAnalyticsScreen({super.key, required this.card});

  @override
  State<CardAnalyticsScreen> createState() => _CardAnalyticsScreenState();
}

class _CardAnalyticsScreenState extends State<CardAnalyticsScreen> {
  final _analyticsService = AnalyticsService();
  bool _isLoading = true;
  CardAnalytics? _analytics;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      final analytics = await _analyticsService.getCardAnalytics(widget.card.id);
      if (mounted) {
        setState(() {
          _analytics = analytics;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading analytics: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_analytics == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No analytics available'),
            TextButton(
              onPressed: _loadAnalytics,
              child: const Text('Retry'),
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
          _buildStatCard(
            'Total Scans',
            _analytics!.totalScans.toString(),
            Icons.qr_code_scanner,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Total Saves',
            _analytics!.totalSaves.toString(),
            Icons.bookmark,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Total Views',
            _analytics!.totalViews.toString(),
            Icons.visibility,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Unique Scanners',
            _analytics!.uniqueScanners.toString(),
            Icons.people,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Last Interaction',
            _formatDate(_analytics!.lastInteraction),
            Icons.access_time,
          ),
          const SizedBox(height: 16),
          _buildDetailedAnalytics(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).primaryColor,
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  Widget _buildDetailedAnalytics() {
    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _analyticsService.getDetailedAnalytics(widget.card.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final activities = snapshot.data!;
              if (activities.isEmpty) {
                return const Center(child: Text('No recent activity'));
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  return ListTile(
                    leading: Icon(_getEventIcon(activity['event_type'])),
                    title: Text(_getEventTitle(activity)),
                    subtitle: Text(
                      _formatDate(DateTime.parse(activity['created_at'])),
                    ),
                    trailing: Text(
                      activity['scanner_email'] ?? 'Anonymous',
                      style: Theme.of(context).textTheme.bodySmall,
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
} 