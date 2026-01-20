import 'package:flutter/material.dart';

enum CustomButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final CustomButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final Color? customColor;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = CustomButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == CustomButtonVariant.outline || variant == CustomButtonVariant.ghost
                  ? theme.primaryColor
                  : Colors.white,
            ),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: 8),
        ],
        Text(text),
      ],
    );

    Widget button;

    switch (variant) {
      case CustomButtonVariant.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: customColor != null 
            ? ElevatedButton.styleFrom(backgroundColor: customColor) 
            : null,
          child: buttonContent,
        );
        break;
      case CustomButtonVariant.secondary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: Colors.white,
          ),
          child: buttonContent,
        );
        break;
      case CustomButtonVariant.outline:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: customColor != null 
            ? OutlinedButton.styleFrom(foregroundColor: customColor, side: BorderSide(color: customColor!)) 
            : null,
          child: buttonContent,
        );
        break;
      case CustomButtonVariant.ghost:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: customColor != null 
            ? TextButton.styleFrom(foregroundColor: customColor) 
            : null,
          child: buttonContent,
        );
        break;
    }

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }
}
