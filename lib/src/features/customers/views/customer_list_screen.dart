import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer.dart';
import '../providers/customer_provider.dart';
import 'customer_form.dart';

class CustomerListScreen extends ConsumerWidget {
  final String tenantId;

  const CustomerListScreen({
    required this.tenantId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(activeCustomersProvider(tenantId));
    final topCustomersAsync = ref.watch(topCustomersProvider(tenantId));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Customers'),
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'All Customers'),
              Tab(text: 'Top Customers'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCustomerList(context, customersAsync),
            _buildCustomerList(context, topCustomersAsync),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => CustomerFormModal(
                tenantId: tenantId,
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildCustomerList(BuildContext context, AsyncValue asyncValue) {
    return asyncValue.when(
      data: (customers) {
        if (customers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No customers yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: customers.length,
          itemBuilder: (context, index) {
            final customer = customers[index];
            return _CustomerCard(
              customer: customer,
              tenantId: tenantId,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}

class _CustomerCard extends ConsumerWidget {
  final Customer customer;
  final String tenantId;

  const _CustomerCard({
    required this.customer,
    required this.tenantId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              child: Text(customer.name[0].toUpperCase()),
            ),
            title: Text(customer.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(customer.email),
                const SizedBox(height: 4),
                Text('Total Spent: \$${customer.totalSpent.toStringAsFixed(2)}'),
              ],
            ),
            trailing: Chip(
              label: Text('${customer.loyaltyPoints.toInt()} pts'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => CustomerFormModal(
                        tenantId: tenantId,
                        initialCustomer: customer,
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _showDeleteConfirm(context, ref),
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  label: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Delete "${customer.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final repo = ref.read(customerRepositoryProvider);
                await repo.deleteCustomer(tenantId, customer.id);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Customer deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
