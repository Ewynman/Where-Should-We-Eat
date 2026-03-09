import 'package:flutter/material.dart';

import '../models.dart';

class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.option,
    required this.colorIndex,
    required this.disabled,
    required this.selected,
    required this.onTap,
  });

  final OptionModel option;
  final int colorIndex;
  final bool disabled;
  final bool selected;
  final VoidCallback onTap;

  static const _accents = [
    Color(0xFF87C5FF),
    Color(0xFFBADFDB),
    Color(0xFFFFBDBD),
    Color(0xFFEBD6FB),
  ];

  @override
  Widget build(BuildContext context) {
    return option.isRestaurant ? _buildRestaurantCard() : _buildCuisineCard();
  }

  Widget _buildCuisineCard() {
    final accent = _accents[colorIndex % _accents.length];
    final cardBorder = selected
        ? const Color(0xFFFFA4A4)
        : const Color(0xFFDCCEEB);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: selected ? 0.28 : 0.12),
            blurRadius: selected ? 16 : 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: const Color(0xFFFCF9EA),
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: const Color(0x40FF7FA3),
          highlightColor: const Color(0x20FFA88A),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: cardBorder, width: selected ? 2 : 1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.restaurant_menu_rounded,
                        color: accent,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            option.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF4A2E3A),
                            ),
                          ),
                          if (option.cuisineType != null &&
                              option.cuisineType!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              option.cuisineType!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF8A6272),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F0),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '${option.voteCount} ${option.voteCount == 1 ? 'vote' : 'votes'}',
                        style: const TextStyle(
                          color: Color(0xFF8A6272),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantCard() {
    final accent = _accents[colorIndex % _accents.length];
    final cardBorder = selected
        ? const Color(0xFFFFA4A4)
        : const Color(0xFFDCCEEB);
    final highlights = option.menuHighlights.take(3).toList();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: selected ? 0.28 : 0.12),
            blurRadius: selected ? 16 : 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: const Color(0xFFFCF9EA),
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: const Color(0x40FF7FA3),
          highlightColor: const Color(0x20FFA88A),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: cardBorder, width: selected ? 2 : 1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 130,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _RestaurantImage(
                          imageUrl: option.imageUrl,
                          title: option.name,
                          accent: accent,
                        ),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: _BadgeChip(
                            text: option.cuisineType ?? 'Cuisine pending',
                            icon: Icons.restaurant_menu_rounded,
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: _BadgeChip(
                            text: option.rating == null
                                ? 'N/A'
                                : option.rating!.toStringAsFixed(1),
                            icon: Icons.star_rounded,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                option.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF4A2E3A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF0F0),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                '${option.voteCount} ${option.voteCount == 1 ? 'vote' : 'votes'}',
                                style: const TextStyle(
                                  color: Color(0xFF8A6272),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (option.address != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            option.address!,
                            style: const TextStyle(
                              color: Color(0xFF8A6272),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        const Text(
                          'Menu highlights',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7D4C5F),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 7),
                        if (highlights.isEmpty)
                          const Text(
                            'No highlights yet - backend will provide these soon.',
                            style: TextStyle(
                              color: Color(0xFF8A6272),
                              fontSize: 13,
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: highlights
                                .map(
                                  (item) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEBD6FB),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      item,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF5F3A47),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCC8A6272),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Color(0xFFFFF4E8)),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(
                color: Color(0xFFFFF4E8),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestaurantImage extends StatelessWidget {
  const _RestaurantImage({
    required this.imageUrl,
    required this.title,
    required this.accent,
  });

  final String? imageUrl;
  final String title;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _placeholder();
        },
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [accent, accent],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF4A2E3A),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
