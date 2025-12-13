import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E2C0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5E2C0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.brown),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Settings",
          style: TextStyle(
            color: Colors.brown,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
      ),
      body: const Center(
        child: Text(
          'Settings Screen\nComing Soon!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Colors.brown,
          ),
        ),
      ),
    );
  }
}