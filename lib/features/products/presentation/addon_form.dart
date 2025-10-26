// addon_form.dart
import 'package:flutter/material.dart';

class AddonForm extends StatefulWidget {
  final Map<String, dynamic>? existingAddon;
  final Function(Map<String, dynamic>) onSave;

  const AddonForm({
    super.key,
    this.existingAddon,
    required this.onSave,
  });

  @override
  State<AddonForm> createState() => _AddonFormState();
}

class _AddonFormState extends State<AddonForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  bool _inStock = true;

  @override
  void initState() {
    super.initState();
    // Pre-fill if editing existing addon
    if (widget.existingAddon != null) {
      _nameCtrl.text = widget.existingAddon!['name'] ?? '';
      _descriptionCtrl.text = widget.existingAddon!['description'] ?? '';
      _priceCtrl.text = (widget.existingAddon!['price'] ?? 0.0).toString();
      _inStock = widget.existingAddon!['inStock'] ?? true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existingAddon != null ? 'Edit Add-on' : 'Add New Add-on',
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: const Color(0xFF1A2B7B),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Add-on Name',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Price',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (v) {
                  if (v?.trim().isEmpty ?? true) return 'Required';
                  if (double.tryParse(v!) == null) return 'Enter valid price';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'In Stock',
                    style: TextStyle(color: Colors.white),
                  ),
                  const Spacer(),
                  Switch(
                    value: _inStock,
                    onChanged: (value) => setState(() => _inStock = value),
                    activeColor: Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final addon = {
                'id': widget.existingAddon?['id'] ?? _nameCtrl.text.toLowerCase().replaceAll(' ', '_'),
                'name': _nameCtrl.text.trim(),
                'description': _descriptionCtrl.text.trim(),
                'price': double.parse(_priceCtrl.text),
                'inStock': _inStock,
              };
              widget.onSave(addon);
              Navigator.pop(context);
            }
          },
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}