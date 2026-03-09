import 'package:flutter/material.dart';

import '../models.dart';
import 'countdown_widget.dart';
import 'option_tile.dart';

class VotingSection extends StatefulWidget {
  const VotingSection({
    super.key,
    required this.room,
    required this.votedOptionId,
    required this.onVote,
    required this.onCountdownDone,
  });

  final RoomModel room;
  final String? votedOptionId;
  final Future<void> Function(String optionId) onVote;
  final Future<void> Function() onCountdownDone;

  @override
  State<VotingSection> createState() => _VotingSectionState();
}

class _VotingSectionState extends State<VotingSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFBDBD),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: const Color(0xFFFFA4A4)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -8,
                    top: 6 + (t * 8),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0x66EBD6FB),
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 44,
                    bottom: -10 + (t * 6),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0x66BADFDB),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cast your vote',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF4A2E3A),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Choose the place that looks best right now.',
                        style: TextStyle(
                          color: Color(0xFF5F3A47),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        CountdownWidget(endTime: widget.room.endTime, onDone: widget.onCountdownDone),
        const SizedBox(height: 16),
        ...widget.room.options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          return OptionTile(
            option: option,
            colorIndex: index,
            disabled: widget.votedOptionId != null,
            selected: widget.votedOptionId == option.id,
            onTap: () => widget.onVote(option.id),
          );
        }),
      ],
    );
  }
}
