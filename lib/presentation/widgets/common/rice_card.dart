import 'package:flutter/material.dart';
import '../../../core/constants/rice_colors.dart';

class RiceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const RiceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: RiceColors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RiceColors.borderLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: card,
      );
    }

    return card;
  }
}
