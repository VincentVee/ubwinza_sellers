
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/category_model.dart';
import '../data/category_repository.dart';

class CategoryPicker extends StatelessWidget {
  final String? selectedId;
  const CategoryPicker({super.key, this.selectedId});


  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (_) => CategoryRepository(),
      child: Dialog(
        backgroundColor: const Color(0xFF1A2B7B),
        child: SizedBox(
          width: 420,
          height: 520,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Category', style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Expanded(child: _List(selectedId: selectedId)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _List extends StatelessWidget {
  final String? selectedId;
  const _List({required this.selectedId});
  @override
  Widget build(BuildContext context) {
    final repo = context.read<CategoryRepository>();
    return StreamBuilder<List<CategoryModel>>(
      stream: repo.watchActive(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final items = snap.data!;
        return ListView.separated(
          itemBuilder: (_, i) {
            final c = items[i];
            final selected = c.id == selectedId;
            return ListTile(
              leading: c.imageUrl != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(c.imageUrl!, width: 40, height: 40, fit: BoxFit.cover))
                  : const Icon(Icons.category),
              title: Text(c.name),
              trailing: selected ? const Icon(Icons.check_circle, color: Colors.green) : null,
              onTap: () => Navigator.of(context).pop(c),
            );
          },
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemCount: items.length,
        );
      },
    );
  }
}