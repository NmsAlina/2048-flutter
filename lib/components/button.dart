import 'package:flutter/material.dart';

class ButtonWidget extends StatelessWidget {
  const ButtonWidget({
    Key? key,
    this.text,
    this.icon,
    required this.onPressed,
    required this.backgroundColor,
    required this.textColor,
    required this.isLightMode,
  }) : super(key: key);

  final String? text;
  final IconData? icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final bool isLightMode;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ButtonStyle(
        padding: MaterialStateProperty.all<EdgeInsets>(
          const EdgeInsets.all(16.0),
        ),
        backgroundColor: MaterialStateProperty.all<Color>(
          backgroundColor,
        ),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, color: textColor),
          if (text != null && icon != null) SizedBox(width: 8),
          if (text != null)
            Text(
              text!,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
                color: textColor,
              ),
            ),
        ],
      ),
    );
  }
}
