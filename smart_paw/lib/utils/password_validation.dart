import 'package:flutter/material.dart';

class PasswordValidation {
  PasswordValidation._();

  static const String formatHint =
      'Şifre en az 8 karakter olmalı; büyük harf, küçük harf ve özel karakter içermelidir.';

  static const Color warningColor = Color(0xFFE9A5A1);

  static bool isValid(String password) {
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[^A-Za-z0-9]').hasMatch(password);
  }

  static Widget warningAboveButton(String? message) {
    if (message == null || message.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 12.5,
            height: 1.35,
            color: warningColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
