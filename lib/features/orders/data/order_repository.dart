import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/order_model.dart';
import '../../../core/services/firebase_paths.dart';

class OrderRepository {
  final _db = FirebaseFirestore.instance;

  Stream<List<OrderModel>> watchNew(String sellerId) => _db
      .collection(FirebasePaths.orders)
      .where('sellerId', isEqualTo: sellerId)
      .where('status', whereIn: ['new', 'accepted', 'preparing', 'ready'])
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => OrderModel.fromMap(d.id, d.data())).toList());

  Stream<List<OrderModel>> watchHistory(String sellerId) => _db
      .collection(FirebasePaths.orders)
      .where('sellerId', isEqualTo: sellerId)
      .where('status', whereIn: ['delivered', 'cancelled'])
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => OrderModel.fromMap(d.id, d.data())).toList());

  Future<void> setStatus(String id, String status) async {
    await _db.collection(FirebasePaths.orders).doc(id).update({'status': status});
  }
}
