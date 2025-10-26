import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ubwinza_sellers/global/global_instances.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_storage/firebase_storage.dart' as fs_store;
import 'package:ubwinza_sellers/global/global_vars.dart';
import 'package:ubwinza_sellers/views/mainScreens/home_screen.dart';

class AuthViewModel extends ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners(); // Notify listeners when loading state changes
  }

  Future<void> validateSignUpForm(
      XFile? image,
      String password,
      String confirm,
      String email,
      String name,
      String phone,
      String locationAddress,
      BuildContext context,
      ) async {
    if (_isLoading) return;

    // Clear previous errors
    _clearValidationMessages(context);

    // Validation checks
    if (image == null) {
      _showValidationError("Please select an image from gallery", context);
      return;
    }

    if (name.isEmpty) {
      _showValidationError("Please enter your name", context);
      return;
    }

    if (email.isEmpty || !_isValidEmail(email)) {
      _showValidationError("Please enter a valid email address", context);
      return;
    }

    if (phone.isEmpty) {
      _showValidationError("Please enter your phone number", context);
      return;
    }

    if (password.isEmpty) {
      _showValidationError("Please enter a password", context);
      return;
    }

    if (password.length < 6) {
      _showValidationError("Password must be at least 6 characters", context);
      return;
    }

    if (password != confirm) {
      _showValidationError("Password and confirmation do not match!", context);
      return;
    }

    if (locationAddress.isEmpty) {
      _showValidationError("Please enter your location address", context);
      return;
    }

    // Optional but important: guard against null GPS position
    final lat = position?.latitude;
    final lng = position?.longitude;
    if (lat == null || lng == null) {
      debugPrint('⚠️ position is null; saving without lat/lng');
    }

    _setLoading(true);
    commonViewModel.showSnackBar("Please wait...", context);

    final fb_auth.User? currentUser =
    await createUserInFirebase(email, password, context);

    if (currentUser == null) {
      _setLoading(false);
      fb_auth.FirebaseAuth.instance.signOut();
      return;
    }

    final String downloadUrl = await uploadImageToFirebase(image);

    final ok = await saveUserToFireStore(
      currentUser: currentUser,
      downloadUrl: downloadUrl,
      email: email,
      name: name,
      locationAddress: locationAddress,
      phone: phone,
      latitude: lat,
      longitude: lng,
      context: context,
    );

    _setLoading(false);

    if (!ok) return; // error already shown

    // Only navigate after successful save
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (_) => HomeScreen()), 
        (route) => false
      );
      commonViewModel.showSnackBar("Account created successfully", context);
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
  }

  void _showValidationError(String message, BuildContext context) {
    commonViewModel.showSnackBar(message, context);
  }

  void _clearValidationMessages(BuildContext context) {
    // This method can be used to clear any validation UI if needed
  }

  Future<fb_auth.User?> createUserInFirebase(
      String email,
      String password,
      BuildContext context,
      ) async {
    try {
      final cred = await fb_auth.FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      return cred.user;
    } on fb_auth.FirebaseAuthException catch (e) {
      String errorMessage = "An error occurred";
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = "This email is already registered";
          break;
        case 'invalid-email':
          errorMessage = "Please enter a valid email address";
          break;
        case 'weak-password':
          errorMessage = "Password is too weak";
          break;
        case 'operation-not-allowed':
          errorMessage = "Email/password accounts are not enabled";
          break;
        default:
          errorMessage = e.message ?? e.code;
      }
      commonViewModel.showSnackBar(errorMessage, context);
      return null;
    } catch (e) {
      commonViewModel.showSnackBar("An unexpected error occurred", context);
      return null;
    }
  }

  Future<String> uploadImageToFirebase(XFile image) async {
    final String fileName = DateTime.now().microsecondsSinceEpoch.toString();
    final fs_store.Reference ref = fs_store.FirebaseStorage.instance
        .ref()
        .child('sellerimages/$fileName');

    final fs_store.UploadTask task = ref.putFile(File(image.path));
    final fs_store.TaskSnapshot snap = await task;
    final String url = await snap.ref.getDownloadURL();
    return url;
  }

  Future<bool> saveUserToFireStore({
    required fb_auth.User currentUser,
    required String downloadUrl,
    required String email,
    required String name,
    required String locationAddress,
    required String phone,
    String? description,
    double? latitude,
    double? longitude,
    required BuildContext context,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection("sellers")
          .doc(currentUser.uid)
          .set({
        "uid": currentUser.uid,
        "imageUrl": downloadUrl,
        "email": email,
        "name": name,
        "address": locationAddress,
        "phone": phone,
        "earnings": 0.0,
        if (latitude != null) "latitude": latitude,
        if (longitude != null) "longitude": longitude,
        "createdAt": FieldValue.serverTimestamp(),
        "status": "approved"
      }, SetOptions(merge: true));

      await sharedPreferences!.setString("uid", currentUser.uid);
      await sharedPreferences!.setString("email", email);
      await sharedPreferences!.setString("name", name);
      await sharedPreferences!.setString("imageUrl", downloadUrl);
      await sharedPreferences!.setString("phone", downloadUrl);

      return true;
    } on FirebaseException catch (e) {
      commonViewModel.showSnackBar(
        "Error saving data: ${e.message ?? e.code}",
        context,
      );
      debugPrint('Firestore error: $e');
      return false;
    } catch (e) {
      commonViewModel.showSnackBar("Error saving user data", context);
      debugPrint('Unexpected error saving seller: $e');
      return false;
    }
  }

  Future<void> validateSignInForm(String email, String password, BuildContext context) async {
    if (_isLoading) return;

    // Clear previous errors
    _clearValidationMessages(context);

    if(email.isEmpty || password.isEmpty) {
      _showValidationError("Email and Password are required!", context);
      return;
    }

    if (!_isValidEmail(email)) {
      _showValidationError("Please enter a valid email address", context);
      return;
    }

    _setLoading(true);
    commonViewModel.showSnackBar("Checking your credentials...!", context);

    fb_auth.User? currentFirebaseUser = await signInUser(email, password, context);

    if (currentFirebaseUser == null) {
      _setLoading(false);
      return;
    }

    bool success = await readDataFromFirestoreAndSetDataLocally(currentFirebaseUser, context);
    _setLoading(false);

    if (success && context.mounted) {
      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (_) => HomeScreen()), 
        (route) => false
      );
      commonViewModel.showSnackBar("Sign in successfully...!", context);
    }
  }

  Future<fb_auth.User?> signInUser(String email, String password, BuildContext context) async {
    try {
      final userCredential = await fb_auth.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      return userCredential.user;
    } on fb_auth.FirebaseAuthException catch (e) {
      String errorMessage = "An error occurred";
      switch (e.code) {
        case 'user-not-found':
          errorMessage = "No user found with this email";
          break;
        case 'wrong-password':
          errorMessage = "Incorrect password";
          break;
        case 'invalid-email':
          errorMessage = "Please enter a valid email address";
          break;
        case 'user-disabled':
          errorMessage = "This account has been disabled";
          break;
        default:
          errorMessage = e.message ?? e.code;
      }
      commonViewModel.showSnackBar(errorMessage, context);
      return null;
    } catch (e) {
      commonViewModel.showSnackBar("An unexpected error occurred", context);
      return null;
    }
  }

  Future<bool> readDataFromFirestoreAndSetDataLocally(fb_auth.User currentFirebaseUser, BuildContext context) async {
    try {
      final dataSnapshot = await FirebaseFirestore.instance
          .collection("sellers")
          .doc(currentFirebaseUser.uid)
          .get();

      if (dataSnapshot.exists) {
        if (dataSnapshot.data()!["status"] == "approved") {
          await sharedPreferences!.setString("uid", currentFirebaseUser.uid);
          await sharedPreferences!.setString("email", dataSnapshot.data()!["email"]);
          await sharedPreferences!.setString("name", dataSnapshot.data()!["name"]);
          await sharedPreferences!.setString("imageUrl", dataSnapshot.data()!["imageUrl"]);
          await sharedPreferences!.setString("phone", dataSnapshot.data()!["phone"]);
          return true;
        } else {
          commonViewModel.showSnackBar("You are blocked by admin!", context);
          fb_auth.FirebaseAuth.instance.signOut();
          return false;
        }
      } else {
        commonViewModel.showSnackBar("This seller record does not exist", context);
        fb_auth.FirebaseAuth.instance.signOut();
        return false;
      }
    } catch (e) {
      commonViewModel.showSnackBar("Error retrieving user data", context);
      fb_auth.FirebaseAuth.instance.signOut();
      return false;
    }
  }
}