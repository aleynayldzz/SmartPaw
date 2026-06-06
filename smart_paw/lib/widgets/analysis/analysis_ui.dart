import 'package:flutter/material.dart';

/// Analiz sekmesi ortak renk ve stiller.
abstract final class AnalysisUi {
  static const pageBg = Color(0xFFFFF9F1);
  static const cardBg = Colors.white;
  static const titleInk = Color(0xFF2C2825);
  static const muted = Color(0xFF6B6B6B);
  static const accentPink = Color(0xFFD47A85);
  static const accentPinkLight = Color(0xFFF9E4E4);
  static const selectorBarBg = Color(0xFFF3F0EA);
  static const gridLine = Color(0xFFE8E4DE);
  static const tooltipBg = Color(0xFF3D3D3D);

  /// 0 = boş gün, 1..maxTasks = açıktan koyu pembeye ölçeklenir.
  static const _careCompletionPalette = <Color>[
    Color(0xFFF5F0F1),
    Color(0xFFF9E4E7),
    Color(0xFFF0C4CB),
    Color(0xFFE8A4B0),
    Color(0xFFDF8495),
    Color(0xFFD66B7F),
    Color(0xFFCD5269),
  ];

  static Color careCompletionBackground(int completed, int maxTasks) {
    if (maxTasks <= 0 || completed <= 0) {
      return _careCompletionPalette.first;
    }
    final ratio = (completed / maxTasks).clamp(0.0, 1.0);
    final index = (ratio * (_careCompletionPalette.length - 1)).round();
    return _careCompletionPalette[index.clamp(0, _careCompletionPalette.length - 1)];
  }

  static Color careCompletionForeground(int completed, int maxTasks) {
    if (maxTasks <= 0 || completed <= 0) return muted;
    return completed >= (maxTasks * 0.55).ceil()
        ? Colors.white
        : titleInk;
  }
}
