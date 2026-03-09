import 'package:flutter/material.dart';

import '../components/buttons/app_button.dart';
import '../components/chips/app_avatar_chip.dart';
import '../components/inputs/app_autocomplete_field.dart';
import '../components/state/app_empty_state.dart';
import '../components/surfaces/app_section_card.dart';
import '../constants/cuisine_constants.dart';
import '../models.dart';

class WaitingSection extends StatelessWidget {
  const WaitingSection({
    super.key,
    required this.room,
    required this.isHost,
    required this.currentUserId,
    required this.highlightedOptionId,
    required this.optionController,
    required this.addingOption,
    required this.startingVote,
    required this.onAddOption,
    required this.onStartVoting,
  });

  final RoomModel room;
  final bool isHost;
  final String? currentUserId;
  final String? highlightedOptionId;
  final TextEditingController optionController;
  final bool addingOption;
  final bool startingVote;
  final VoidCallback onAddOption;
  final VoidCallback onStartVoting;

  @override
  Widget build(BuildContext context) {
    final participants = room.participants;
    final atLimit = room.options.length >= 10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEBD6FB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD6BDF1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${participants.length} in the room',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4A2E3A),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: participants
                    .map(
                      (person) => AppAvatarChip(
                        name: person.name,
                        isHost: person.id == room.hostId,
                        isYou: person.id == currentUserId,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Suggestions ${room.options.length}/10',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5F3A47),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: AppAutocompleteField(
                      externalController: optionController,
                      options: cuisines,
                      enabled: !atLimit,
                      hintText: 'Type cuisine or custom place...',
                      maxLength: 64,
                    ),
                  ),
                  const SizedBox(width: 10),
                  AppButton(
                    width: 110,
                    onPressed: (addingOption || atLimit) ? null : onAddOption,
                    loading: addingOption,
                    text: 'Add',
                  ),
                ],
              ),
              if (atLimit)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    '10 options reached.',
                    style: TextStyle(
                      color: Color(0xFF8A6272),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...room.options.map(
          (option) => _SuggestionCard(
            key: ValueKey(option.id),
            name: option.name,
            animate: option.id == highlightedOptionId,
          ),
        ),
        if (room.options.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: AppEmptyState(
              message: 'No suggestions yet. Add one to get started.',
            ),
          ),
        const SizedBox(height: 14),
        if (!isHost)
          const AppSectionCard(
            backgroundColor: Color(0xFFBADFDB),
            borderColor: Color(0xFFA5D0CB),
            child: Text(
              'Waiting for host to start voting...',
              style: TextStyle(
                color: Color(0xFF365C58),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (isHost)
          AppSectionCard(
            backgroundColor: const Color(0xFFFFBDBD),
            borderColor: const Color(0xFFFFA4A4),
            child: AppButton(
              onPressed: (room.options.length < 2 || startingVote)
                  ? null
                  : onStartVoting,
              loading: startingVote,
              text: 'Start voting',
            ),
          ),
      ],
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({super.key, required this.name, required this.animate});

  final String name;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: animate ? 0.8 : 1, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.restaurant_menu_rounded),
          title: Text(name),
        ),
      ),
    );
  }
}
