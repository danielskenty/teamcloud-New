// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:teamcloud_new/app.dart';
import 'package:teamcloud_new/src/core/providers/firebase_providers.dart';
import 'package:teamcloud_new/src/features/auth/providers/auth_providers.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAppProvider.overrideWith((ref) async {}),
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          authStateListenableProvider.overrideWith(
            (ref) => AuthStateListenable(Stream.value(null)),
          ),
        ],
        child: const TeamCloudApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Run every store from one accurate retail cloud.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    expect(find.text('Business Login'), findsOneWidget);

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.text('Reset your password'), findsOneWidget);
  });

  testWidgets('Unknown routes show branded 404 page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAppProvider.overrideWith((ref) async {}),
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          authStateListenableProvider.overrideWith(
            (ref) => AuthStateListenable(Stream.value(null)),
          ),
        ],
        child: const TeamCloudApp(),
      ),
    );
    await tester.pumpAndSettle();

    final router = GoRouter.of(
      tester.element(
        find.text('Run every store from one accurate retail cloud.'),
      ),
    );
    router.go('/missing-page');
    await tester.pumpAndSettle();

    expect(find.text('404'), findsOneWidget);
    expect(find.text('Page not found'), findsOneWidget);
  });
}
