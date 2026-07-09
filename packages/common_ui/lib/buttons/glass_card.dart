import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;

/// Creates theme-adaptive glass colors.
Color _glassFill(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withOpacity(0.06)
        : Colors.white.withOpacity(0.72);

Color _glassBorder(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withOpacity(0.08)
        : Colors.white.withOpacity(0.6);

Color _glassHeavy(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withOpacity(0.12)
        : Colors.white.withOpacity(0.85);

Color _textPrimary(BuildContext context) =>
    Theme.of(context).colorScheme.onSurface;

Color _textSecondary(BuildContext context) =>
    Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;

/// A frosted-glass card — theme-aware.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final double blurSigma;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 20,
    this.blurSigma = 20,
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
              color: _glassFill(context),
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

/// A frosted-glass app bar — theme-aware.
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
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: _glassHeavy(context),
            border: Border(bottom: BorderSide(color: _glassBorder(context))),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                if (onBack != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _CircleBtn(icon: Icons.arrow_back_ios_new, onTap: onBack!),
                  ),
                Expanded(
                  child: Text(title,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
                          color: _textPrimary(context))),
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

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: _glassFill(context),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(icon, size: 16, color: _textSecondary(context)),
            ),
          ),
        ),
      ),
    );
  }
}
