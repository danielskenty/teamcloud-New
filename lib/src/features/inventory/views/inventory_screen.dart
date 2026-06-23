import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/inventory_provider.dart';

class InventoryScreen extends ConsumerWidget {
  final String tenantId;

  const InventoryScreen({
    required this.tenantId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryStreamProvider(tenantId));
    final lowStockAsync = ref.watch(lowStockInventoryProvider(tenantId));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inventory'),
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'All Stock'),
              Tab(text: 'Low Stock'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildInventoryList(context, ref, inventoryAsync),
            _buildInventoryList(context, ref, lowStockAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryList(
    BuildContext context,
    WidgetRef ref,
    AsyncValue asyncValue,
  ) {
    return asyncValue.when(
      data: (inventory) {
        if (inventory.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warehouse_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No inventory items',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: inventory.length,
          itemBuilder: (context, index) {
            final item = inventory[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text('Product: ${item.productId}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('Total: ${item.quantity} | Available: ${item.available} | Reserved: ${item.reserved}'),
                    const SizedBox(height: 4),
                    Text('Last Restocked: ${item.lastRestocked.toString().split('.')[0]}'),
                  ],
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Inventory detail coming soon')),
                  );
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
