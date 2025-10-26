import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/order_model.dart';
import 'orders_view_model.dart';

class HistoryOrdersScreen extends StatelessWidget {
  final String sellerId;
  const HistoryOrdersScreen({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OrdersViewModel(sellerId: sellerId, history: true),
      child: Scaffold(
        appBar: AppBar(title: const Text('Order History'),backgroundColor:  Color(0xFF1A2B7B)),
        body: const _BodyHistory(),
      ),
    );
  }
}

class _BodyHistory extends StatelessWidget {
  const _BodyHistory();
  @override
  Widget build(BuildContext context) {
    final vm = context.read<OrdersViewModel>();
    return StreamBuilder<List<OrderModel>>(
      stream: vm.stream,
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final list = snap.data!;
        if (list.isEmpty) return const Center(child: Text('No history yet', style:  TextStyle( color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16), ));
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemBuilder: (_, i) {
            final o = list[i];
            return ListTile(
              title: Text('Order #${o.id.substring(o.id.length - 6)} · ${o.status.toUpperCase()}'),
              subtitle: Text(o.createdAt.toString()),
              trailing: Text('K${o.total}'),
            );
          },
          separatorBuilder: (_, __) => const Divider(),
          itemCount: list.length,
        );
      },
    );
  }
}
