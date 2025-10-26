import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:ubwinza_sellers/global/global_vars.dart';
import 'package:ubwinza_sellers/view_models/auth_view_model.dart';

import '../../global/global_instances.dart';
import '../widgets/custom_text_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  XFile? imageFile;
  ImagePicker pickerImage = ImagePicker();

  TextEditingController nameTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();
  TextEditingController confirmTextEditingController = TextEditingController();
  TextEditingController phoneTextEditingController = TextEditingController();
  TextEditingController locationTextEditingController = TextEditingController();

  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  Future<void> pickImageFromGallery() async {
    final XFile? pickedFile = await pickerImage.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        imageFile = pickedFile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          InkWell(
            onTap: pickImageFromGallery,
            child: CircleAvatar(
              radius: MediaQuery.of(context).size.width * 0.20,
              backgroundColor: Colors.grey[200],
              backgroundImage: imageFile == null ? null : FileImage(File(imageFile!.path)),
              child: imageFile == null
                  ? Icon(
                      Icons.add_photo_alternate,
                      size: MediaQuery.of(context).size.width * 0.15,
                      color: Colors.grey,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            imageFile == null ? "Tap to add profile photo" : "Photo selected ✓",
            style: TextStyle(
              color: imageFile == null ? Colors.grey : Colors.green,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 20),

          Form(
            key: formKey,
            child: Column(
              children: [
                CustomeTextField(
                  textEditingController: nameTextEditingController,
                  iconData: Icons.person,
                  hintString: "Name",
                  isObsecure: false,
                  enable: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomeTextField(
                  textEditingController: emailTextEditingController,
                  iconData: Icons.email,
                  hintString: "Email",
                  isObsecure: false,
                  enable: true,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomeTextField(
                  textEditingController: phoneTextEditingController,
                  iconData: Icons.phone,
                  hintString: "Phone",
                  isObsecure: false,
                  enable: true,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomeTextField(
                  textEditingController: passwordTextEditingController,
                  iconData: Icons.lock,
                  hintString: "Password",
                  isObsecure: true,
                  enable: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomeTextField(
                  textEditingController: confirmTextEditingController,
                  iconData: Icons.lock,
                  hintString: "Confirm Password",
                  isObsecure: true,
                  enable: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != passwordTextEditingController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomeTextField(
                  textEditingController: locationTextEditingController,
                  iconData: Icons.my_location,
                  hintString: "Cafe/Restaurant Address",
                  isObsecure: false,
                  enable: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      String address = await commonViewModel.getCurrentLocation();
                      setState(() {
                        locationTextEditingController.text = address;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    label: const Text(
                      "Get my current location",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    icon: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                authViewModel.isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                      )
                    : ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate() && imageFile != null) {
                            await authViewModel.validateSignUpForm(
                              imageFile,
                              passwordTextEditingController.text.trim(),
                              confirmTextEditingController.text.trim(),
                              emailTextEditingController.text.trim(),
                              nameTextEditingController.text.trim(),
                              phoneTextEditingController.text.trim(),
                              fullAddress,
                              context,
                            );
                          } else if (imageFile == null) {
                            commonViewModel.showSnackBar("Please select a profile photo", context);
                          }
                        },
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                          minimumSize: const Size(200, 50),
                        ),
                      ),
                const SizedBox(height: 37),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    nameTextEditingController.dispose();
    emailTextEditingController.dispose();
    passwordTextEditingController.dispose();
    confirmTextEditingController.dispose();
    phoneTextEditingController.dispose();
    locationTextEditingController.dispose();
    super.dispose();
  }
}