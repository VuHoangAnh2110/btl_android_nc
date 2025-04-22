import 'package:flutter/material.dart';

class OptionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? arrowColor;

  const OptionItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.arrowColor = Colors.grey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
          children: [
            Icon(icon,
                color: iconColor ?? Theme.of(context).colorScheme.primary),
            SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: arrowColor),
          ],
        ),
      ),
    );
  }
}
