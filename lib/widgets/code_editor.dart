import 'package:flutter/material.dart';

class CodeEditor extends StatefulWidget {
  final String code;
  final Function(String) onChanged;

  const CodeEditor({
    super.key,
    required this.code,
    required this.onChanged,
  });

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.code);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _controller,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'monospace',
        ),
        maxLines: null,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Enter template code...',
          hintStyle: TextStyle(color: Colors.grey),
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
} 