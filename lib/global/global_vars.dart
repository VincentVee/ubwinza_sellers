
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

Position? position;

List<Placemark>? placeMark;
final user = FirebaseAuth.instance.currentUser;
String fullAddress = "";
SharedPreferences? sharedPreferences;
final Color primaryColor = Color(0xFF1A2B7B);
String googleApiKey = "AIzaSyC24a0-yk2HG6ONDtpbPRlL_lWkxeqqQ2Y";