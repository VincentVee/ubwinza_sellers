import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ubwinza_sellers/views/widgets/my_drawer.dart';

// Import your screens here
import '../../features/earnings/presentation/earnings_screen.dart';
import '../../features/orders/presentation/history_orders_screen.dart';
import '../../features/orders/presentation/new_order_screen.dart';
import '../../features/orders/presentation/orders_in_preparation_screen.dart';
import '../../features/orders/presentation/orders_in_transit_screen.dart';
import '../../features/products/presentation/product_list_screen.dart';
import '../../../global/global_instances.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String sellerId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1A2B7B);

    return Scaffold(
      drawer: const MyDrawer(),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: primaryColor,
        title: const Text(
          "Seller Dashboard",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.05),
        ),
        child: CustomScrollView(
          slivers: [
            // Header Welcome Section
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Welcome back,", style: TextStyle(color: Colors.white70, fontSize: 16)),
                    SizedBox(height: 5),
                    Text(
                      "Manage Your Store",
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
            ),

            // Grid Section
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.1,
                ),
                delegate: SliverChildListDelegate([
                  _buildDashboardCard(
                    context,
                    title: "Manage Products",
                    icon: Icons.inventory_2,
                    color: Colors.orange,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductListScreen(sellerId: sellerId))),
                  ),
                  _buildDashboardCard(
                    context,
                    title: "New Orders",
                    icon: Icons.reorder,
                    color: Colors.blue,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewOrdersScreen(sellerId: sellerId))),
                  ),
                  _buildDashboardCard(
                    context,
                    title: "Preparation",
                    icon: Icons.soup_kitchen,
                    color: Colors.purple,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrdersInPreparationScreen(sellerId: sellerId))),
                  ),
                  _buildDashboardCard(
                    context,
                    title: "Track Orders",
                    icon: Icons.local_shipping,
                    color: Colors.indigo,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrdersInTransitScreen(sellerId: sellerId))),
                  ),
                  _buildDashboardCard(
                    context,
                    title: "My Earnings",
                    icon: Icons.monetization_on,
                    color: Colors.green,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EarningsScreen(sellerId: sellerId))),
                  ),
                  _buildDashboardCard(
                    context,
                    title: "Order History",
                    icon: Icons.history,
                    color: Colors.teal,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HistoryOrdersScreen(sellerId: sellerId))),
                  ),
                ]),
              ),
            ),

            // Full Width Action Button for Address
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: InkWell(
                  onTap: () {
                    commonViewModel.updateLocationInDatabase();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Store address updated successfully")),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white60,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.share_location, color: primaryColor),
                        SizedBox(width: 15),
                        Text("Update Store Location", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                        Spacer(),
                        Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white60,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}