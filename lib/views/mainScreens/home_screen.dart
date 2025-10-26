
import 'package:flutter/material.dart';
import 'package:ubwinza_sellers/views/widgets/my_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MyDrawer(),
      appBar: AppBar(
          backgroundColor:Color(0xFF1A2B7B),
        title: Text("Home Page"),
        
      ),
    );
  }
}
