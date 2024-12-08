import 'package:flutter/material.dart';

class CodeEditor extends StatelessWidget {
  final String code;
  final Function(String) onChanged;

  const CodeEditor({
    super.key,
    required this.code,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: code),
      maxLines: null,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Enter template code',
      ),
      onChanged: onChanged,
    );
  }
} 