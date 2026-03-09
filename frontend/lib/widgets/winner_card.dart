import 'package:flutter/material.dart';

import '../models.dart';

class WinnerCard extends StatelessWidget {
  const WinnerCard({super.key, required this.option});

  final OptionModel option;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF9CB6), Color(0xFFFFD27A), Color(0xFF87C5FF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Winner',
            style: TextStyle(
              color: Color(0xFF5F3A47),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (option.cuisineType != null)
                _chip(Icons.restaurant_menu_rounded, option.cuisineType!),
              if (option.rating != null)
                _chip(Icons.star_rounded, option.rating!.toStringAsFixed(1)),
            ],
          ),
          if (option.cuisineType != null || option.rating != null)
            const SizedBox(height: 8),
          Text(
            option.name,
            style: const TextStyle(
              color: Color(0xFF4A2E3A),
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (option.address != null) ...[
            const SizedBox(height: 4),
            Text(
              option.address!,
              style: const TextStyle(color: Color(0xFF5F3A47)),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            '${option.voteCount} votes',
            style: const TextStyle(color: Color(0xFF4A2E3A)),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x66FFE8C7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Color(0xFF4A2E3A), size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF4A2E3A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
