import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tampal_pintar_gov/screens/login_screen.dart';

/// Guards the client-side login validation.
///
/// These tests never initialize Supabase. That is the point: if validation
/// stops passing, `_login()` reaches `Supabase.instance.client` and the test
/// fails with an initialization error instead of a silent regression.
void main() {
  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
  }

  Future<void> tapLogin(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Log Masuk'));
    await tester.pump();
  }

  testWidgets('empty form shows both errors and never calls Supabase',
      (tester) async {
    await pumpLogin(tester);
    await tapLogin(tester);

    expect(find.text('Sila masukkan e-mel.'), findsOneWidget);
    expect(find.text('Sila masukkan kata laluan.'), findsOneWidget);
  });

  testWidgets('malformed email is rejected before any network call',
      (tester) async {
    await pumpLogin(tester);
    await tester.enterText(find.byType(TextFormField).first, 'notanemail');
    await tester.enterText(find.byType(TextFormField).last, 'somepassword');
    await tapLogin(tester);

    expect(find.text('Format e-mel tidak sah.'), findsOneWidget);
  });

  testWidgets('missing password is rejected even with a valid email',
      (tester) async {
    await pumpLogin(tester);
    await tester.enterText(
        find.byType(TextFormField).first, 'officer@jkr.gov.my');
    await tapLogin(tester);

    expect(find.text('Sila masukkan kata laluan.'), findsOneWidget);
    expect(find.text('Format e-mel tidak sah.'), findsNothing);
  });

  // No tap here: valid input passes validation and `_login()` would reach
  // Supabase, which these tests deliberately never initialize. The Form's
  // autovalidateMode validates on typing, so the assertion needs no submit.
  testWidgets('surrounding whitespace does not make an email invalid',
      (tester) async {
    await pumpLogin(tester);
    await tester.enterText(
        find.byType(TextFormField).first, '  officer@jkr.gov.my  ');
    await tester.pump();

    expect(find.text('Format e-mel tidak sah.'), findsNothing);
    expect(find.text('Sila masukkan e-mel.'), findsNothing);
  });
}
