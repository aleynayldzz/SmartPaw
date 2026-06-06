import 'package:flutter/material.dart';

import '../../models/weekly_care_completion.dart';
import '../../services/weekly_care_completion_service.dart';
import 'analysis_ui.dart';

class WeeklyCareCompletionCard extends StatelessWidget {
  const WeeklyCareCompletionCard({
    super.key,
    required this.data,
  });

  final WeeklyCareCompletion data;

  @override
  Widget build(BuildContext context) {
    final maxTasks = data.maxTasksPerDay;

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
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Haftalık Tamamlama',
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AnalysisUi.titleInk,
                  ),
                ),
              ),
              if (maxTasks > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AnalysisUi.accentPinkLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Günlük $maxTasks Bakım Rutini',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AnalysisUi.accentPink,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < data.days.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: _DayColumn(
                    label: WeeklyCareCompletionService.dayLabels[i],
                    completed: data.days[i].completedCount,
                    maxTasks: maxTasks,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          _CompletionMessage(percent: data.completionPercent),
        ],
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.label,
    required this.completed,
    required this.maxTasks,
  });

  final String label;
  final int completed;
  final int maxTasks;

  @override
  Widget build(BuildContext context) {
    final bg = AnalysisUi.careCompletionBackground(completed, maxTasks);
    final fg = AnalysisUi.careCompletionForeground(completed, maxTasks);

    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AnalysisUi.muted,
          ),
        ),
        const SizedBox(height: 6),
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$completed',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompletionMessage extends StatelessWidget {
  const _CompletionMessage({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AnalysisUi.accentPinkLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text.rich(
        TextSpan(
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AnalysisUi.titleInk,
            height: 1.35,
          ),
          children: [
            const TextSpan(text: 'Bu hafta bakımların '),
            TextSpan(
              text: '%$percent',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AnalysisUi.titleInk,
              ),
            ),
            const TextSpan(text: '\'ini tamamladın!'),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
