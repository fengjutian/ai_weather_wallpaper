import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:common_ui/themes/app_theme.dart';

/// 磨玻璃（毛玻璃）卡片 — Apple 风格半透明模糊面板
///
/// 使用 [BackdropFilter] 实现磨玻璃效果，配合圆角和半透明背景。
class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final double blurSigma;
  final double opacity;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 20,
    this.blurSigma = 20,
    this.opacity = 0.15,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(opacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 磨玻璃容器 — 全尺寸磨玻璃面板
class GlassScaffold extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const GlassScaffold({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 背景渐变
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A0A1A),
                  Color(0xFF12122E),
                  Color(0xFF1A1040),
                  Color(0xFF0A0A1A),
                ],
              ),
            ),
          ),
        ),
        // 模糊光斑装饰
        Positioned(
          top: -100,
          right: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary.withOpacity(0.08),
            ),
          ),
        ),
        Positioned(
          bottom: -80,
          left: -40,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.secondary.withOpacity(0.06),
            ),
          ),
        ),
        // 内容
        SafeArea(child: Padding(padding: padding, child: child)),
      ],
    );
  }
}
