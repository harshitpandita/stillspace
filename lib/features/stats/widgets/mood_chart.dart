// Mood chart widget - 7-day line chart using fl_chart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/mood_provider.dart';

class MoodChart extends StatelessWidget {
  const MoodChart({super.key});

  @override
  Widget build(BuildContext context) {
    final moodProvider = context.watch<MoodProvider>();
    final dailyMoods = moodProvider.dailyAverageMoods;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mood Trend', style: AppTextStyles.headline3),
          const SizedBox(height: 8),
          Text(
            'Your emotional trend this week',
            style: AppTextStyles.insightLabel,
          ),
          const SizedBox(height: 24),
          dailyMoods.isEmpty
              ? _buildEmptyState()
              : SizedBox(
                  height: 180,
                  child: _buildChart(dailyMoods),
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 180,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insert_chart_outlined, color: AppColors.textSecondary, size: 48),
            const SizedBox(height: 12),
            Text(
              'No mood data yet',
              style: AppTextStyles.body2,
            ),
            const SizedBox(height: 4),
            Text(
              'Log your mood to see trends',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(Map<String, double> dailyMoods) {
    final now = DateTime.now();
    final spots = <FlSpot>[];
    final labels = <String>[];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = _dateKey(date);
      final x = (6 - i).toDouble();

      labels.add(_shortDayName(date));

      if (dailyMoods.containsKey(dateKey)) {
        spots.add(FlSpot(x, dailyMoods[dateKey]!));
      }
    }

    if (spots.isEmpty) {
      return _buildEmptyState();
    }

    return LineChart(
      LineChartData(
        minY: 0.5,
        maxY: 5.5,
        minX: -0.5,
        maxX: 6.5,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.background,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value < 1 || value > 5) return const SizedBox();
                const emojis = ['😔', '😕', '😐', '🙂', '😊'];
                return Text(
                  emojis[value.toInt() - 1],
                  style: const TextStyle(fontSize: 12),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= labels.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    labels[index],
                    style: AppTextStyles.caption,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 5,
                  color: AppColors.primary,
                  strokeWidth: 2,
                  strokeColor: AppColors.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => AppColors.background,
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                const emojis = ['😔', '😕', '😐', '🙂', '😊'];
                final moodIndex = spot.y.round().clamp(1, 5) - 1;
                return LineTooltipItem(
                  emojis[moodIndex],
                  const TextStyle(fontSize: 20),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _shortDayName(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }
}
