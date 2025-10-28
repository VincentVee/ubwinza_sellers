import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NewOrdersScreen extends StatefulWidget {
  final String sellerId;
  const NewOrdersScreen({super.key, required this.sellerId});

  @override
  State<NewOrdersScreen> createState() => _NewOrdersScreenState();
}

class _NewOrdersScreenState extends State<NewOrdersScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Orders'),
        backgroundColor: Colors.deepOrange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('sellerId', isEqualTo: widget.sellerId)
            .where('status', whereIn: ['pending', 'preparing'])
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No active orders right now.',
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

              final status = order['status'] ?? 'pending';

              return Card(
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
                      Text('Total: ZMW ${order['total'].toStringAsFixed(2)}'),
                      Text('Delivery Fee: ZMW ${order['deliveryFee']}'),
                      Text('Distance: ${order['distanceKm'].toStringAsFixed(2)} km'),
                      Text('Ride Type: ${order['rideType']}'),
                      Text('Created: $dateStr'),
                      const SizedBox(height: 8),
                      Text(
                        'Status: ${status.toUpperCase()}',
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildActionButtons(orderId, status),
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

  Widget _buildActionButtons(String orderId, String currentStatus) {
    List<Widget> buttons = [];

    if (currentStatus == 'pending') {
      buttons = [
        _buildButton(
          label: 'Start Preparing',
          color: Colors.orange,
          icon: Icons.kitchen,
          onPressed: () => _confirmAction(orderId, 'preparing'),
        ),
        _buildButton(
          label: 'Cancel',
          color: Colors.redAccent,
          icon: Icons.cancel_outlined,
          onPressed: () => _confirmAction(orderId, 'cancelled'),
        ),
      ];
    } else if (currentStatus == 'preparing') {
      buttons = [
        _buildButton(
          label: 'Mark On The Way',
          color: Colors.green,
          icon: Icons.delivery_dining,
          onPressed: () => _confirmAction(orderId, 'onTheWay'),
        ),
        _buildButton(
          label: 'Cancel',
          color: Colors.redAccent,
          icon: Icons.cancel_outlined,
          onPressed: () => _confirmAction(orderId, 'cancelled'),
        ),
      ];
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: buttons
          .map((b) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: b,
                ),
              ))
          .toList(),
    );
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
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 10),
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
      case 'preparing':
        return Colors.blue;
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

    switch (newStatus) {
      case 'preparing':
        title = 'Start Preparing';
        message = 'Mark this order as preparing?';
        break;
      case 'onTheWay':
        title = 'Mark On The Way';
        message = 'Is the delivery rider now on the way?';
        break;
      case 'cancelled':
        title = 'Cancel Order';
        message =
            'Are you sure you want to cancel this order? It will be marked as cancelled.';
        break;
      default:
        title = 'Update Order';
        message = 'Change order status to $newStatus?';
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateOrderStatus(orderId, newStatus);
            },
            child: Text(
              'Yes',
              style: TextStyle(
                  color: newStatus == 'cancelled'
                      ? Colors.red
                      : Colors.green),
            ),
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
          content: Text('Order marked as $newStatus'),
          backgroundColor:
              newStatus == 'cancelled' ? Colors.red : Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update order: $e')),
      );
    }
  }
}
