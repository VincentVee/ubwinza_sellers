import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ubwinza_sellers/features/products/presentation/addon_form.dart';
import 'package:ubwinza_sellers/features/products/presentation/size_form.dart';
import '../../categories/presentation/category_picker.dart';
import '../../../core/models/category_model.dart';
import 'product_view_model.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key});
  @override State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController(); 
  final priceCtrl = TextEditingController();
  final stockCtrl = TextEditingController(text: '1');
  final prepTimeCtrl = TextEditingController();
  String? categoryId; CategoryModel? category;
  final images = <Uint8List>[];
  final _picker = ImagePicker();
  
  // New fields
 List<Map<String, dynamic>> sizes = [];   
 List<Map<String, dynamic>> addons = []; 
    final List<String> variations = [];

  Future<void> _pickFromGallery() async {
    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isNotEmpty) {
      final bytesList = await Future.wait(picked.map((x) => x.readAsBytes()));
      setState(() => images.addAll(bytesList));
    }
  }

  Future<void> _captureFromCamera() async {
    final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (x != null) {
      final bytes = await x.readAsBytes();
      setState(() => images.add(bytes));
    }
  }

  // Helper method to show add item popup
  Future<void> _showAddItemDialog({
    required String title,
    required String hintText,
    required List<String> list,
    required Function(String) onAdd,
  }) async {
    final textCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2B7B),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: TextFormField(
          controller: textCtrl,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.white),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
          style: const TextStyle(color: Colors.white),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:  Colors.green,
            ),
            onPressed: () {
              final text = textCtrl.text.trim();
              if (text.isNotEmpty) {
                onAdd(text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Widget for list management
  Widget _buildListSection({
    required String title,
    required List<String> items,
    required VoidCallback onAdd,
    required Function(int) onDelete,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (int i = 0; i < items.length; i++)
              Chip(
                label: Text(items[i], style: const TextStyle(color: Colors.white)),
                backgroundColor: const Color(0xFF1A2B7B),
                deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white),
                onDeleted: () => onDelete(i),
              ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            backgroundColor: const Color(0xFF1A2B7B),
            side: const BorderSide(color: Color(0xFF1A2B7B)),
          ),
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 16, color: Colors.white),
          label: const Text('Add', style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

Future<void> _showAddonDialog(Map<String, dynamic>? existingAddon) async {
  await showDialog(
    context: context,
    builder: (context) => AddonForm(
      existingAddon: existingAddon,
      onSave: (addon) {
        setState(() {
          if (existingAddon != null) {
            // Find and update existing addon
            final index = addons.indexWhere((a) => a['id'] == existingAddon['id']);
            if (index != -1) {
              addons[index] = addon;
            }
          } else {
            // Add new addon
            addons.add(addon);
          }
        });
      },
    ),
  );
}

List<Map<String, dynamic>> _convertSizesToMap(List<dynamic> sizesList) {
    return sizesList.map((item) {
      if (item is Map<String, dynamic>) {
        // Already in new format
        return {
          'id': item['id'] ?? item['name']?.toString().toLowerCase().replaceAll(' ', '_') ?? 'size_${DateTime.now().millisecondsSinceEpoch}',
          'name': item['name'] ?? 'Unnamed Size',
          'description': item['description'] ?? '',
          'priceModifier': (item['priceModifier'] is num) ? (item['priceModifier'] as num).toDouble() : 0.0,
          'inStock': item['inStock'] ?? true,
        };
      } else if (item is String) {
        // Convert old string format to new map format
        return {
          'id': item.toLowerCase().replaceAll(' ', '_'),
          'name': item,
          'description': '',
          'priceModifier': 0.0,
          'inStock': true,
        };
      }
      // Fallback
      return {
        'id': 'size_${DateTime.now().millisecondsSinceEpoch}',
        'name': 'Unnamed Size',
        'description': '',
        'priceModifier': 0.0,
        'inStock': true,
      };
    }).toList();
  }

void _showAddonsList() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('All Add-ons', style: TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF1A2B7B),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: addons.length,
          itemBuilder: (context, index) {
            final addon = addons[index];
            return Card(
              color: Colors.white,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: Text(
                  addon['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(addon['description']),
                    Text(
                      'K${addon['price']?.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      addon['inStock'] ? 'In Stock' : 'Out of Stock',
                      style: TextStyle(
                        color: addon['inStock'] ? Colors.green : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () {
                        Navigator.pop(context);
                        _showAddonDialog(addon);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                      onPressed: () {
                        setState(() => addons.removeAt(index));
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

Future<void> _showSizeDialog(Map<String, dynamic>? existingSize) async {
  await showDialog(
    context: context,
    builder: (context) => SizeForm(
      existingSize: existingSize,
      onSave: (size) {
        setState(() {
          if (existingSize != null) {
            // Find and update existing size
            final index = sizes.indexWhere((s) => s['id'] == existingSize['id']);
            if (index != -1) {
              sizes[index] = size;
            }
          } else {
            // Add new size
            sizes.add(size);
          }
        });
      },
    ),
  );
}

void _showSizesList() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('All Sizes', style: TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF1A2B7B),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: sizes.length,
          itemBuilder: (context, index) {
            final size = sizes[index];
            return Card(
              color: Colors.white,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: Text(
                  size['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(size['description']),
                    Text(
                      'Price Modifier: K${size['priceModifier'] >= 0 ? '+' : ''}${size['priceModifier']?.toStringAsFixed(2) ?? '0.00'}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: size['priceModifier'] >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                    Text(
                      size['inStock'] ? 'In Stock' : 'Out of Stock',
                      style: TextStyle(
                        color: size['inStock'] ? Colors.green : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () {
                        Navigator.pop(context);
                        _showSizeDialog(size);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                      onPressed: () {
                        setState(() => sizes.removeAt(index));
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProductViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A2B7B),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Product name',
                        labelStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        errorBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        errorStyle: TextStyle(color: Colors.red),
                      ),
                      style: const TextStyle(color: Colors.black),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        errorBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        errorStyle: TextStyle(color: Colors.red),
                      ),
                      style: const TextStyle(color: Colors.black),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          controller: priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Price',
                            labelStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                            errorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.red),
                            ),
                            focusedErrorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.red),
                            ),
                            errorStyle: TextStyle(color: Colors.red),
                          ),
                          style: const TextStyle(color: Colors.black),
                          validator: (v) => (v == null || double.tryParse(v) == null) ? 'Enter a number' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: stockCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Stock',
                            labelStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                            errorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.red),
                            ),
                            focusedErrorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.red),
                            ),
                            errorStyle: TextStyle(color: Colors.red),
                          ),
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
                          validator: (v) => (v == null || int.tryParse(v) == null) ? 'Enter an integer' : null,
                        ),
                      ),
                    ]),

                    const SizedBox(height: 12),
                    TextFormField(
                      controller: prepTimeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Preparation Time (minutes)',
                        labelStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
                        hintText: 'e.g., 30',
                        hintStyle: TextStyle(color: Colors.black54),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        errorBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        errorStyle: TextStyle(color: Colors.red),
                      ),
                      style: const TextStyle(color: Colors.black),
                    ),

                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: Text(
                          category == null ? 'No category selected' : 'Category: ${category!.name}',
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A2B7B),
                        ),
                        onPressed: () async {
                          final picked = await showDialog<CategoryModel>(
                            context: context,
                            builder: (_) => const CategoryPicker(),
                          );
                          if (picked != null) setState(() { category = picked; categoryId = picked.id; });
                        },
                        icon: const Icon(Icons.category, color: Colors.white), 
                        label: const Text('Pick Category', style: TextStyle(color: Colors.white)),
                      ),
                    ]),

                    const SizedBox(height: 16),
                    
                    // Sizes Section
                   Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const Text(
      'Sizes', 
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)
    ),
    const SizedBox(height: 8),
    if (sizes.isNotEmpty) ...[
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (int i = 0; i < sizes.length; i++)
            Chip(
              label: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sizes[i]['name'],
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Text(
                    'K${sizes[i]['priceModifier'] >= 0 ? '+' : ''}${sizes[i]['priceModifier']?.toStringAsFixed(2) ?? '0.00'}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF1A2B7B),
              deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white),
              onDeleted: () => setState(() => sizes.removeAt(i)),
            ),
        ],
      ),
      const SizedBox(height: 8),
    ],
    Row(
      children: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            backgroundColor: const Color(0xFF1A2B7B),
            side: const BorderSide(color: Color(0xFF1A2B7B)),
          ),
          onPressed: () => _showSizeDialog(null),
          icon: const Icon(Icons.add, size: 16, color: Colors.white),
          label: const Text('Add Size', style: TextStyle(color: Colors.white)),
        ),
        if (sizes.isNotEmpty) ...[
          const SizedBox(width: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange),
            ),
            onPressed: () => _showSizesList(),
            icon: const Icon(Icons.list, size: 16, color: Colors.white),
            label: const Text('View All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ],
    ),
    const SizedBox(height: 16),
  ],
),


                    // Add-ons Section  //////////////////////
                                
              // Add-ons Section
                        Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add-ons', 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)
                  ),
                  const SizedBox(height: 8),
                  if (addons.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (int i = 0; i < addons.length; i++)
                          Chip(
                            label: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  addons[i]['name'],
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                                Text(
                                  'K${addons[i]['price']?.toString() ?? '0.00'}',
                                  style: const TextStyle(color: Colors.white, fontSize: 10),
                                ),
                              ],
                            ),
                            backgroundColor: const Color(0xFF1A2B7B),
                            deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white),
                            onDeleted: () => setState(() => addons.removeAt(i)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A2B7B),
                          side: const BorderSide(color: Color(0xFF1A2B7B)),
                        ),
                        onPressed: () => _showAddonDialog(null),
                        icon: const Icon(Icons.add, size: 16, color: Colors.white),
                        label: const Text('Add Add-on', style: TextStyle(color: Colors.white)),
                      ),
                      if (addons.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                          ),
                          onPressed: () => _showAddonsList(),
                          icon: const Icon(Icons.list, size: 16, color: Colors.white),
                          label: const Text('View All', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),

              // Add these methods to the ProductFormScreen class:


                  ///////////// add on /////////////////

                    // Variations Section
                    _buildListSection(
                      title: 'Variations',
                      items: variations,
                      onAdd: () => _showAddItemDialog(
                        title: 'Add Variation',
                        hintText: 'e.g., Color: Red, Material: Cotton',
                        list: variations,
                        onAdd: (variation) => setState(() => variations.add(variation)),
                      ),
                      onDelete: (index) => setState(() => variations.removeAt(index)),
                    ),

                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Images', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          for (final bytes in images)
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(bytes, width: 100, height: 100, fit: BoxFit.cover),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => setState(() => images.remove(bytes)),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          Row(children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A2B7B),
                                side: const BorderSide(color: Color(0xFF1A2B7B)),
                              ),
                              onPressed: _pickFromGallery, 
                              icon: const Icon(Icons.photo_library, color: Colors.white), 
                              label: const Text('Gallery', style: TextStyle(color: Colors.white)),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A2B7B),
                                side: const BorderSide(color: Color(0xFF1A2B7B)),
                              ),
                              onPressed: _captureFromCamera, 
                              icon: const Icon(Icons.photo_camera, color: Colors.white), 
                              label: const Text('Camera', style: TextStyle(color: Colors.white)),
                            ),
                          ]),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 80), // Extra space for the fixed button
                  ],
                ),
              ),
            ),
          ),
          // Fixed Save Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color:  Color(0xFFB8B4B4),
              border: Border(
                top: BorderSide(color: Colors.black, width: 1.0),
              ),
            ),
            child: SafeArea(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A2B7B),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: vm.busy ? null : () async {
                  if (!_formKey.currentState!.validate()) return;
                  if (categoryId == null) { 
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pick a category'))); 
                    return; 
                  }
                  if (images.isEmpty) { 
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least 1 image'))); 
                    return; 
                  }
                  
                  await vm.create(
                    name: nameCtrl.text,
                    description: descCtrl.text,
                    categoryId: categoryId!,
                    price: num.parse(priceCtrl.text),
                    stock: int.parse(stockCtrl.text),
                    imageBytes: images,
                    sizes: sizes.isNotEmpty ? sizes : null,
                    addons: addons.isNotEmpty ? addons : null,
                    variations: variations.isNotEmpty ? variations : null,
                    prepTimeMinutes: prepTimeCtrl.text.isNotEmpty ? int.parse(prepTimeCtrl.text) : null,
                  );
                  
                  if (!mounted) return;
                  if (vm.error == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product created')));
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.error!)));
                  }
                },
                icon: const Icon(Icons.save, color: Colors.white), 
                label: Text(
                  vm.busy ? 'Saving…' : 'Save Product', 
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}