import '../../../core/models/product_model.dart';
import '../../../core/services/firebase_paths.dart';
import '../../../core/services/firebase_service.dart';


class ProductRepository {
  final _db = FirebaseService.I.db;


  Stream<List<ProductModel>> watch(String sellerId) => _db
      .collection(FirebasePaths.productsCol(sellerId))
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => ProductModel.fromMap(d.id, d.data())).toList());


  Future<void> create(ProductModel m) async {
    await _db.collection(FirebasePaths.productsCol(m.sellerId)).doc(m.id).set(m.toMap());
  }

  Future<void> update(ProductModel m) async {
    await _db.collection(FirebasePaths.productsCol(m.sellerId)).doc(m.id).update(m.toMap());
  }

  Future<void> updateActive(String sellerId, String id, bool active) async {
    await _db.collection(FirebasePaths.productsCol(sellerId)).doc(id).update({'isActive': active});
  }


  Future<void> remove(String sellerId, String id) async {
    await _db.collection(FirebasePaths.productsCol(sellerId)).doc(id).delete();
  }
}