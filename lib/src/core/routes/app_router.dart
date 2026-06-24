import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/branches/views/branches_page.dart';
import '../../features/auth/views/login_page.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../providers/tenant_context_provider.dart';
import '../../features/dashboard/views/dashboard_page.dart';
import '../../features/admin/views/admin_home_page.dart';
import '../../features/products/views/product_list_screen.dart';
import '../../features/inventory/views/inventory_screen.dart';
import '../../features/customers/views/customer_list_screen.dart';
import '../../features/pos/views/checkout_screen.dart';
import '../../features/marketing/views/error_pages.dart';
import '../../features/marketing/views/marketing_pages.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final authListenable = ref.watch(authStateListenableProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authListenable,
    errorBuilder: (context, state) {
      final error = state.error;
      if (error == null) {
        return NotFoundPage(location: state.uri.toString());
      }
      return RouteErrorPage(message: error.toString());
    },
    redirect: (context, state) async {
      final user = authState.asData?.value;
      final location = state.uri.path;
      final loggingIn = location == '/login';
      final forbidden = location == '/forbidden';
      final publicRoute = _isPublicRoute(location);

      if (authState.isLoading) {
        return null;
      }

      if (user == null && !publicRoute) {
        return '/login';
      }
      if (user != null && loggingIn) {
        return '/dashboard';
      }
      if (user == null || forbidden) {
        return null;
      }

      final tenantContext = await ref.read(tenantContextProvider.future);

      if (location == '/admin' && tenantContext?.isPlatformAdmin != true) {
        return '/forbidden';
      }

      if (_isTenantRoute(location) &&
          (tenantContext == null ||
              !tenantContext.hasTenant ||
              !_canAccessTenantRoute(location, tenantContext.role))) {
        return '/forbidden';
      }

      final requestedTenantId = _requestedTenantId(state.extra);
      if (requestedTenantId != null &&
          requestedTenantId != tenantContext?.tenantId) {
        return '/forbidden';
      }

      return null;
    },
    routes: <GoRoute>[
      GoRoute(
        path: '/',
        name: 'landing',
        builder: (context, state) => const LandingPage(),
      ),
      GoRoute(
        path: '/pricing',
        name: 'pricing',
        builder: (context, state) => const PricingPage(),
      ),
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => const AboutPage(),
      ),
      GoRoute(
        path: '/contact',
        name: 'contact',
        builder: (context, state) => const ContactPage(),
      ),
      GoRoute(
        path: '/legal',
        name: 'legal',
        builder: (context, state) => const LegalPage(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) =>
            SignupPage(initialPlan: state.uri.queryParameters['plan']),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) => const AdminHomePage(),
      ),
      GoRoute(
        path: '/forbidden',
        name: 'forbidden',
        builder: (context, state) => const ForbiddenPage(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/branches',
        name: 'branches',
        builder: (context, state) => const BranchesPage(),
      ),
      GoRoute(
        path: '/products',
        name: 'products',
        builder: (context, state) {
          final extra = state.extra as Map<String, String>?;
          if (extra == null || !extra.containsKey('tenantId')) {
            return const Scaffold(
              body: Center(child: Text('Missing tenant ID')),
            );
          }
          final categoryId = extra['categoryId'] ?? 'default';
          return ProductListScreen(
            tenantId: extra['tenantId']!,
            categoryId: categoryId,
          );
        },
      ),
      GoRoute(
        path: '/inventory',
        name: 'inventory',
        builder: (context, state) {
          final tenantId = state.extra as String?;
          if (tenantId == null) {
            return const Scaffold(
              body: Center(child: Text('Missing tenant ID')),
            );
          }
          return InventoryScreen(tenantId: tenantId);
        },
      ),
      GoRoute(
        path: '/customers',
        name: 'customers',
        builder: (context, state) {
          final tenantId = state.extra as String?;
          if (tenantId == null) {
            return const Scaffold(
              body: Center(child: Text('Missing tenant ID')),
            );
          }
          return CustomerListScreen(tenantId: tenantId);
        },
      ),
      GoRoute(
        path: '/checkout',
        name: 'checkout',
        builder: (context, state) {
          // Expecting extra to be a map {tenantId, branchId, cashierId}
          final extra = state.extra as Map<String, String>?;
          if (extra == null || !extra.containsKey('tenantId')) {
            return const Scaffold(
              body: Center(child: Text('Missing checkout parameters')),
            );
          }
          return CheckoutScreen(
            tenantId: extra['tenantId']!,
            branchId: extra['branchId'] ?? '',
            cashierId: extra['cashierId'] ?? '',
          );
        },
      ),
    ],
  );
});

bool _isPublicRoute(String location) {
  return location == '/' ||
      location == '/pricing' ||
      location == '/about' ||
      location == '/contact' ||
      location == '/legal' ||
      location == '/signup' ||
      location == '/login' ||
      location == '/forbidden';
}

bool _isTenantRoute(String location) {
  return location == '/dashboard' ||
      location == '/branches' ||
      location == '/products' ||
      location == '/inventory' ||
      location == '/customers' ||
      location == '/checkout';
}

bool _canAccessTenantRoute(String location, String? role) {
  if (role == null) {
    return false;
  }

  const tenantAdmins = {'business_owner', 'branch_manager'};

  final allowedRoles = switch (location) {
    '/dashboard' => {
      ...tenantAdmins,
      'cashier',
      'inventory_officer',
      'accountant',
      'sales_staff',
    },
    '/branches' => tenantAdmins,
    '/products' => {...tenantAdmins, 'inventory_officer'},
    '/inventory' => {...tenantAdmins, 'inventory_officer'},
    '/customers' => {...tenantAdmins, 'cashier', 'sales_staff'},
    '/checkout' => {...tenantAdmins, 'cashier', 'sales_staff'},
    _ => <String>{},
  };

  return allowedRoles.contains(role);
}

String? _requestedTenantId(Object? extra) {
  if (extra is String && extra.isNotEmpty) {
    return extra;
  }
  if (extra is Map<String, String>) {
    return extra['tenantId'];
  }
  return null;
}
