// Widget tests for SettingsScreen.
//
// Covers rendering and navigation tile routing for SettingsScreen:
//   - renders all six navigation tiles (Tags, Instruments, Trash,
//     Appearance, Custom Fields, About)
//   - About tile shows app name and version string
//   - tapping Tags tile triggers go_router navigation to /settings/tags
//   - tapping Instruments tile triggers navigation to /settings/instruments
//   - tapping Trash tile triggers navigation to /settings/trash
//   - tapping Appearance tile triggers navigation to /settings/appearance
//   - tapping Custom Fields tile triggers navigation to /settings/custom-fields
//
// Naming convention:
//   <widget/scenario> → <expected outcome>

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:swaralipi/features/settings/screens/settings_screen.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds a testable [SettingsScreen] wrapped in a [GoRouter] that records
/// the last navigation destination.
Widget _buildApp({
  required List<String> navigatedRoutes,
  String appName = 'Swaralipi',
  String version = '1.2.3',
  String buildNumber = '42',
}) {
  PackageInfo.setMockInitialValues(
    appName: appName,
    packageName: 'com.example.swaralipi',
    version: version,
    buildNumber: buildNumber,
    buildSignature: '',
  );

  final router = GoRouter(
    initialLocation: '/settings',
    routes: [
      GoRoute(
        path: '/settings',
        builder: (_, __) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'tags',
            builder: (_, __) {
              navigatedRoutes.add('/settings/tags');
              return const _StubScreen(label: 'tags');
            },
          ),
          GoRoute(
            path: 'instruments',
            builder: (_, __) {
              navigatedRoutes.add('/settings/instruments');
              return const _StubScreen(label: 'instruments');
            },
          ),
          GoRoute(
            path: 'trash',
            builder: (_, __) {
              navigatedRoutes.add('/settings/trash');
              return const _StubScreen(label: 'trash');
            },
          ),
          GoRoute(
            path: 'appearance',
            builder: (_, __) {
              navigatedRoutes.add('/settings/appearance');
              return const _StubScreen(label: 'appearance');
            },
          ),
          GoRoute(
            path: 'custom-fields',
            builder: (_, __) {
              navigatedRoutes.add('/settings/custom-fields');
              return const _StubScreen(label: 'custom-fields');
            },
          ),
        ],
      ),
    ],
  );

  return MaterialApp.router(
    routerConfig: router,
    theme: ThemeData(useMaterial3: true),
  );
}

// ---------------------------------------------------------------------------
// Stub destinations
// ---------------------------------------------------------------------------

class _StubScreen extends StatelessWidget {
  const _StubScreen({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(label);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('SettingsScreen —', () {
    group('renders all navigation tiles', () {
      testWidgets(
        'shows Tags, Instruments, Trash, Appearance, Custom Fields tiles',
        (tester) async {
          await tester.pumpWidget(_buildApp(navigatedRoutes: []));
          await tester.pumpAndSettle();

          expect(find.text('Tags'), findsOneWidget);
          expect(find.text('Instruments'), findsOneWidget);
          expect(find.text('Trash'), findsOneWidget);
          expect(find.text('Appearance'), findsOneWidget);
          expect(find.text('Custom Fields'), findsOneWidget);
        },
      );

      testWidgets(
        'About tile shows app name and version',
        (tester) async {
          await tester.pumpWidget(
            _buildApp(
              navigatedRoutes: [],
              appName: 'Swaralipi',
              version: '2.0.0',
              buildNumber: '10',
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('About'), findsOneWidget);
          expect(find.textContaining('2.0.0'), findsOneWidget);
        },
      );
    });

    group('navigation tile routing', () {
      testWidgets(
        'tapping Tags tile navigates to /settings/tags',
        (tester) async {
          final routes = <String>[];
          await tester.pumpWidget(_buildApp(navigatedRoutes: routes));
          await tester.pumpAndSettle();

          await tester.tap(find.text('Tags'));
          await tester.pumpAndSettle();

          expect(routes, contains('/settings/tags'));
        },
      );

      testWidgets(
        'tapping Instruments tile navigates to /settings/instruments',
        (tester) async {
          final routes = <String>[];
          await tester.pumpWidget(_buildApp(navigatedRoutes: routes));
          await tester.pumpAndSettle();

          await tester.tap(find.text('Instruments'));
          await tester.pumpAndSettle();

          expect(routes, contains('/settings/instruments'));
        },
      );

      testWidgets(
        'tapping Trash tile navigates to /settings/trash',
        (tester) async {
          final routes = <String>[];
          await tester.pumpWidget(_buildApp(navigatedRoutes: routes));
          await tester.pumpAndSettle();

          await tester.tap(find.text('Trash'));
          await tester.pumpAndSettle();

          expect(routes, contains('/settings/trash'));
        },
      );

      testWidgets(
        'tapping Appearance tile navigates to /settings/appearance',
        (tester) async {
          final routes = <String>[];
          await tester.pumpWidget(_buildApp(navigatedRoutes: routes));
          await tester.pumpAndSettle();

          await tester.tap(find.text('Appearance'));
          await tester.pumpAndSettle();

          expect(routes, contains('/settings/appearance'));
        },
      );

      testWidgets(
        'tapping Custom Fields tile navigates to /settings/custom-fields',
        (tester) async {
          final routes = <String>[];
          await tester.pumpWidget(_buildApp(navigatedRoutes: routes));
          await tester.pumpAndSettle();

          await tester.tap(find.text('Custom Fields'));
          await tester.pumpAndSettle();

          expect(routes, contains('/settings/custom-fields'));
        },
      );
    });
  });
}
