import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/services/firebase_paths.dart';

class EarningsScreen extends StatelessWidget {
  final String sellerId;
  const EarningsScreen({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context) {
    final sellerDoc =
    FirebaseFirestore.instance.collection(FirebasePaths.sellers).doc(sellerId);

    final deliveredQ = FirebaseFirestore.instance
        .collection(FirebasePaths.orders)
        .where('sellerId', isEqualTo: sellerId)
        .where('status', isEqualTo: 'delivered')
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('My Earnings'),backgroundColor:  Color(0xFF1A2B7B)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: sellerDoc.snapshots(),
            builder: (context, snap) {
              final earnings = (snap.data?.data()?['earnings'] ?? 0) as num;
              return Card(
                color: const Color.fromARGB(255, 216, 211, 211),
                child: ListTile(
                  title: const Text('Wallet / Withdrawable', style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold
                  ),),
                  subtitle: const Text('Earnings stored on your seller profile', style: TextStyle(
                    color: Colors.black
                  ),),
                  trailing: Text('K$earnings',
                      style:
                      const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const Text('Delivered orders total (live calc)', style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold
                  ),),
          Expanded(
            child: StreamBuilder(
              stream: deliveredQ,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = (snap.data! as dynamic).docs as List;
                num sum = 0;
                for (final d in docs) {
                  final data = d.data() as Map<String, dynamic>;
                  sum += (data['subtotal'] ?? data['total'] ?? 0) as num;
                }
                return Center(
                  child: Text('K$sum',
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w700, color: Colors.black)),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
