import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/food_package_consumption.dart';
import 'analysis_ui.dart';

class FoodConsumptionBarChart extends StatelessWidget {
  const FoodConsumptionBarChart({super.key, required this.records});

  final List<FoodPackageConsumption> records;

  static const _axisStyle = TextStyle(
    fontSize: 10,
    color: AnalysisUi.muted,
    fontWeight: FontWeight.w500,
  );

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No food consumption data available',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AnalysisUi.muted,
            ),
          ),
        ),
      );
    }

    final maxDays = records.map((r) => r.daysLasted).reduce(math.max);
    final yScale = _yScaleFor(maxDays);

    return SizedBox(
      height: 220,
      child: Padding(
        padding: const EdgeInsets.only(right: 8, top: 8),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: yScale.maxY,
            minY: 0,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: yScale.interval,
              getDrawingHorizontalLine: (_) =>
                  const FlLine(color: AnalysisUi.gridLine, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  interval: yScale.interval,
                  getTitlesWidget: (value, meta) {
                    if (!_isTickValue(value, yScale)) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        value.round().toString(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AnalysisUi.muted,
                          fontWeight: FontWeight.w500,
                        ),
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
                    final idx = value.round();
                    if (idx < 0 || idx >= records.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _axisDateLabel(records[idx].openingDate),
                        style: _axisStyle,
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => AnalysisUi.tooltipBg,
                tooltipBorderRadius: BorderRadius.circular(10),
                tooltipPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  if (groupIndex < 0 || groupIndex >= records.length) {
                    return null;
                  }
                  final record = records[groupIndex];
                  return BarTooltipItem(
                    '${_axisDateLabel(record.openingDate)}\n${record.daysLasted} gün',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),
            barGroups: [
              for (var i = 0; i < records.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: records[i].daysLasted.toDouble(),
                      width: records.length <= 3 ? 28 : 20,
                      color: AnalysisUi.accentPink,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _axisDateLabel(DateTime date) {
    const months = [
      'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  static _YScale _yScaleFor(int maxDays) {
    final maxY = maxDays <= 40 ? 40.0 : maxDays <= 80 ? 80.0 : 120.0;
    final interval = maxY <= 40 ? 20.0 : maxY / 3;
    return _YScale(maxY: maxY, interval: interval);
  }

  static bool _isTickValue(double value, _YScale scale) {
    final steps = (value / scale.interval).round();
    return (value - steps * scale.interval).abs() < 0.51;
  }
}

class _YScale {
  const _YScale({required this.maxY, required this.interval});
  final double maxY;
  final double interval;
}
