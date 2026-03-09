import 'package:flutter/material.dart';

class AppInlineMessage extends StatelessWidget {
  const AppInlineMessage({
    super.key,
    required this.message,
    this.color = const Color(0xFF8A6272),
  });

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();
    return Text(
      message,
      style: TextStyle(color: color, fontWeight: FontWeight.w600),
    );
  }
}
