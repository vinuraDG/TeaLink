import 'package:TeaLink/constants/colors.dart';
import 'package:flutter/material.dart';

// If you already defined kBlack somewhere, keep it.
// For now, I'll assume it's Colors.black.


class DashboardCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final String? subtitle;
  final String? label;
  final bool disabled;
  final bool isWide;
  final VoidCallback? onTap;

  const DashboardCard({
    super.key,
    required this.title,
    this.icon,
    this.subtitle,
    this.label,
    this.disabled = false,
    this.isWide = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: isWide ? double.infinity : 155,
      height: 145,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: disabled ? Colors.grey[200] : Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: kBlack,
            blurRadius: 4,
            offset: Offset(3, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (label != null)
            Text(
              label!,
              style: const TextStyle(
                color: kBlack,
                  fontSize: 30, fontWeight: FontWeight.bold),
            ),
          if (icon != null)
            Icon(
              icon,
              color: kMainColor,
              size: 60,
            ),
          const SizedBox(height: 5),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800,color: kBlack),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500),
            ),
        ],
      ),
    );

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: card,
    );
  }
}
