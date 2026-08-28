import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../models/analytics.dart';
import '../theme/palette.dart';

/// Weekly earnings area chart built with fl_chart.
class RevenueChart extends StatelessWidget {
  final Language language;

  const RevenueChart({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final axisColor = dark ? Colors.white54 : AppColors.ink500;
    final gridColor = dark ? Colors.white10 : AppColors.ink200;
    final peakIndex = kWeekEarnings.indexOf(kPeakDay);

    // Build data spots
    final spots = <FlSpot>[
      for (int i = 0; i < kWeekEarnings.length; i++)
        FlSpot(i.toDouble(), kWeekEarnings[i].amount),
    ];

    return SizedBox(
      height: 192,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 13000,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 3000,
            getDrawingHorizontalLine: (_) => FlLine(color: gridColor, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= kWeekEarnings.length) return const SizedBox.shrink();
                  final day = language == Language.hi
                      ? kWeekEarnings[i].dayHi
                      : kWeekEarnings[i].dayEn;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(day, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: axisColor)),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => dark ? AppColors.ink950 : AppColors.ink800,
              tooltipRoundedRadius: 12,
              getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                return LineTooltipItem(
                  '₹${s.y.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.saffron600,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, xPercentage, bar, index) {
                  final isPeak = spot.x.toInt() == peakIndex;
                  return FlDotCirclePainter(
                    radius: isPeak ? 7 : 3,
                    color: AppColors.saffron600,
                    strokeWidth: isPeak ? 3 : 0,
                    strokeColor: dark ? AppColors.ink950 : Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.saffron500.withAlpha(115),
                    AppColors.saffron500.withAlpha(5),
                  ],
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 600),
      ),
    );
  }
}
