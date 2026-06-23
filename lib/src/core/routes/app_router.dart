import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/branches/views/branches_page.dart';
import '../../features/auth/views/login_page.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/dashboard/views/dashboard_page.dart';
import '../../features/admin/views/admin_home_page.dart';
import '../../features/products/views/product_list_screen.dart';
import '../../features/inventory/views/inventory_screen.dart';
import '../../features/customers/views/customer_list_screen.dart';
import '../../features/pos/views/checkout_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final authListenable = ref.watch(authStateListenableProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final user = authState.asData?.value;
      final loggingIn = state.uri.toString() == '/login';

      if (user == null && !loggingIn) {
        return '/login';
      }
      if (user != null && loggingIn) {
        return '/';
      }
      return null;
    },
    routes: <GoRoute>[
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
        path: '/',
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
