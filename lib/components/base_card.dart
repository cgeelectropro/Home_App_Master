import 'package:flutter/material.dart';
import 'package:home_app/components/card_styles.dart';

class BaseCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final double elevation;

  const BaseCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.elevation = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: CardStyles.defaultRadius,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: CardStyles.defaultRadius,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
