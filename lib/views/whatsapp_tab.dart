import 'package:flutter/material.dart';

class WhatsAppTab extends StatelessWidget {
  const WhatsAppTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: const Text(
          'WhatsApp Status download coming soon!',
          style: TextStyle(fontSize: 18, color: Colors.orange, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}