import 'package:flutter/material.dart';

class DeviceStatusIndicator extends StatelessWidget {
  final bool isConnected;
  final bool isActive;
  final double size;

  const DeviceStatusIndicator({
    super.key,
    required this.isConnected,
    required this.isActive,
    this.size = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    Color indicatorColor;
    if (!isConnected) {
      indicatorColor = Colors.grey;
    } else if (isActive) {
      indicatorColor = Colors.green;
    } else {
      indicatorColor = Colors.red;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: indicatorColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: indicatorColor.withOpacity(0.4),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
