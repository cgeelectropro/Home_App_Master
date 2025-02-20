import 'package:flutter/material.dart';

class ListDeviceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isConnecting;
  final Widget? trailing;

  const ListDeviceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.status,
    this.onTap,
    this.onLongPress,
    this.isConnecting = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = status.toLowerCase() == 'on';
    final deviceColor = Theme.of(context).primaryColor;

    return Card(
      elevation: isActive ? 2 : 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: isConnecting ? null : onTap,
        onLongPress: isConnecting ? null : onLongPress,
        leading: Stack(
          children: [
            Icon(
              _getDeviceIcon(title),
              color: isActive ? deviceColor : Colors.grey,
              size: 28,
            ),
            if (isConnecting)
              Positioned(
                right: 0,
                bottom: 0,
                child: SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(deviceColor),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? deviceColor : null,
            fontWeight: isActive ? FontWeight.bold : null,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: trailing ??
            Text(
              status.toUpperCase(),
              style: TextStyle(
                color: isActive ? deviceColor : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
      ),
    );
  }

  IconData _getDeviceIcon(String deviceName) {
    final name = deviceName.toLowerCase();
    if (name.contains('light')) return Icons.lightbulb_outline;
    if (name.contains('fan')) return Icons.air;
    if (name.contains('tv')) return Icons.tv;
    if (name.contains('ac')) return Icons.ac_unit;
    if (name.contains('door')) return Icons.door_front_door;
    if (name.contains('camera')) return Icons.camera_alt;
    return Icons.devices_other;
  }
}
