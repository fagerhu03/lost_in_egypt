import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final String prompt;

  const ResultScreen({
    super.key,
    required this.prompt,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Prompt Result'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          prompt,
          style: const TextStyle(fontSize: 15),
        ),
      ),
    );
  }
}