import 'package:flutter/material.dart';

import '../maps_launch.dart';
import '../models.dart';
import 'option_tile.dart' show StarRatingRow;

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
            ],
          ),
          if (option.cuisineType != null) const SizedBox(height: 8),
          if (option.rating != null) ...[
            StarRatingRow(rating: option.rating!),
            const SizedBox(height: 8),
          ],
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
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (option.mapsLaunchUri != null)
                FilledButton.icon(
                  onPressed: () async {
                    await launchOptionInMaps(option);
                  },
                  icon: const Icon(Icons.map_rounded),
                  label: const Text('Open in Maps'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4A2E3A),
                    foregroundColor: const Color(0xFFFFF4E8),
                  ),
                ),
              if (option.websiteUri != null &&
                  option.websiteUri!.trim().isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () async {
                    await launchWebsite(option.websiteUri);
                  },
                  icon: const Icon(Icons.restaurant_menu_rounded),
                  label: const Text('Menu / website'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4A2E3A),
                  ),
                ),
            ],
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
