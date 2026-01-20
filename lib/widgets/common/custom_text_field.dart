import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? labelText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final int? maxLines;
  final int? minLines;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final double? borderRadius;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.minLines,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.readOnly = false,
    this.onTap,
    this.focusNode,
    this.textInputAction,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              labelText!,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ],
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            // Theme data handles borders and colors, but we can override radius
            border: borderRadius != null 
              ? OutlineInputBorder(borderRadius: BorderRadius.circular(borderRadius!), borderSide: BorderSide.none)
              : null,
            enabledBorder: borderRadius != null
              ? OutlineInputBorder(borderRadius: BorderRadius.circular(borderRadius!), borderSide: BorderSide(color: Colors.transparent))
              : null,
            focusedBorder: borderRadius != null
              ? OutlineInputBorder(borderRadius: BorderRadius.circular(borderRadius!), borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2))
              : null,
          ),
          style: Theme.of(context).textTheme.bodyLarge,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          minLines: minLines,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          inputFormatters: inputFormatters,
          readOnly: readOnly,
          onTap: onTap,
          focusNode: focusNode,
          textInputAction: textInputAction,
        ),
      ],
    );
  }
}
