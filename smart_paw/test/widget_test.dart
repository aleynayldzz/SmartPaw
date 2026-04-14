// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:smart_paw/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Welcome screen renders and navigates', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text("SmartPaw'a\nHoş Geldiniz!"), findsOneWidget);
    expect(find.text('Dostlarınız İçin Akıllı Bakım'), findsOneWidget);
    expect(find.text('Giriş Yap'), findsOneWidget);
    expect(find.text('Hesap Oluştur'), findsOneWidget);

    await tester.tap(find.text('Giriş Yap'));
    await tester.pumpAndSettle();
    expect(find.text('E-posta'), findsOneWidget);
    expect(find.text('Şifre'), findsOneWidget);
    expect(find.text('Şifremi unuttum?'), findsOneWidget);
    expect(find.text('Giriş Yap'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Hesap Oluştur'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hesap Oluştur'));
    await tester.pumpAndSettle();
    expect(find.text('Kayıt Ol'), findsOneWidget);
  });
}
