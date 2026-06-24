import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _teamcloudLogoAsset = 'assets/marketing/teamcloud-logo.png';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key, required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return ErrorScaffold(
      code: '404',
      title: 'Page not found',
      message: 'The page you are looking for does not exist or may have moved.',
      detail: location.isEmpty ? null : location,
      primaryLabel: 'Go home',
      primaryPath: '/',
      secondaryLabel: 'Login',
      secondaryPath: '/login',
    );
  }
}

class ForbiddenPage extends StatelessWidget {
  const ForbiddenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ErrorScaffold(
      code: '403',
      title: 'Access denied',
      message: 'You do not have permission to access this section.',
      primaryLabel: 'Go to dashboard',
      primaryPath: '/dashboard',
      secondaryLabel: 'Go home',
      secondaryPath: '/',
    );
  }
}

class RouteErrorPage extends StatelessWidget {
  const RouteErrorPage({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ErrorScaffold(
      code: '500',
      title: 'Something went wrong',
      message: 'TeamCloud could not open this page.',
      detail: message,
      primaryLabel: 'Go home',
      primaryPath: '/',
      secondaryLabel: 'Contact support',
      secondaryPath: '/contact',
    );
  }
}

class ErrorScaffold extends StatelessWidget {
  const ErrorScaffold({
    super.key,
    required this.code,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.primaryPath,
    this.secondaryLabel,
    this.secondaryPath,
    this.detail,
  });

  final String code;
  final String title;
  final String message;
  final String primaryLabel;
  final String primaryPath;
  final String? secondaryLabel;
  final String? secondaryPath;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    _teamcloudLogoAsset,
                    width: 86,
                    height: 86,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    code,
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: const Color(0xFF0F52BA),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                  if (detail != null && detail!.trim().isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        detail!,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: () => context.go(primaryPath),
                        icon: const Icon(Icons.home),
                        label: Text(primaryLabel),
                      ),
                      if (secondaryLabel != null && secondaryPath != null)
                        OutlinedButton.icon(
                          onPressed: () => context.go(secondaryPath!),
                          icon: const Icon(Icons.arrow_forward),
                          label: Text(secondaryLabel!),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
