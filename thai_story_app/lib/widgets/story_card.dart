import 'package:flutter/material.dart';

class StoryCard extends StatelessWidget {
  final String text;

  const StoryCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        width: double.infinity, // ขยายเต็มความกว้าง
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.orange.shade200, width: 2),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Text(
            text.isEmpty ? "🐰 รอฟังนิทานอยู่นะ..." : text,
            style: TextStyle(
              fontSize: 18,
              height: 1.6,
              color: Colors.brown.shade800,
            ),
          ),
        ),
      ),
    );
  }
}