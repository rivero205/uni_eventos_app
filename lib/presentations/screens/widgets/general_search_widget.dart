import 'package:flutter/material.dart';

class GeneralSearchWidget extends StatelessWidget {
  final TextEditingController controller;
  final String currentQuery;
  final VoidCallback onClear;
  final Function(String) onSubmitted;
  final ValueChanged<String>? onChanged;
  final String labelText;
  final String hintText;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;

  const GeneralSearchWidget({
    super.key,
    required this.controller,
    required this.currentQuery,
    required this.onClear,
    required this.onSubmitted,
    this.onChanged,
    required this.labelText,
    required this.hintText,
    this.focusNode,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        suffixIcon: currentQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: onClear,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Color(0xFF0288D1), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: textInputAction ?? TextInputAction.search,
    );
  }
}
