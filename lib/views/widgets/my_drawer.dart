import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ubwinza_sellers/features/profile/profile_update_screen.dart';
import 'package:ubwinza_sellers/global/global_instances.dart';
import 'package:ubwinza_sellers/global/global_vars.dart';
import 'package:ubwinza_sellers/views/mainScreens/home_screen.dart';
import 'package:ubwinza_sellers/views/splashScreen/splash_screen.dart';

import '../../features/earnings/presentation/earnings_screen.dart';
import '../../features/orders/presentation/history_orders_screen.dart';
import '../../features/orders/presentation/new_order_screen.dart';
import '../../features/products/presentation/product_list_screen.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({super.key});

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color.fromARGB(255, 71, 70, 70),
      child: ListView(
        children: [

          //header
         // In your MyDrawer class, update the header section:

//header
Container(
  padding: EdgeInsets.only(top: 25, bottom: 10),
  child: Column(
    children: [
      // Make the profile image clickable
      GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileUpdateScreen()),
          );
        },
        child: Material(
          borderRadius: const BorderRadius.all(Radius.circular(81)),
          elevation: 8,
          child: SizedBox(
            height: 158,
            width: 158,
            child: CircleAvatar(
              backgroundImage: NetworkImage(
                sharedPreferences!.getString("imageUrl") ?? '',
              ),
              child: sharedPreferences!.getString("imageUrl") == null ||
                      sharedPreferences!.getString("imageUrl")!.isEmpty
                  ? const Icon(Icons.person, size: 50, color: Colors.white)
                  : null,
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Text(
        sharedPreferences!.getString("name") ?? 'No Name',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        sharedPreferences!.getString("restaurantName") ?? 'No Restaurant Name',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    ],
  ),
),

          // body
          Container(

            child: Column(

              children: [
                const Divider(
                  height: 10,
                    color: Colors.grey,
                  thickness: 2,

                ),
                ListTile(
                  leading: const Icon(Icons.home, color: Colors.white,),
                  title: const Text(
                    "Home",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                   onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen()));
                   },

                ),

                const Divider(
                  height: 10,
                  color: Colors.grey,
                  thickness: 2,

                ),

                ListTile(
                  leading: const Icon(Icons.inventory_2, color: Colors.white),
                  title: const Text('Manage Products', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    final sellerId = FirebaseAuth.instance.currentUser!.uid; // or from sharedPreferences
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ProductListScreen(sellerId: sellerId),
                    ));
                  },
                ),

                const Divider(
                  height: 10,
                  color: Colors.grey,
                  thickness: 2,

                ),

                ListTile(
                  leading: const Icon(Icons.monetization_on, color: Colors.white),
                  title: const Text("My Earnings", style: TextStyle(color: Colors.white)),
                  onTap: () {
                    final sellerId = FirebaseAuth.instance.currentUser!.uid;
                    Navigator.push(context,
                      MaterialPageRoute(builder: (_) => EarningsScreen(sellerId: sellerId)),
                    );
                  },
                ),
                const Divider(
                  height: 10,
                  color: Colors.grey,
                  thickness: 2,

                ),

                ListTile(
                  leading: const Icon(Icons.reorder, color: Colors.white),
                  title: const Text("New Orders", style: TextStyle(color: Colors.white)),
                  onTap: () {
                    final sellerId = FirebaseAuth.instance.currentUser!.uid;
                    Navigator.push(context,
                      MaterialPageRoute(builder: (_) => NewOrdersScreen(sellerId: sellerId)),
                    );
                  },
                ),

                const Divider(
                  height: 10,
                  color: Colors.grey,
                  thickness: 2,

                ),

                ListTile(
                  leading: const Icon(Icons.local_shipping, color: Colors.white),
                  title: const Text("History - Order", style: TextStyle(color: Colors.white)),
                  onTap: () {
                    final sellerId = FirebaseAuth.instance.currentUser!.uid;
                    Navigator.push(context,
                      MaterialPageRoute(builder: (_) => HistoryOrdersScreen(sellerId: sellerId)),
                    );
                  },
                ),

                const Divider(
                  height: 10,
                  color: Colors.grey,
                  thickness: 2,

                ),

                ListTile(
                  leading: const Icon(Icons.share_location, color: Colors.white,),
                  title: const Text(
                    "Update My Address",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  onTap: () {

                    commonViewModel.updateLocationInDatabase();
                    commonViewModel.showSnackBar(
                        "Your restaurant/cafe address updated successfully",
                        context
                    );
                  },

                ),

                const Divider(
                  height: 10,
                  color: Colors.grey,
                  thickness: 2,

                ),
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: Colors.white,),
                  title: const Text(
                    "Sign Out",
                    style: TextStyle(
                      color: Colors.white,

                    ),
                  ),
                  onTap: () {
                    FirebaseAuth.instance.signOut();
                    Navigator.push(context, MaterialPageRoute(builder: (context) => MySplashScreen()));
                  },

                ),
              ],

            ),
          )
        ],
      ),
    );
  }
}
