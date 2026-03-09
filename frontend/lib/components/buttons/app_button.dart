import 'package:flutter/material.dart';

enum AppButtonVariant { filled, outlined }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.width,
    this.height = 52,
    this.loading = false,
    this.fullWidth = true,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.variant = AppButtonVariant.filled,
  });

  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double? width;
  final double height;
  final bool loading;
  final bool fullWidth;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final isOutlined = variant == AppButtonVariant.outlined;
    final disabled = loading || onPressed == null;
    final resolvedOnPressed = disabled ? null : onPressed;

    final label = loading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: foregroundColor,
            ),
          )
        : icon == null
            ? Text(text)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                  Text(text),
                ],
              );

    final button = isOutlined
        ? OutlinedButton(
            onPressed: resolvedOnPressed,
            style: OutlinedButton.styleFrom(
              minimumSize: Size(fullWidth ? double.infinity : 0, height),
              side: BorderSide(color: borderColor ?? const Color(0xFFF4C2B7)),
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: label,
          )
        : ElevatedButton(
            onPressed: resolvedOnPressed,
            style: ElevatedButton.styleFrom(
              minimumSize: Size(fullWidth ? double.infinity : 0, height),
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: label,
          );

    return width == null ? button : SizedBox(width: width, child: button);
  }
}
