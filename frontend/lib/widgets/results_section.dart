import 'package:flutter/material.dart';

import '../components/buttons/app_button.dart';
import '../components/surfaces/app_section_card.dart';
import '../models.dart';
import 'winner_card.dart';

class ResultsSection extends StatelessWidget {
  const ResultsSection({
    super.key,
    required this.winner,
    required this.sortedResults,
    required this.isHost,
    required this.onRestart,
  });

  final OptionModel? winner;
  final List<OptionModel> sortedResults;
  final bool isHost;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Results',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        if (winner != null) WinnerCard(option: winner!),
        const SizedBox(height: 8),
        ...sortedResults.map((option) {
          final subtitle = [
            if (option.cuisineType != null) option.cuisineType,
            if (option.address != null) option.address,
          ].whereType<String>().join(' • ');
          return AppSectionCard(
            child: ListTile(
              title: Text(option.name),
              subtitle: subtitle.isEmpty ? null : Text(subtitle),
              trailing: Text('${option.voteCount} votes'),
            ),
          );
        }),
        if (isHost) ...[
          const SizedBox(height: 10),
          AppButton(
            onPressed: onRestart,
            icon: Icons.replay_rounded,
            text: 'Restart session',
          ),
        ],
      ],
    );
  }
}
