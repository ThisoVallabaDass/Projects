import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// A glassmorphic card widget with subtle blur and border effects.
/// Perfect for the "glass and whitespace" design language.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 20,
    this.backgroundColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? TinyTrailsColors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: TinyTrailsColors.glassBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: TinyTrailsColors.charcoal.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
