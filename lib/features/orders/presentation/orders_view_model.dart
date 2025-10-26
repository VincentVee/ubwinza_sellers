import 'package:flutter/foundation.dart';
import '../../orders/data/order_repository.dart';
import '../../../core/models/order_model.dart';

class OrdersViewModel extends ChangeNotifier {
  final String sellerId;
  final bool history; // false -> new, true -> history
  OrdersViewModel({required this.sellerId, required this.history});

  final repo = OrderRepository();
  late final Stream<List<OrderModel>> stream =
  history ? repo.watchHistory(sellerId) : repo.watchNew(sellerId);

  Future<void> acceptOrder(String id) => repo.setStatus(id, 'accepted');
  Future<void> markPreparing(String id) => repo.setStatus(id, 'preparing');
  Future<void> markReady(String id) => repo.setStatus(id, 'ready');
  Future<void> cancelOrder(String id) => repo.setStatus(id, 'cancelled');
}
