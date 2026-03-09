import 'package:flutter/material.dart';

class AppAvatarChip extends StatelessWidget {
  const AppAvatarChip({
    super.key,
    required this.name,
    this.isHost = false,
    this.isYou = false,
  });

  final String name;
  final bool isHost;
  final bool isYou;

  @override
  Widget build(BuildContext context) {
    final label = [name, if (isYou) 'you', if (isHost) 'host'].join(' • ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isHost ? const Color(0xFFFFBDBD) : const Color(0xFFFCF9EA),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isHost ? const Color(0xFFFFA4A4) : const Color(0xFFDCCEEB),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF5F3A47),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
