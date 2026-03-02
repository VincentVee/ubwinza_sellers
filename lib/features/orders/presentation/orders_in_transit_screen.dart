import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Assuming global_vars.dart is available
import 'SellerTrackingDetailView.dart';

class OrdersInTransitScreen extends StatefulWidget {
  final String sellerId;
  const OrdersInTransitScreen({super.key, required this.sellerId});

  @override
  State<OrdersInTransitScreen> createState() => _OrdersInTransitScreenState();
}

class _OrdersInTransitScreenState extends State<OrdersInTransitScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders In Transit'),
        backgroundColor: primaryColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('sellerId', isEqualTo: widget.sellerId)
        // ⭐ Filter for orders that are dispatched or on the way
            .where('status', whereIn: ['prepared', 'in-progress','onTheWay', 'heading_to_destination'])
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No orders currently out for delivery.',
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

              return OrderTransitCard(order: order, orderId: orderId);
            },
          );
        },
      ),
    );
  }
}

class OrderTransitCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final String orderId;

  const OrderTransitCard({
    super.key,
    required this.order,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    final createdAt = order['createdAt'] is Timestamp
        ? order['createdAt'].toDate()
        : DateTime.now();
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(createdAt);

    final status = order['status'] ?? 'unknown';
    final driverName = order['driverName'] ?? 'Awaiting Assignment';
    final driverPhone = order['driverPhone'];
    final vehicleType = order['rideType'] ?? 'N/A';

    // Summary of items
    final itemSummary = _buildItemSummary(order['items'] as List<dynamic>?);

    return Card(
      color: primaryColor,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID and Date
            
            Text(
              'Placed: $dateStr',
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),

            const Divider(height: 20, color: Colors.white24),

            // Item Summary
            ...itemSummary,

            const Divider(height: 20, color: Colors.white24),

            // Driver and Status Info

                _buildStatusChip(status),
                Text(
                  'Total: ZMW ${order['total']?.toStringAsFixed(2) ?? 'N/A'}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),

            const SizedBox(height: 10),

            _buildDriverInfo(driverName, driverPhone, vehicleType),

            // Optional: A button to view live map for the seller
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.location_on_outlined, size: 18),
                  label: const Text('View Live Tracking (Admin View)'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: primaryColor,
                    backgroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SellerTrackingDetailView(
                          requestId: orderId,
                          initialOrderData: order,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
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
        style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.white),
      );
    }).toList();
  }

  // Helper to display driver and vehicle info
  Widget _buildDriverInfo(String name, String? phone, String vehicleType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              vehicleType.toLowerCase() == 'motorbike' ? Icons.two_wheeler : Icons.pedal_bike,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '$vehicleType Driver: $name',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
        if (phone != null && phone.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 28),
            child: Text(
              'Contact: $phone',
              style: const TextStyle(fontSize: 13, color: Colors.white60),
            ),
          ),
      ],
    );
  }

  // Helper to build a status chip
  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'prepared':
        color = Colors.orange.shade700;
        text = 'Awaiting Pickup';
        icon = Icons.pending_actions;
        break;
      case 'in-progress':
      case 'heading_to_destination':
        color = Colors.green;
        text = 'Driver to pickup';
        icon = Icons.delivery_dining;
        break;
      default:
        color = Colors.grey;
        text = 'Unknown';
        icon = Icons.help_outline;
    }

    return Chip(
      avatar: Icon(icon, color: Colors.white, size: 18),
      label: Text(
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}