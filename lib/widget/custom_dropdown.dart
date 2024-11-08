import 'package:flutter/material.dart';

class CustomDropdownFormField extends StatefulWidget {
  final String label; // Original label
  final TextStyle labelStyle;
  final List<String> items;
  final TextEditingController controller;

  const CustomDropdownFormField({
    super.key,
    required this.label,
    required this.labelStyle,
    required this.items,
    required this.controller,
  });

  @override
  _CustomDropdownFormFieldState createState() => _CustomDropdownFormFieldState();
}

class _CustomDropdownFormFieldState extends State<CustomDropdownFormField> {
  String? errorMessage; // Initialize to null

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: errorMessage ?? widget.label,
        labelStyle: widget.labelStyle.copyWith(
          color: errorMessage != null ? Colors.red.withOpacity(0.5) : widget.labelStyle.color,
        ),
        suffixIcon: const Icon(
          Icons.arrow_drop_down,
          color: Color(0xff13322b), // Set the arrow color
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          borderSide: BorderSide(
            color: errorMessage != null ? Colors.red.withOpacity(0.2):const Color(0xff13322b).withOpacity(0.5),
            width: 1.0,
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          borderSide: BorderSide(
            color: Color(0xff13322b),
            width: 2.0,
          ),
        ),
      ),
      value: widget.controller.text.isNotEmpty ? widget.controller.text : null,
      dropdownColor: const Color(0xffffffff),
      items: widget.items.map((String status) {
        return DropdownMenuItem<String>(
          value: status,
          child: Text(
            status,
            style: const TextStyle(
              color: Color(0xff13322b),
            ),
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          widget.controller.text = newValue ?? '';
          errorMessage = null; // Clear error message when selection changes
        });
      },
      validator: (value) {
        final error = (value == null || value.isEmpty) ? 'Please select a civil status' : null;
        setState(() {
          errorMessage = error; // Update error message state
        });
        return null; // Return null to avoid showing default validator messages
      },
    );
  }
}
