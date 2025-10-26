import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/firebase_paths.dart';
import '../../../core/services/storage_service.dart';
import '../data/product_repository.dart';

class ProductViewModel extends ChangeNotifier {
  final String sellerId;
  ProductViewModel({required this.sellerId});

  final repo = ProductRepository();
  late final Stream<List<ProductModel>> stream = repo.watch(sellerId);
  bool busy = false; String? error;

 Future<void> create({
  required String name,
  required String description,
  required String categoryId,
  required num price,
  required int stock,
  required List<Uint8List> imageBytes,
List<Map<String, dynamic>>? sizes,  
final List<Map<String, dynamic>>? addons,
  List<String>? variations,
  int? prepTimeMinutes,
}) async {
  try {
    busy = true; error = null; notifyListeners();
  
    
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final urls = <String>[];
    
    for (int i = 0; i < imageBytes.length; i++) {
      final path = FirebasePaths.productImagePath(sellerId, id, i);
      final url = await StorageService.I.upload(path, imageBytes[i]);
      urls.add(url);
    }
    
    final m = ProductModel(
      id: id,
      sellerId: sellerId,
      name: name.trim(),
      description: description.trim(),
      categoryId: categoryId,
      price: price,
      stock: stock,
      images: urls,
      sizes: sizes,
      addons: addons,
      variations: variations,
      prepTimeMinutes: prepTimeMinutes,
      isActive: true,
      createdAt: DateTime.now(),
    );
    
    await repo.create(m);
    
  } catch (e) { 
    error = e.toString(); 
 
  } finally { 
    busy = false; 
    notifyListeners(); 
  }
}

  Future<void> update({
    required ProductModel original,
    String? name,
    String? description,
    String? categoryId,
    num? price,
    int? stock,
    List<Uint8List>? newImages, // optional; if provided, they will be appended
    List<String>? keepImages, // existing URLs to keep (enables deletion of some)
    List<Map<String, dynamic>>? sizes,  
    final List<Map<String, dynamic>>? addons,
    List<String>? variations,
    int? prepTimeMinutes,
  }) async {
    try {
      busy = true;
      error = null;
      notifyListeners();
      final id = original.id;
      final nextImages = <String>[];
      if (keepImages != null) {
        nextImages.addAll(keepImages);
      } else {
        nextImages.addAll(original.images);
      }
      // upload any new images and append
      if (newImages != null && newImages.isNotEmpty) {
        final startIndex = nextImages.length;
        for (int i = 0; i < newImages.length; i++) {
          final path = FirebasePaths.productImagePath(sellerId, id, startIndex + i);
          final url = await StorageService.I.upload(path, newImages[i]);
          nextImages.add(url);
        }
      }
      final updated = ProductModel(
        id: id,
        sellerId: sellerId,
        name: (name ?? original.name).trim(),
        description: (description ?? original.description).trim(),
        categoryId: categoryId ?? original.categoryId,
        price: price ?? original.price,
        stock: stock ?? original.stock,
        images: nextImages,
        sizes: sizes ?? original.sizes,
        addons: addons ?? original.addons,
        variations: variations ?? original.variations,
        prepTimeMinutes: prepTimeMinutes ?? original.prepTimeMinutes,
        isActive: original.isActive,
        createdAt: original.createdAt,
      );
      await repo.update(updated);
    } catch (e) {
      error = e.toString();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> toggleActive(String id, bool active) => repo.updateActive(sellerId, id, active);
  Future<void> remove(String id) => repo.remove(sellerId, id);
}