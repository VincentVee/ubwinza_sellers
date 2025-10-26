import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ubwinza_sellers/global/global_vars.dart';
import 'package:ubwinza_sellers/view_models/auth_view_model.dart';
import 'package:ubwinza_sellers/views/splashScreen/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  sharedPreferences = await SharedPreferences.getInstance();

  await Permission.locationWhenInUse.isDenied.then((valueOfPermission) {
    if(valueOfPermission) {
      Permission.locationWhenInUse.request();
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthViewModel()),
        // Add other providers here if you have more view models
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Ubwinza Seller App',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFFB8B4B4),
        ),
        home: const MySplashScreen(),
      ),
    );
  }
}