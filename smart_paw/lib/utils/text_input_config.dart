import 'package:flutter/material.dart';

enum UserTextInputKind {
  general,
  email,
  password,
  multiline,
}

/// Standart TextField — ek klavye müdahalesi yok, karakter filtresi yok.
class UserTextField extends StatelessWidget {
  const UserTextField({
    super.key,
    required this.controller,
    this.kind = UserTextInputKind.general,
    this.decoration,
    this.style,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.obscureText = false,
    this.cursorColor,
  });

  final TextEditingController controller;
  final UserTextInputKind kind;
  final InputDecoration? decoration;
  final TextStyle? style;
  final int? minLines;
  final int? maxLines;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final Color? cursorColor;

  bool get _isMultiline =>
      kind == UserTextInputKind.multiline ||
      (minLines != null && minLines! > 1) ||
      (maxLines != null && maxLines! > 1);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: kind == UserTextInputKind.email
          ? TextInputType.emailAddress
          : TextInputType.text,
      obscureText: obscureText,
      autocorrect: false,
      enableSuggestions: false,
      textCapitalization: TextCapitalization.none,
      minLines: _isMultiline ? minLines : 1,
      maxLines: _isMultiline ? maxLines : 1,
      maxLength: maxLength,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      style: style,
      cursorColor: cursorColor,
      decoration: decoration,
    );
  }
}

abstract final class TextInputConfig {
  static const email = UserTextInputKind.email;
}
