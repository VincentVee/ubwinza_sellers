import 'order_item_model.dart';

class OrderModel {
  final String id;
  final String sellerId;
  final String userId;
  final String? riderId;
  final String status; // new, accepted, preparing, ready, out_for_delivery, delivered, cancelled
  final num subtotal;
  final num deliveryFee;
  final num total;
  final DateTime createdAt;
  final List<OrderItemModel> items;
  final String shippingAddress;

  OrderModel({
    required this.id,
    required this.sellerId,
    required this.userId,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.createdAt,
    required this.items,
    required this.shippingAddress,
    this.riderId,
  });

  factory OrderModel.fromMap(String id, Map<String, dynamic> m) => OrderModel(
    id: id,
    sellerId: m['sellerId'] as String,
    userId: m['userId'] as String,
    riderId: m['riderId'] as String?,
    status: (m['status'] ?? 'new') as String,
    subtotal: (m['subtotal'] ?? 0) as num,
    deliveryFee: (m['deliveryFee'] ?? 0) as num,
    total: (m['total'] ?? 0) as num,
    createdAt: (m['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    items: (m['items'] as List<dynamic>? ?? const [])
        .map((e) => OrderItemModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList(),
    shippingAddress: (m['shippingAddress'] ?? '') as String,
  );
}
