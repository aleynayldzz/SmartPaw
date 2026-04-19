// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:smart_paw/main.dart';
import 'package:smart_paw/screens/verification_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  testWidgets('Welcome screen renders and navigates', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text("SmartPaw'a\nHoş Geldiniz!"), findsOneWidget);
    expect(find.text('Dostlarınız İçin Akıllı Bakım'), findsOneWidget);
    expect(find.text('Giriş Yap'), findsOneWidget);
    expect(find.text('Hesap Oluştur'), findsOneWidget);

    await tester.ensureVisible(find.text('Hesap Oluştur'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hesap Oluştur'));
    await tester.pumpAndSettle();
    expect(find.text('Kayıt Ol'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Giriş Yap'));
    await tester.pumpAndSettle();
    expect(find.text('E-posta'), findsOneWidget);
    expect(find.text('Şifre'), findsOneWidget);
    expect(find.text('Şifremi unuttum?'), findsOneWidget);
    expect(find.text('Giriş Yap'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);
  });

  testWidgets('Verification screen opens from navigator', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const VerificationScreen(
                          email: 'test@example.com',
                        ),
                      ),
                    );
                  },
                  child: const Text('open_verification'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open_verification'));
    await tester.pumpAndSettle();

    expect(find.text('Verification Code'), findsOneWidget);
    expect(find.text('Verify'), findsOneWidget);
    expect(find.text('Geri Gel'), findsNothing);
  });
}
