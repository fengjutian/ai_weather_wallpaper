import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;
import 'dart:ui' show ImageFilter;

/// A frosted-glass style button widget.
///
/// Renders a translucent background with a blur effect, mimicking
/// frosted glass. Typically used over dark wallpapers or gradient
/// backgrounds where the blur enhances readability.
///
/// ```dart
/// GlassButton(
///   label: 'Generate',
///   icon: Icons.auto_awesome,
///   onPressed: () => print('tapped'),
/// )
/// ```
class GlassButton extends StatefulWidget {
  /// Text label displayed on the button.
  final String label;

  /// Optional icon shown before the label.
  final IconData? icon;

  /// Callback invoked when the button is tapped.
  final VoidCallback? onPressed;

  /// Optional background color tint (applied with opacity).
  final Color? color;

  const GlassButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.color,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = (widget.color ?? theme.colorScheme.secondary).withOpacity(isDark ? 0.25 : 0.18);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: bgColor,
          child: InkWell(
            onTap: widget.onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: textColor, size: 20),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    widget.label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
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
