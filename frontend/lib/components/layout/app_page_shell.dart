import 'package:flutter/material.dart';

import '../../constants/ui_tokens.dart';

class AppPageShell extends StatelessWidget {
  const AppPageShell({
    super.key,
    required this.child,
    this.maxContentWidth,
    this.padding = const EdgeInsets.fromLTRB(20, 14, 20, 20),
    this.backgroundColor = AppColors.background,
    this.alignTop = true,
  });

  final Widget child;
  final double? maxContentWidth;
  final EdgeInsets padding;
  final Color backgroundColor;
  final bool alignTop;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: backgroundColor),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final maxWidth =
                maxContentWidth ?? (isWide ? 760.0 : constraints.maxWidth);

            return Align(
              alignment: alignTop ? Alignment.topCenter : Alignment.center,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                  padding: isWide
                      ? EdgeInsets.fromLTRB(
                          AppSpacing.xl,
                          padding.top,
                          AppSpacing.xl,
                          padding.bottom,
                        )
                      : padding,
                  child: child,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
