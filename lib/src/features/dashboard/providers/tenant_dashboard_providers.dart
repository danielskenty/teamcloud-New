import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tenant_dashboard_summary.dart';
import '../repositories/tenant_repository.dart';

final tenantRepositoryProvider = Provider<TenantRepository>((ref) {
  return TenantRepository();
});

final tenantDashboardSummaryProvider =
    FutureProvider.family<TenantDashboardSummary, String>((
      ref,
      tenantId,
    ) async {
      final repository = ref.watch(tenantRepositoryProvider);

      final branchesSnapshot = await repository.branchesRef(tenantId).get();
      final productsSnapshot = await repository.productsRef(tenantId).get();
      final salesSnapshot = await repository.salesRef(tenantId).get();

      // Placeholder calculations for summary.
      return TenantDashboardSummary(
        totalBranches: branchesSnapshot.docs.length,
        totalProducts: productsSnapshot.docs.length,
        totalSales: salesSnapshot.docs.length,
        monthlyRevenue: 0.0,
      );
    });
