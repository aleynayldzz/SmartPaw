import 'package:flutter/material.dart';

import '../../models/food_package_consumption.dart';
import 'analysis_ui.dart';
import 'food_consumption_bar_chart.dart';

class FoodConsumptionCard extends StatelessWidget {
  const FoodConsumptionCard({super.key, required this.records});

  final List<FoodPackageConsumption> records;

  @override
  Widget build(BuildContext context) {
    final averageDays = FoodPackageConsumption.averageDays(records);
    final hasData = records.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AnalysisUi.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Text(
              'Mama Paketi Tüketim Analizi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AnalysisUi.titleInk,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: FoodConsumptionBarChart(records: records),
          ),
          if (hasData) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Text(
                'Ortalama: ${averageDays.round()} gün',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AnalysisUi.titleInk,
                ),
              ),
            ),
          ] else
            const SizedBox(height: 18),
        ],
      ),
    );
  }
}
