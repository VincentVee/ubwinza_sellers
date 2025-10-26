import 'package:flutter/material.dart';

class CustomeTextField extends StatefulWidget {
  final TextEditingController? textEditingController;
  final IconData? iconData;
  final String? hintString;
  final bool? isObsecure;
  final bool? enable;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const CustomeTextField({
    super.key, 
    this.textEditingController, 
    this.iconData, 
    this.hintString, 
    this.isObsecure, 
    this.enable,
    this.keyboardType,
    this.validator,
  });

  @override
  State<CustomeTextField> createState() => _CustomeTextFieldState();
}

class _CustomeTextFieldState extends State<CustomeTextField> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.all(11),
      child: TextFormField(
        style: const TextStyle(
          color: Colors.black,
        ),
        enabled: widget.enable,
        controller: widget.textEditingController,
        obscureText: widget.isObsecure ?? false,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(
            widget.iconData,
            color: Colors.blueAccent,
          ),
          hintText: widget.hintString,
          hintStyle: const TextStyle(
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}