import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config/api_config.dart';
import 'login_screen.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key, required this.email});

  final String email;

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  static const int _digitCount = 6;

  static const Color _creamBackground = Color(0xFFF7F3ED);
  static const Color _titleColor = Color(0xFF2B1F1C);
  static const Color _cellBorder = Color(0xFFE5C4BE);
  static const Color _cellFill = Color(0xFFFFF8F6);
  static const Color _buttonRose = Color(0xFFD98E8E);

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  bool _syncingControllers = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_digitCount, (_) => TextEditingController());
    _focusNodes = List.generate(_digitCount, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code =>
      _controllers.map((c) => c.text).join().replaceAll(RegExp(r'\D'), '');

  bool get _codeComplete => _code.length == _digitCount;

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _verifyCode() async {
    FocusScope.of(context).unfocus();
    if (!_codeComplete || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await http.post(
        ApiConfig.verifyEmailUri(),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email.trim(), 'code': _code}),
      );

      if (!mounted) return;

      Map<String, dynamic> body = {};
      if (response.body.isNotEmpty) {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            body = decoded;
          }
        } on FormatException {
          _showSnack('Something went wrong. Please try again.');
          return;
        }
      }

      if (response.statusCode == 200 && body['ok'] == true) {
        _showSnack('Successful verification.');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        return;
      }

      _showSnack(body['message']?.toString() ?? 'Verification failed.');
    } catch (_) {
      if (!mounted) return;
      _showSnack(
        'Could not connect to the server. Check that the backend is running.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _onDigitChanged(int index, String raw) {
    if (_syncingControllers) return;

    final digitsOnly = raw.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.isEmpty) {
      _controllers[index].clear();
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
      setState(() {});
      return;
    }

    if (digitsOnly.length > 1) {
      _syncingControllers = true;
      try {
        for (var j = 0; j < digitsOnly.length && index + j < _digitCount; j++) {
          _controllers[index + j].text = digitsOnly[j];
        }
        final end = index + digitsOnly.length;
        if (end >= _digitCount) {
          _focusNodes[_digitCount - 1].requestFocus();
          FocusManager.instance.primaryFocus?.unfocus();
        } else {
          _focusNodes[end].requestFocus();
        }
      } finally {
        _syncingControllers = false;
      }
      setState(() {});
      return;
    }

    _controllers[index].text = digitsOnly;
    if (index < _digitCount - 1) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
    }
    setState(() {});
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap = 8.0;

    return Scaffold(
      backgroundColor: _creamBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Back',
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute<void>(
                        builder: (_) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.arrow_back, color: _titleColor),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final rowWidth = constraints.maxWidth;
                    final totalGaps = gap * (_digitCount - 1);
                    final boxSize = ((rowWidth - totalGaps) / _digitCount)
                        .clamp(40.0, 52.0)
                        .toDouble();

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Verification Code',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontWeight: FontWeight.w700,
                            fontSize: 26,
                            height: 1.2,
                            color: _titleColor,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_digitCount, (index) {
                            return Padding(
                              padding: EdgeInsets.only(
                                right: index < _digitCount - 1 ? gap : 0,
                              ),
                              child: SizedBox(
                                width: boxSize,
                                height: boxSize,
                                child: Focus(
                                  onKeyEvent: (node, event) {
                                    _onKeyEvent(index, event);
                                    return KeyEventResult.ignored;
                                  },
                                  child: TextField(
                                    controller: _controllers[index],
                                    focusNode: _focusNodes[index],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: _titleColor,
                                    ),
                                    decoration: InputDecoration(
                                      counterText: '',
                                      filled: true,
                                      fillColor: _cellFill,
                                      contentPadding: EdgeInsets.zero,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: _cellBorder,
                                          width: 1.2,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: _cellBorder,
                                          width: 1.2,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: _cellBorder,
                                          width: 1.4,
                                        ),
                                      ),
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    onChanged: (v) => _onDigitChanged(index, v),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 36),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (_codeComplete && !_isSubmitting)
                                ? _verifyCode
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _buttonRose,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: _buttonRose.withValues(
                                alpha: 0.45,
                              ),
                              disabledForegroundColor: Colors.white70,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: const StadiumBorder(),
                              textStyle: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                            child: Text(_isSubmitting ? 'Verifying...' : 'Verify'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
