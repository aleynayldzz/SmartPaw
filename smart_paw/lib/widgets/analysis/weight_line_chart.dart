import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/weight_record.dart';
import '../../utils/turkish_date_format.dart';
import 'analysis_ui.dart';

class WeightLineChart extends StatefulWidget {
  const WeightLineChart({
    super.key,
    required this.records,
  });

  final List<WeightRecord> records;

  @override
  State<WeightLineChart> createState() => _WeightLineChartState();
}

class _YScale {
  const _YScale({
    required this.minY,
    required this.maxY,
    required this.interval,
    required this.decimals,
  });

  final double minY;
  final double maxY;
  final double interval;
  final int decimals;

  String labelFor(double value) {
    if (decimals == 0) return value.round().toString();
    return value.toStringAsFixed(decimals);
  }
}

class _WeightLineChartState extends State<WeightLineChart> {
  int? _touchedIndex;

  static const _axisStyle = TextStyle(
    fontSize: 10,
    color: AnalysisUi.muted,
    fontWeight: FontWeight.w500,
  );

  @override
  Widget build(BuildContext context) {
    final records = widget.records;
    if (records.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Ağırlık verisi bulunmuyor',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AnalysisUi.muted,
            ),
          ),
        ),
      );
    }

    final spots = <FlSpot>[
      for (var i = 0; i < records.length; i++)
        FlSpot(i.toDouble(), records[i].weightKg),
    ];

    final weights = records.map((r) => r.weightKg).toList();
    final yScale = _yScaleFor(weights);
    final maxX =
        (records.length - 1).toDouble().clamp(0.0, double.infinity);

    return SizedBox(
      height: 220,
      child: Padding(
        padding: const EdgeInsets.only(right: 8, top: 8),
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: maxX,
            minY: yScale.minY,
            maxY: yScale.maxY,
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
                        yScale.labelFor(value),
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
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final idx = value.round();
                    if (idx < 0 || idx >= records.length) {
                      return const SizedBox.shrink();
                    }
                    final date = records[idx].dateOnly;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _axisDateLabel(date),
                        style: _axisStyle,
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              enabled: true,
              touchCallback: (event, response) {
                if (!event.isInterestedForInteractions ||
                    response == null ||
                    response.lineBarSpots == null ||
                    response.lineBarSpots!.isEmpty) {
                  setState(() => _touchedIndex = null);
                  return;
                }
                setState(() {
                  _touchedIndex = response.lineBarSpots!.first.spotIndex;
                });
              },
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => AnalysisUi.tooltipBg,
                tooltipBorderRadius: BorderRadius.circular(10),
                tooltipPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final idx = spot.spotIndex;
                    if (idx < 0 || idx >= records.length) return null;
                    final record = records[idx];
                    return LineTooltipItem(
                      '${formatTurkishDate(record.dateOnly)} - ${record.weightKg.toStringAsFixed(1)} kg',
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList();
                },
              ),
              getTouchedSpotIndicator: (barData, spotIndexes) {
                return spotIndexes.map((index) {
                  return TouchedSpotIndicatorData(
                    const FlLine(color: Colors.transparent),
                    FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, i) =>
                          FlDotCirclePainter(
                        radius: 5,
                        color: Colors.white,
                        strokeWidth: 2.5,
                        strokeColor: AnalysisUi.accentPink,
                      ),
                    ),
                  );
                }).toList();
              },
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.35,
                color: AnalysisUi.accentPink,
                barWidth: 2.5,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) {
                    final isTouched = _touchedIndex == index;
                    return FlDotCirclePainter(
                      radius: isTouched ? 5 : 3.5,
                      color: Colors.white,
                      strokeWidth: isTouched ? 2.5 : 2,
                      strokeColor: AnalysisUi.accentPink,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AnalysisUi.accentPink.withValues(alpha: 0.28),
                      AnalysisUi.accentPink.withValues(alpha: 0.02),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _axisDateLabel(DateTime date) {
    const months = [
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  /// Ağırlıklar birbirinden uzaksa tam sayı (4,5,6,7); yakınsa 0.2 adımlı (5.0,5.2,5.4).
  static _YScale _yScaleFor(List<double> weights) {
    final minW = weights.reduce((a, b) => a < b ? a : b);
    final maxW = weights.reduce((a, b) => a > b ? a : b);
    final spread = maxW - minW;

    if (spread >= 1.5) {
      final minY = minW.floor().toDouble().clamp(0.0, double.infinity);
      var maxY = maxW.ceil().toDouble();
      if (maxY <= minY) maxY = minY + 1;
      return _YScale(
        minY: minY,
        maxY: maxY,
        interval: 1,
        decimals: 0,
      );
    }

    const step = 0.2;
    final pad = spread < 0.15 ? 0.2 : 0.1;
    var minY = _snapDown(minW - pad, step);
    var maxY = _snapUp(maxW + pad, step);
    if (maxY <= minY) maxY = minY + step * 2;
    return _YScale(
      minY: minY.clamp(0.0, double.infinity),
      maxY: maxY,
      interval: step,
      decimals: 1,
    );
  }

  static double _snapDown(double value, double step) {
    return (_roundTo((value / step).floor() * step, 1));
  }

  static double _snapUp(double value, double step) {
    return _roundTo((value / step).ceil() * step, 1);
  }

  static double _roundTo(double value, int places) {
    final p = math.pow(10, places).toDouble();
    return (value * p).round() / p;
  }

  static bool _isTickValue(double value, _YScale scale) {
    final steps = ((value - scale.minY) / scale.interval).round();
    final expected = _roundTo(scale.minY + steps * scale.interval, 2);
    return (value - expected).abs() < 0.051;
  }
}
