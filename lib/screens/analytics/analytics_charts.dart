import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/theme.dart';
import '../../services/analytics_service.dart';

class AnalyticsCharts extends StatelessWidget {
  final String cardId;
  final CardAnalytics analytics;

  const AnalyticsCharts({
    super.key,
    required this.cardId,
    required this.analytics,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildActivityDistributionChart(),
        const SizedBox(height: 24),
        _buildTimeSeriesChart(),
        if (analytics.scansByCity.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildLocationChart(),
        ],
      ],
    );
  }

  Widget _buildActivityDistributionChart() {
    final totalScans = analytics.totalScans;
    final totalViews = analytics.totalViews;
    final totalSaves = analytics.totalSaves;
    final total = totalScans + totalViews + totalSaves;

    if (total == 0) {
      return _buildEmptyChart('No activity data available');
    }

    final data = [
      PieChartSectionData(
        value: totalScans.toDouble(),
        title: '${((totalScans / total) * 100).toStringAsFixed(1)}%',
        color: AppColors.primary,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: totalViews.toDouble(),
        title: '${((totalViews / total) * 100).toStringAsFixed(1)}%',
        color: AppColors.secondary,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: totalSaves.toDouble(),
        title: '${((totalSaves / total) * 100).toStringAsFixed(1)}%',
        color: Colors.orange,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];

    return Container(
      height: 300,
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
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Activity Distribution',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sections: data,
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      startDegreeOffset: -90,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem('Scans', AppColors.primary, totalScans),
                    const SizedBox(height: 8),
                    _buildLegendItem('Views', AppColors.secondary, totalViews),
                    const SizedBox(height: 8),
                    _buildLegendItem('Saves', Colors.orange, totalSaves),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSeriesChart() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: AnalyticsService().getTimeSeriesAnalytics(cardId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
        }

        final data = snapshot.data!;
        if (data.isEmpty) {
          return _buildEmptyChart('No time series data available');
        }

        final spots = data.map((point) {
          final date = DateTime.parse(point['date'].toString());
          final count = (point['count'] ?? 0).toDouble();
          return FlSpot(
            date.millisecondsSinceEpoch.toDouble(),
            count,
          );
        }).toList();

        if (spots.isEmpty) {
          return _buildEmptyChart('No activity data available');
        }

        return Container(
          height: 300,
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
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.timeline, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Activity Over Time',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                            return Text(
                              '${date.day}/${date.month}',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.primary.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationChart() {
    final cityData = analytics.scansByCity.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    if (cityData.isEmpty) {
      return _buildEmptyChart('No location data available');
    }

    // Limit to top 5 cities to prevent overcrowding
    final displayData = cityData.take(5).toList();
    
    return Container(
      height: 300,
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
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.location_city, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Top Locations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (displayData.first.value.toDouble() * 1.2),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= displayData.length) return const Text('');
                        final cityName = displayData[value.toInt()].key;
                        // Truncate long city names
                        final displayName = cityName.length > 12 
                          ? '${cityName.substring(0, 10)}...' 
                          : cityName;
                        return Transform.rotate(
                          angle: -0.5, // Rotate text slightly for better readability
                          child: Container(
                            padding: const EdgeInsets.only(top: 8, right: 8),
                            child: Text(
                              displayName,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
                barGroups: List.generate(
                  displayData.length,
                  (index) => BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: displayData[index].value.toDouble(),
                        color: AppColors.primary,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (cityData.length > 5) ...[
            const SizedBox(height: 8),
            Text(
              '* Showing top 5 locations',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyChart(String message) {
    return Container(
      height: 300,
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 48,
              color: AppColors.secondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int value) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label ($value)',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
} 