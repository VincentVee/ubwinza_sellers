// // orders_view_model.dart
//
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../../../core/models/order_model.dart';
//
// class OrdersViewModel extends ChangeNotifier {
//   final String sellerId;
//   final bool history;
//
//   // Stream to hold the result of the Firestore query
//   late final Stream<List<OrderModel>> _orderStream;
//
//   Stream<List<OrderModel>> get stream => _orderStream;
//
//   OrdersViewModel({required this.sellerId, this.history = false}) {
//     _orderStream = _fetchOrdersStream();
//   }
//
//   Stream<List<OrderModel>> _fetchOrdersStream() {
//     Query ordersQuery = FirebaseFirestore.instance.collection('orders');
//
//     // 1. Filter by seller ID
//     ordersQuery = ordersQuery.where('sellerId', isEqualTo: sellerId);
//
//     // 2. Filter by status: 'delivered' for history, or current status for live orders
//     if (history) {
//       ordersQuery = ordersQuery.where('status', isEqualTo: 'delivered');
//     }
//     // If you need to filter live orders (e.g., status != 'delivered' or 'cancelled')
//     // else {
//     //   ordersQuery = ordersQuery.where('status', whereIn: ['pending', 'accepted', 'driverToPickup', 'onTheWayToYou']);
//     // }
//
//     // 3. Order by creation time (most recent first)
//     ordersQuery = ordersQuery.orderBy('createdAt', descending: true);
//
//     // Convert the QuerySnapshot stream to a List<OrderModel> stream
//     return ordersQuery.snapshots().map((snapshot) {
//       return snapshot.docs
//           .map((doc) => OrderModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
//           .toList();
//     }).handleError((error) {
//       debugPrint('Error fetching seller orders: $error');
//       // Optionally rethrow or return an empty list on error
//       return [];
//     });
//   }
// }