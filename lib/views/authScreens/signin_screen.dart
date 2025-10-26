import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ubwinza_sellers/global/global_instances.dart';
import 'package:ubwinza_sellers/view_models/auth_view_model.dart';

import '../widgets/custom_text_field.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();

  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                "images/seller.png",
                height: 270,
              ),
            ),
          ),
          
          Form(
            key: formKey,
            child: Column(
              children: [
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
                  textEditingController: passwordTextEditingController,
                  iconData: Icons.lock,
                  hintString: "Password",
                  isObsecure: true,
                  enable: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                authViewModel.isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                      )
                    : ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            authViewModel.validateSignInForm(
                              emailTextEditingController.text.trim(),
                              passwordTextEditingController.text.trim(),
                              context,
                            );
                          }
                        },
                        child: const Text(
                          "Sign In",
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
                const SizedBox(height: 16),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    emailTextEditingController.dispose();
    passwordTextEditingController.dispose();
    super.dispose();
  }
}