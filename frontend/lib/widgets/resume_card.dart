import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../models/resume_model.dart';
import 'score_gauge.dart';

class ResumeCard extends StatelessWidget {
  final ResumeModel resume;
  final VoidCallback onTap;
  final VoidCallback? onReanalyze;
  final VoidCallback? onDelete;

  const ResumeCard({
    super.key,
    required this.resume,
    required this.onTap,
    this.onReanalyze,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formattedDate = resume.createdAt != null
        ? DateFormat('MMM dd, yyyy').format(resume.createdAt!)
        : 'Uploaded recently';

    final hasScore = resume.latestScore != null || resume.latestAtsScore != null;
    final atsScore = resume.latestAtsScore ?? resume.latestScore ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon or Mini Score Gauge
              if (hasScore)
                ScoreGauge(
                  score: atsScore,
                  radius: 28,
                  lineWidth: 5,
                  title: '',
                )
              else
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Icon(Icons.description_outlined, color: AppColors.primary, size: 28),
                  ),
                ),
              const SizedBox(width: 14),

              // File Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resume.fileName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            resume.fileType.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    if (hasScore) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, size: 13, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'ATS Match Score: ${atsScore.toInt()}%',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Popup Menu Actions
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                onSelected: (val) {
                  if (val == 'view') onTap();
                  if (val == 'reanalyze') onReanalyze?.call();
                  if (val == 'delete') onDelete?.call();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.analytics_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('View Analysis'),
                      ],
                    ),
                  ),
                  if (onReanalyze != null)
                    const PopupMenuItem(
                      value: 'reanalyze',
                      child: Row(
                        children: [
                          Icon(Icons.refresh_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Re-analyze'),
                        ],
                      ),
                    ),
                  if (onDelete != null)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
