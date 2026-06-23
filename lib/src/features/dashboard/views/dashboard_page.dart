import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_strings.dart';
import '../models/tenant_dashboard_summary.dart';
import '../providers/tenant_dashboard_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(tenantDashboardSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.dashboardTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: summaryAsync.when(
          data: (summary) => _buildSummary(context, summary),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Unable to load dashboard: $error')),
        ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context, TenantDashboardSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Tenant dashboard',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text('Sales, inventory, and branch performance at a glance.'),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _statCard('Branches', summary.totalBranches.toString()),
            _statCard('Products', summary.totalProducts.toString()),
            _statCard('Sales', summary.totalSales.toString()),
            _statCard('Monthly revenue', '\$${summary.monthlyRevenue.toStringAsFixed(2)}'),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String title, String value) {
    return SizedBox(
      width: 180,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 12),
              Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
