import '../../../core/models/category_model.dart';
import '../../../core/services/firebase_paths.dart';
import '../../../core/services/firebase_service.dart';

class CategoryRepository {
  final _db = FirebaseService.I.db;
  Stream<List<CategoryModel>> watchActive() => _db
      .collection(FirebasePaths.categories)
      .where('active', isEqualTo: true)
      .snapshots()
      .map((s) => s.docs.map((d) => CategoryModel.fromMap(d.id, d.data())).toList());
}