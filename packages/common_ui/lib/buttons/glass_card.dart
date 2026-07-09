import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;
import '../themes/app_theme.dart';

/// Helper: returns a theme-adaptive text color for glass surfaces.
Color _textColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;

Color _mutedColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.black54;

Color _subtleColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white38
        : Colors.black26;

Color _glassBg(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.06);

Color _glassBorder(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.08);

Color _glassOverlay(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withOpacity(0.15)
        : Colors.black.withOpacity(0.06);

/// A frosted-glass card with blurred background — theme-aware.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final double blurSigma;
  final Color? backgroundColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 20,
    this.blurSigma = 10,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor ?? _glassOverlay(context),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: _glassBorder(context)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A frosted-glass styled app bar replacement — theme-aware.
class GlassAppBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final EdgeInsetsGeometry padding;

  const GlassAppBar({
    super.key,
    required this.title,
    this.actions,
    this.onBack,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    final textColor = _textColor(context);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: _glassBg(context).withOpacity(0.5),
            border: Border(bottom: BorderSide(color: _glassBorder(context))),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                if (onBack != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _CircleButton(icon: Icons.arrow_back_ios_new, onTap: onBack!),
                  ),
                Expanded(
                  child: Text(title,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
                ),
                if (actions != null) ...actions!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Material(
          color: _glassBg(context),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(icon, size: 16, color: _mutedColor(context)),
            ),
          ),
        ),
      ),
    );
  }
}
