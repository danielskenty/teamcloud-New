import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../products/providers/product_provider.dart';
import '../../products/models/product.dart';
import '../../sales/models/sale.dart';
import '../../sales/providers/sale_provider.dart';
// Payment provider injected from providers; concrete implementations in payment module
import '../providers/cart_provider.dart';
import '../providers/payment_state_provider.dart';
import '../../sales/receipt_generator.dart';

class CheckoutScreen extends ConsumerWidget {
  final String tenantId;
  final String branchId;
  final String cashierId;

  const CheckoutScreen({
    required this.tenantId,
    required this.branchId,
    required this.cashierId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsStreamProvider(tenantId));
    final cartNotifier = ref.read(cartProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Column(
        children: [
          Expanded(
            child: productsAsync.when(
              data: (products) => _buildProductGrid(context, products, cartNotifier),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
          _buildCartSummary(context, ref),
        ],
      ),
    );
  }

  Widget _buildProductGrid(BuildContext context, List<Product> products, CartNotifier cart) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final p = products[index];
        return GestureDetector(
          onTap: () => cart.addProduct(p, qty: 1),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: p.imageUrl != null
                        ? Image.network(p.imageUrl!, fit: BoxFit.cover)
                        : Icon(Icons.image, size: 48, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('\$${p.sellingPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCartSummary(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final saleRepo = ref.watch(saleRepositoryProvider);
    final paymentMethodState = ref.watch(paymentMethodProvider);
    final paymentClient = ref.read(paymentProvider);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              children: cart.items.map((it) {
                return ListTile(
                  title: Text(it.name),
                  subtitle: Text('Qty: ${it.quantity} | Unit: \$${it.unitPrice.toStringAsFixed(2)}'),
                  trailing: Text('\$${(it.unitPrice * it.quantity).toStringAsFixed(2)}'),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            // Payment method selector
            Row(
              children: [
                const Text('Payment: '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: paymentMethodState,
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'nomba', child: Text('Nomba')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(paymentMethodProvider.notifier).state = v;
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal', style: Theme.of(context).textTheme.bodyLarge),
                Text('\$${cart.subtotal.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tax (12%)'),
                Text('\$${cart.tax.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text('\$${cart.total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: cart.items.isEmpty
                        ? null
                        : () async {
                            // Process payment via selected provider
                            // Create a deterministic reference for the payment and sale
                            final reference = FirebaseFirestore.instance.collection('tenants').doc().id;
                            final amountCents = (cart.total * 100).toInt();
                            final paymentResult = await paymentClient.processPayment(
                              amountCents: amountCents,
                              currency: 'USD',
                              reference: reference,
                              metadata: {
                                'tenantId': tenantId,
                                'branchId': branchId,
                                'cashierId': cashierId,
                              },
                            );

                            if (!paymentResult.success) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment failed: ${paymentResult.message}')));
                              }
                              return;
                            }

                            // Build Sale (record payment reference)
                            final id = FirebaseFirestore.instance.collection('tenants').doc().id;
                            final sale = Sale(
                              id: id,
                              tenantId: tenantId,
                              branchId: branchId,
                              cashierId: cashierId,
                              customerId: null,
                              items: cart.items.map((it) => SaleItem(
                                productId: it.productId,
                                productName: it.name,
                                unitPrice: it.unitPrice,
                                quantity: it.quantity,
                                discount: 0.0,
                                total: it.unitPrice * it.quantity,
                              )).toList(),
                              subtotal: cart.subtotal,
                              discount: 0.0,
                              tax: cart.tax,
                              total: cart.total,
                              paymentMethod: paymentMethodState,
                              status: 'completed',
                              paymentRef: reference,
                              notes: 'payment_ref:${paymentResult.transactionId ?? ''}',
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            );

                            try {
                              await saleRepo.createSale(tenantId, sale);
                              cartNotifier.clear();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sale created')));
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                              }
                            }
                            // Optionally generate and print receipt
                            try {
                              await ReceiptGenerator.printPdf(sale);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Receipt print error: $e')));
                              }
                            }
                          },
                    child: const Text('Pay & Complete Sale'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => cartNotifier.clear(),
                  child: const Text('Clear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
