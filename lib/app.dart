import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/core/providers/firebase_providers.dart';
import 'src/core/routes/app_router.dart';
import 'src/core/theme/app_theme.dart';

class TeamCloudApp extends ConsumerStatefulWidget {
  const TeamCloudApp({super.key});

  @override
  ConsumerState<TeamCloudApp> createState() => _TeamCloudAppState();
}

class _TeamCloudAppState extends ConsumerState<TeamCloudApp> {
  @override
  Widget build(BuildContext context) {
    final firebaseInitState = ref.watch(firebaseAppProvider);
    final router = ref.watch(appRouterProvider);

    return firebaseInitState.when(
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.themeData,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stackTrace) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.themeData,
        home: Scaffold(
          body: Center(
            child: Text('Unable to initialize Firebase:\n$error', textAlign: TextAlign.center),
          ),
        ),
      ),
      data: (_) => MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'TeamCloud Retail POS',
        theme: AppTheme.themeData,
        routerConfig: router,
        restorationScopeId: 'teamcloud_app',
      ),
    );
  }
}
