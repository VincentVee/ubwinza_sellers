import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ubwinza_sellers/features/products/presentation/product_update_screen.dart';
import '../../../core/models/product_model.dart';
import 'product_view_model.dart';
import 'product_form_screen.dart';

class ProductListScreen extends StatelessWidget {
  final String sellerId;
  const ProductListScreen({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProductViewModel(sellerId: sellerId),
      child: Scaffold(
        appBar: AppBar(title: const Text('My Products'),  backgroundColor:Color(0xFF1A2B7B),),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton.extended(
              backgroundColor:Color(0xFF1A2B7B),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: context.read<ProductViewModel>(),
                  child: const ProductFormScreen(),
                ),
              ),
            ),
            icon: const Icon(Icons.add), label: const Text('Add Product'),
          ),
        ),
        body: const _Body(),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();
  @override
  Widget build(BuildContext context) {
    final vm = context.read<ProductViewModel>();
    return StreamBuilder<List<ProductModel>>(
      stream: vm.stream,
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final items = snap.data!;
        if (items.isEmpty) return const Center(child: Text('No products yet'));
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemBuilder: (_, i) {
            final p = items[i];
            return Card(
              color: const Color.fromARGB(255, 216, 211, 211),
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row with image and basic info
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product image
                        p.images.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  p.images.first,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.inventory_2, color: Colors.grey),
                              ),
                        const SizedBox(width: 12),
                        // Product details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product name
                              Text(
                                p.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              // Price and stock
                              Text(
                                'K${p.price} · Stock: ${p.stock}',
                                style: const TextStyle(
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Type and subtype (category info)
                              Text(
                                'Category: ${p.categoryId}',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Additional info (sizes, addons, variations, prep time)
                              _buildAdditionalInfo(p),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Action buttons row - simplified layout
                    Row(
                      children: [
                        // Edit button - icon only
                        IconButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChangeNotifierProvider.value(
                                value: context.read<ProductViewModel>(),
                                child: ProductUpdateScreen(product: p),
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                          tooltip: 'Edit',
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                        const Spacer(),
                        // Active status with toggle
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              p.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                color: p.isActive ? Colors.green : Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                value: p.isActive,
                                onChanged: (v) => vm.toggleActive(p.id, v),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Delete button - icon only
                        IconButton(
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                backgroundColor: const Color(0xFF1A2B7B),
                                title: const Text('Delete product?'),
                                content: Text('This will remove "${p.name}"'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true) await vm.remove(p.id);
                          },
                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                          tooltip: 'Delete',
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemCount: items.length,
        );
      },
    );
  }

  Widget _buildAdditionalInfo(ProductModel product) {
    final List<String> info = [];
    
    // Add sizes if available
    if (product.sizes != null && product.sizes!.isNotEmpty) {
      info.add('Sizes: ${product.sizes!.join(', ')}');
    }
    
    // Add addons if available
    // if (product.addons != null && product.addons!.isNotEmpty) {
    //   info.add('Add-ons: ${product.addons!.join(', ')}');
    // }
    
    // Add variations if available
    // if (product.variations != null && product.variations!.isNotEmpty) {
    //   info.add('Variations: ${product.variations!.join(', ')}');
    // }
    
    // Add prep time if available
    if (product.prepTimeMinutes != null && product.prepTimeMinutes! > 0) {
      info.add('Prep: ${product.prepTimeMinutes}min');
    }
    
    if (info.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Text(
      info.join(' · '),
      style: const TextStyle(
        color: Colors.black54,
        fontSize: 11,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}