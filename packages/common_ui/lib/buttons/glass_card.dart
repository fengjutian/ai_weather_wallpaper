import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;
import '../themes/app_theme.dart';

/// A frosted-glass card with blurred background.
///
/// Renders a translucent card with a `BackdropFilter` blur effect,
/// mimicking the Apple macOS / iOS frosted-glass aesthetic.
///
/// ```dart
/// GlassCard(
///   child: Text('Hello'),
/// )
/// ```
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
              color: (backgroundColor ?? AppTheme.glassOverlay)
                  .withOpacity(0.15),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A frosted-glass styled app bar replacement.
///
/// Use at the top of a [Stack] to overlay a translucent title bar.
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
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppTheme.glassOverlay.withOpacity(0.12),
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                if (onBack != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _CircleButton(
                      icon: Icons.arrow_back_ios_new,
                      onTap: onBack!,
                    ),
                  ),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
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

/// A small circular icon button for glass headers.
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
          color: Colors.white.withOpacity(0.08),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(icon, size: 16, color: Colors.white70),
            ),
          ),
        ),
      ),
    );
  }
}
