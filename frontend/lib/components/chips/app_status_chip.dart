import 'package:flutter/material.dart';

import '../../constants/ui_tokens.dart';

class AppStatusChip extends StatelessWidget {
  const AppStatusChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label.toUpperCase()),
      side: BorderSide.none,
      backgroundColor: AppColors.accentPurple,
      labelStyle: const TextStyle(
        color: Color(0xFF5F3A47),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
