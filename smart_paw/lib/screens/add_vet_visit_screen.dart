import 'package:flutter/material.dart';

/// Veteriner ziyareti ekleme akışına giriş noktası (Quick Actions).
class AddVetVisitScreen extends StatelessWidget {
  const AddVetVisitScreen({super.key});

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
          'Veteriner ziyareti',
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
            'Veteriner ziyareti kaydı burada oluşturulacak.',
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
