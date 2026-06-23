import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';

class ProductFormModal extends ConsumerStatefulWidget {
  final String tenantId;
  final String categoryId;
  final Product? initialProduct;

  const ProductFormModal({
    required this.tenantId,
    required this.categoryId,
    this.initialProduct,
    super.key,
  });

  @override
  ConsumerState<ProductFormModal> createState() => _ProductFormModalState();
}

class _ProductFormModalState extends ConsumerState<ProductFormModal> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _skuController;
  late TextEditingController _barcodeController;
  late TextEditingController _costPriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _quantityController;
  late TextEditingController _reorderLevelController;

  late String _selectedUnit;
  late bool _isActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final product = widget.initialProduct;
    _nameController = TextEditingController(text: product?.name ?? '');
    _descriptionController = TextEditingController(text: product?.description ?? '');
    _skuController = TextEditingController(text: product?.sku ?? '');
    _barcodeController = TextEditingController(text: product?.barcode ?? '');
    _costPriceController = TextEditingController(text: product?.costPrice.toString() ?? '');
    _sellingPriceController = TextEditingController(text: product?.sellingPrice.toString() ?? '');
    _quantityController = TextEditingController(text: product?.quantity.toString() ?? '0');
    _reorderLevelController = TextEditingController(text: product?.reorderLevel.toString() ?? '10');
    _selectedUnit = product?.unit ?? 'pcs';
    _isActive = product?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _quantityController.dispose();
    _reorderLevelController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (_nameController.text.isEmpty || _skuController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and SKU are required')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(productRepositoryProvider);
      final now = DateTime.now();
      final product = (widget.initialProduct ?? Product(
        id: FirebaseFirestore.instance.collection('tenants').doc().id,
        tenantId: widget.tenantId,
        name: '',
        description: '',
        sku: '',
        barcode: '',
        costPrice: 0,
        sellingPrice: 0,
        categoryId: widget.categoryId,
        quantity: 0,
        reorderLevel: 10,
        unit: 'pcs',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      )).copyWith(
        name: _nameController.text,
        description: _descriptionController.text,
        sku: _skuController.text,
        barcode: _barcodeController.text,
        costPrice: double.tryParse(_costPriceController.text) ?? 0,
        sellingPrice: double.tryParse(_sellingPriceController.text) ?? 0,
        quantity: int.tryParse(_quantityController.text) ?? 0,
        reorderLevel: int.tryParse(_reorderLevelController.text) ?? 10,
        unit: _selectedUnit,
        isActive: _isActive,
        updatedAt: now,
      );

      if (widget.initialProduct == null) {
        await repo.createProduct(widget.tenantId, product);
      } else {
        await repo.updateProduct(widget.tenantId, product);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.initialProduct == null ? 'Product created' : 'Product updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.initialProduct == null ? 'Add Product' : 'Edit Product',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Product Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _skuController,
                      decoration: InputDecoration(
                        labelText: 'SKU *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _barcodeController,
                      decoration: InputDecoration(
                        labelText: 'Barcode',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _costPriceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Cost Price',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _sellingPriceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Selling Price',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _reorderLevelController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Reorder Level',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedUnit,
                      items: ['pcs', 'box', 'bag', 'carton', 'dozen']
                          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedUnit = v ?? 'pcs'),
                      decoration: InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CheckboxListTile(
                      title: const Text('Active'),
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v ?? true),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveProduct,
                    child: _isSaving
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
