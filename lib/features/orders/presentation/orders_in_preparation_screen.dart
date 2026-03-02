import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Assuming global_vars.dart is available
import '../../../global/global_vars.dart';
import 'orders_in_transit_screen.dart';

class OrdersInPreparationScreen extends StatefulWidget {
  final String sellerId;
  const OrdersInPreparationScreen({super.key, required this.sellerId});

  @override
  State<OrdersInPreparationScreen> createState() => _OrdersInPreparationScreenState();
}

class _OrdersInPreparationScreenState extends State<OrdersInPreparationScreen> {
  // The new status to be set when the order is ready for dispatch
  static const String READY_FOR_DISPATCH_STATUS = 'prepared';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preparing Orders'),
        backgroundColor: primaryColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('sellerId', isEqualTo: widget.sellerId)
        // ⭐ Filter for orders that have been accepted by the seller
            .where('status', isEqualTo: 'preparing')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No orders currently in preparation.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;
              final orderId = orders[index].id;
              final createdAt = order['createdAt'] is Timestamp
                  ? order['createdAt'].toDate()
                  : DateTime.now();
              final dateStr =
              DateFormat('dd MMM yyyy, hh:mm a').format(createdAt);

              final status = order['status'] ?? 'preparing';

              return Card(
                color: primaryColor,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['seller']?['name'] ?? 'Unknown Seller',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      // Display Dropoff Location (Crucial for preparation screen)
                      Text(
                        'Dropoff: ${order['dropoff']?['id'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      // List Items (Summary)
                      ..._buildItemSummary(order['items'] as List<dynamic>?),

                      const Divider(height: 20, color: Colors.white24),

                      Text('Total: ZMW ${order['total'].toStringAsFixed(2)}'),
                      Text('Delivery Fee: ZMW ${order['deliveryFee']}'),
                      Text('Created: $dateStr'),
                      const SizedBox(height: 10),

                      // Status and Action Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Status: ${status.toUpperCase()}',
                            style: TextStyle(
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          _buildActionButton(orderId, status),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Helper to build a summary of items
  List<Widget> _buildItemSummary(List<dynamic>? itemsData) {
    if (itemsData == null || itemsData.isEmpty) {
      return [const Text('No items listed.')];
    }
    return itemsData.map((item) {
      final name = item['name'] as String? ?? 'Item';
      final qty = (item['qty'] as num?)?.toInt() ?? 1;
      return Text(
        '  • $qty x $name',
        style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
      );
    }).toList();
  }

  // New action button specific to this screen
  Widget _buildActionButton(String orderId, String currentStatus) {
    // Only show the button if the status is 'accepted'
    if (currentStatus == 'preparing') {
      return _buildButton(
        label: 'Send for Delivery',
        color: Colors.green,
        icon: Icons.send,
        onPressed: () => _confirmAction(orderId, READY_FOR_DISPATCH_STATUS),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: onPressed,
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'preparing': // Preparing status color
        return Colors.blue;
      case 'prepared':
        return Colors.yellow.shade700;
      case 'onTheWay':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _confirmAction(String orderId, String newStatus) {
    String title;
    String message;

    if (newStatus == READY_FOR_DISPATCH_STATUS) {
      title = 'Dispatch Order';
      message = 'Is this order fully packaged and ready for driver pickup?';
    } else {
      title = 'Update Order';
      message = 'Change order status to $newStatus?';
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: primaryColor,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'Cancel'),
            child: const Text('No', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateOrderStatus(orderId, newStatus);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => OrdersInTransitScreen(sellerId: widget.sellerId),
                ),
              );
            },
            child: const Text('Yes', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': newStatus});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated to $newStatus.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update order: $e')),
      );
    }
  }
}