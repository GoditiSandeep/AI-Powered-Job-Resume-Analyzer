import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class SkillChip extends StatelessWidget {
  final String label;
  final bool isMatched;
  final bool isMissing;
  final String? priority; // 'high', 'medium', 'low'
  final VoidCallback? onDeleted;
  final VoidCallback? onTap;

  const SkillChip({
    super.key,
    required this.label,
    this.isMatched = false,
    this.isMissing = false,
    this.priority,
    this.onDeleted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;
    Color border;

    if (isMatched) {
      bg = AppColors.success.withOpacity(isDark ? 0.2 : 0.1);
      fg = AppColors.success;
      border = AppColors.success.withOpacity(0.4);
    } else if (isMissing) {
      bg = AppColors.error.withOpacity(isDark ? 0.2 : 0.1);
      fg = AppColors.error;
      border = AppColors.error.withOpacity(0.4);
    } else if (priority == 'high') {
      bg = AppColors.error.withOpacity(isDark ? 0.2 : 0.1);
      fg = AppColors.error;
      border = AppColors.error.withOpacity(0.4);
    } else if (priority == 'medium') {
      bg = AppColors.warning.withOpacity(isDark ? 0.2 : 0.1);
      fg = AppColors.warning;
      border = AppColors.warning.withOpacity(0.4);
    } else {
      bg = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight;
      fg = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
      border = isDark ? AppColors.borderDark : AppColors.borderLight;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMatched) ...[
              const Icon(Icons.check_circle, size: 14, color: AppColors.success),
              const SizedBox(width: 4),
            ] else if (isMissing) ...[
              const Icon(Icons.cancel, size: 14, color: AppColors.error),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
            if (priority != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: fg.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  priority!.toUpperCase(),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: fg),
                ),
              ),
            ],
            if (onDeleted != null) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: onDeleted,
                child: Icon(Icons.close, size: 14, color: fg),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
