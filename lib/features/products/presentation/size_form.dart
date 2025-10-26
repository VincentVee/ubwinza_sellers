// size_form.dart
import 'package:flutter/material.dart';

class SizeForm extends StatefulWidget {
  final Map<String, dynamic>? existingSize;
  final Function(Map<String, dynamic>) onSave;

  const SizeForm({
    super.key,
    this.existingSize,
    required this.onSave,
  });

  @override
  State<SizeForm> createState() => _SizeFormState();
}

class _SizeFormState extends State<SizeForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _priceModifierCtrl = TextEditingController(text: '0.0');
  bool _inStock = true;

  @override
  void initState() {
    super.initState();
    // Pre-fill if editing existing size
    if (widget.existingSize != null) {
      _nameCtrl.text = widget.existingSize!['name'] ?? '';
      _descriptionCtrl.text = widget.existingSize!['description'] ?? '';
      _priceModifierCtrl.text = (widget.existingSize!['priceModifier'] ?? 0.0).toString();
      _inStock = widget.existingSize!['inStock'] ?? true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existingSize != null ? 'Edit Size' : 'Add New Size',
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
                  labelText: 'Size Name',
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
                controller: _priceModifierCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Price Modifier',
                  labelStyle: TextStyle(color: Colors.white),
                  hintText: 'e.g., 2.50 for +K2.50, -1.00 for -K1.00',
                  hintStyle: TextStyle(color: Colors.white54),
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
              final size = {
                'id': widget.existingSize?['id'] ?? _nameCtrl.text.toLowerCase().replaceAll(' ', '_'),
                'name': _nameCtrl.text.trim(),
                'description': _descriptionCtrl.text.trim(),
                'priceModifier': double.parse(_priceModifierCtrl.text),
                'inStock': _inStock,
              };
              widget.onSave(size);
              Navigator.pop(context);
            }
          },
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}