import 'package:flutter/material.dart';
import '../../core/constants.dart';

class TemplateChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const TemplateChip({
    Key? key,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(
        label,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      backgroundColor: AppColors.surface,
      onPressed: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.primary),
      ),
    );
  }
}
