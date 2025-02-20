import 'package:flutter/material.dart';
import 'package:home_app/theme/color.dart';

class CardStyles {
  static BorderRadius defaultRadius = BorderRadius.circular(8.0);
  static EdgeInsets defaultPadding = const EdgeInsets.all(16.0);

  static BoxDecoration cardDecoration(BuildContext context) {
    return BoxDecoration(
      borderRadius: defaultRadius,
      color: Theme.of(context).cardColor,
      boxShadow: [
        BoxShadow(
          color: AppColors.shadowColor.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
