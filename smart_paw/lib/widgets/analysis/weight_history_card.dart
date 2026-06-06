import 'package:flutter/material.dart';

import '../../models/weight_record.dart';
import 'analysis_ui.dart';
import 'cat_profile_selector.dart';
import 'weight_line_chart.dart';

class WeightHistoryCard extends StatelessWidget {
  const WeightHistoryCard({
    super.key,
    required this.cats,
    required this.selectedCatId,
    required this.records,
    required this.onCatSelected,
  });

  final List<Map<String, dynamic>> cats;
  final int? selectedCatId;
  final List<WeightRecord> records;
  final ValueChanged<int> onCatSelected;

  @override
  Widget build(BuildContext context) {
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
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Ağırlık Geçmişi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AnalysisUi.titleInk,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AnalysisUi.accentPinkLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Son 6 Ay',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AnalysisUi.accentPink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: WeightLineChart(records: records),
          ),
          const SizedBox(height: 4),
          CatProfileSelector(
            cats: cats,
            selectedCatId: selectedCatId,
            onSelect: onCatSelected,
          ),
        ],
      ),
    );
  }
}
