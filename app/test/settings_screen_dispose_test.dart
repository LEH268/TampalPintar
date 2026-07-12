// Regression test for the "setState() called after dispose()" hazard in
// SettingsScreen._load().
//
// WHAT THIS FILE ACTUALLY TESTS (read before trusting the name):
// `SettingsScreen` cannot be constructed directly in a plain `flutter test`
// host: its State creates `ProfileService(Supabase.instance.client)` in a
// field initializer, and `Supabase.instance` throws
// (`Instance of Supabase must be initialized`) unless
// `Supabase.initialize(...)` has run — which would require a real/stubbed
// network client we don't have here.
//
// So this file does NOT drive `SettingsScreen` itself. Instead it
// reproduces the exact lifecycle shape of `_load()` in a minimal, local
// `StatefulWidget`:
//
//     initState() -> _load() -> await controlledFuture -> setState(...)
//
// with the widget being removed from the tree (dispose) while that future
// is still pending — the same race a user triggers by opening Settings and
// switching tabs before the profile fetch resolves (HomeShell has no
// IndexedStack, so tab switches dispose the old subtree).
//
// HOW THE ERROR IS CAPTURED, AND WHY NOT tester.takeException():
// `_load()` is called fire-and-forget from initState() (exactly as
// settings_screen.dart does: `_load();` with no await/catchError). When the
// unguarded setState() throws, the throw happens inside the async
// continuation of an *unawaited* Future, so it never passes through
// Flutter's build/layout/paint error boundary (the mechanism that feeds
// `tester.takeException()`). Instead Dart reports it as an unhandled async
// error on the ambient `Zone`, which the Flutter test framework treats as
// an immediate, un-recoverable test failure — `takeException()` returns
// null for it because nothing was ever queued there. Confirmed empirically
// during development (takeException()-based version left the exception
// uncaptured and the test failed outright), and confirmed by precedent in
// the Flutter SDK's own suite: `packages/flutter/test/widgets/async_test.dart`
// ("debugRethrowError rethrows caught error") uses `runZonedGuarded` to
// catch exactly this class of error, not `takeException()`. This file
// follows that same precedent.
//
// Two tests:
//   1. `_UnguardedProbe` — setState with NO `mounted` check. This is the
//      negative control: it proves the harness actually detects the bug by
//      installing a `runZonedGuarded` error handler around the
//      pump-build-dispose-complete sequence and asserting the captured
//      error is non-null and its string contains
//      "setState() called after dispose()". If this test ever stops
//      catching an error, the harness has stopped detecting the hazard and
//      the positive test below is not trustworthy.
//   2. `_GuardedProbe` — identical, but with `if (!mounted) return;` before
//      `setState`, mirroring the fixed `settings_screen.dart:_load()`
//      exactly. Asserts no error reaches the zone handler.
//
// This pins the *pattern*. `settings_screen.dart`'s `_load()` now matches
// the guarded probe's shape line-for-line (await, then `if (!mounted)
// return;`, then setState), so this test stands in for a direct
// `SettingsScreen` test without requiring Supabase to be initialized.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors the buggy shape: `await` then unguarded `setState`.
class _UnguardedProbe extends StatefulWidget {
  final Future<void> Function() fetch;
  const _UnguardedProbe({required this.fetch});

  @override
  State<_UnguardedProbe> createState() => _UnguardedProbeState();
}

class _UnguardedProbeState extends State<_UnguardedProbe> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await widget.fetch();
    setState(() {
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) =>
      Text(_loaded ? 'loaded' : 'loading');
}

/// Mirrors the fixed shape: `await` then `if (!mounted) return;` then
/// `setState` — identical to `settings_screen.dart:_load()` after the fix.
class _GuardedProbe extends StatefulWidget {
  final Future<void> Function() fetch;
  const _GuardedProbe({required this.fetch});

  @override
  State<_GuardedProbe> createState() => _GuardedProbeState();
}

class _GuardedProbeState extends State<_GuardedProbe> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await widget.fetch();
    if (!mounted) return;
    setState(() {
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) =>
      Text(_loaded ? 'loaded' : 'loading');
}

void main() {
  testWidgets(
      'negative control: UNGUARDED setState after dispose throws '
      '(proves the harness detects the hazard)', (tester) async {
    Object? capturedError;

    await runZonedGuarded(() async {
      final completer = Completer<void>();

      await tester.pumpWidget(
        MaterialApp(home: _UnguardedProbe(fetch: () => completer.future)),
      );

      // Remove the widget from the tree before the fetch resolves — same
      // race as switching tabs in HomeShell (no IndexedStack) while the
      // profile fetch is in flight.
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

      // Now let the pending fetch complete; the unguarded setState() fires
      // against a disposed State. Because _load() is unawaited
      // fire-and-forget (as in the real code), this surfaces as an
      // unhandled async error on this Zone rather than through Flutter's
      // build-phase error boundary.
      completer.complete();
      await tester.pump();
    }, (error, stack) {
      capturedError = error;
    });

    expect(capturedError, isNotNull,
        reason:
            'unguarded setState-after-dispose should have thrown, but no '
            'exception was captured by the zone handler');
    expect(
      capturedError.toString(),
      contains('setState() called after dispose()'),
    );
  });

  testWidgets(
      'guarded variant (matches fixed settings_screen.dart _load): '
      'no exception when disposed mid-fetch', (tester) async {
    Object? capturedError;

    await runZonedGuarded(() async {
      final completer = Completer<void>();

      await tester.pumpWidget(
        MaterialApp(home: _GuardedProbe(fetch: () => completer.future)),
      );

      // Same race: dispose before the fetch resolves.
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

      completer.complete();
      await tester.pump();
    }, (error, stack) {
      capturedError = error;
    });

    expect(capturedError, isNull);
    expect(tester.takeException(), isNull);
  });
}
