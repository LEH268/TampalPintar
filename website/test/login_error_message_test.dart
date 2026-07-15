import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tampal_pintar_gov/screens/login_screen.dart';

/// Guards what a failed login is allowed to say on screen.
///
/// The messages below are the real ones gotrue produces: on a network or CORS
/// failure it throws `AuthRetryableFetchException(message: e.toString())` with
/// the underlying ClientException (fetch.dart:204), and on a 5xx it passes the
/// raw response body (fetch.dart:53). Both extend AuthException, which is how
/// the raw text originally reached users.
void main() {
  group('network failure', () {
    test('does not leak the backend URL or exception type', () {
      final error = AuthRetryableFetchException(
        message: 'ClientException: Failed to fetch, uri=https://abcdefg.supabase.co'
            '/auth/v1/token?grant_type=password',
      );

      final message = loginErrorMessage(error);

      expect(message, 'Ralat rangkaian. Semak sambungan anda dan cuba lagi.');
      expect(message, isNot(contains('supabase.co')));
      expect(message, isNot(contains('ClientException')));
      expect(message, isNot(contains('grant_type')));
    });

    test('does not leak a raw 5xx response body', () {
      final error = AuthRetryableFetchException(
        message: '{"error":"internal","stack":"pg_catalog.users line 42"}',
        statusCode: '500',
      );

      final message = loginErrorMessage(error);

      expect(message, 'Ralat rangkaian. Semak sambungan anda dan cuba lagi.');
      expect(message, isNot(contains('pg_catalog')));
    });
  });

  test('curated auth messages are passed through unchanged', () {
    // The role rejection thrown by _login() for a citizen account.
    const error =
        AuthException('Akaun rakyat tidak boleh mengakses papan pemuka kerajaan.');

    expect(loginErrorMessage(error),
        'Akaun rakyat tidak boleh mengakses papan pemuka kerajaan.');
  });

  test('wrong credentials keep gotrue\'s own message', () {
    const error = AuthApiException('Invalid login credentials', statusCode: '400');

    expect(loginErrorMessage(error), 'Invalid login credentials');
  });

  test('an unexpected non-auth error falls back to a generic message', () {
    // e.g. the profiles lookup failing after a successful sign-in.
    final error = Exception('PostgrestException(message: permission denied '
        'for table profiles, code: 42501)');

    final message = loginErrorMessage(error);

    expect(message, 'Log masuk gagal. Sila cuba lagi.');
    expect(message, isNot(contains('permission denied')));
    expect(message, isNot(contains('42501')));
  });
}
