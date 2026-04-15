import 'package:flutter/material.dart';

class CustomizePlanScreen extends StatelessWidget {
  const CustomizePlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customize Plan')),
      body: const Center(
        child: Text('Collect user data here'),
      ),
    );
  }
}