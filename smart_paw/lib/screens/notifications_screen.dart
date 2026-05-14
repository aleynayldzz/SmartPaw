import 'package:flutter/material.dart';

/// Bildirimler akışına giriş noktası (Quick Actions).
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const Color _titleColor = Color(0xFF2C2825);
  static const Color _creamBg = Color(0xFFFFF9F1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _creamBg,
      appBar: AppBar(
        backgroundColor: _creamBg,
        elevation: 0,
        foregroundColor: _titleColor,
        title: const Text(
          'Bildirimler',
          style: TextStyle(
            color: _titleColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Henüz bildiriminiz yok.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B6B6B),
            ),
          ),
        ),
      ),
    );
  }
}
