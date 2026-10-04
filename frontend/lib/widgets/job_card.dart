import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/job_model.dart';
import 'skill_chip.dart';

class JobCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback onTap;
  final VoidCallback? onSaveToggle;
  final VoidCallback? onApply;
  final bool showMatchScore;

  const JobCard({
    super.key,
    required this.job,
    required this.onTap,
    this.onSaveToggle,
    this.onApply,
    this.showMatchScore = true,
  });

  Color _getMatchColor(double score) {
    if (score >= 80) return AppColors.scoreHigh;
    if (score >= 60) return AppColors.scoreMedium;
    return AppColors.scoreLow;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Company Logo Avatar, Title, Company, Bookmark
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        job.company.isNotEmpty ? job.company[0].toUpperCase() : 'J',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          job.company,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onSaveToggle != null)
                    IconButton(
                      icon: Icon(
                        job.isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: job.isSaved ? AppColors.primary : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                      ),
                      onPressed: onSaveToggle,
                      tooltip: job.isSaved ? 'Remove from saved' : 'Save job',
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Badges: Location, Employment Type, Salary, Match Percentage
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildTag(Icons.location_on_outlined, job.location, isDark),
                  _buildTag(Icons.work_outline, job.employmentType, isDark),
                  if (job.salary != null && job.salary!.isNotEmpty)
                    _buildTag(Icons.attach_money, job.salary!, isDark, isHighlight: true),
                  if (showMatchScore && job.matchPercentage != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getMatchColor(job.matchPercentage!).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _getMatchColor(job.matchPercentage!).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, size: 13, color: _getMatchColor(job.matchPercentage!)),
                          const SizedBox(width: 4),
                          Text(
                            '${job.matchPercentage!.toInt()}% Match',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _getMatchColor(job.matchPercentage!),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Skills preview (Top 3)
              if (job.requiredSkills.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: job.requiredSkills.take(3).map((skill) => SkillChip(label: skill)).toList(),
                ),

              // Application status if applied
              if (job.applicationStatus != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.send_rounded, size: 14, color: AppColors.info),
                    const SizedBox(width: 4),
                    Text(
                      'Status: ${job.applicationStatus}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.info),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(IconData icon, String text, bool isDark, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlight
            ? AppColors.primary.withOpacity(0.12)
            : (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: isHighlight ? AppColors.primary : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
              color: isHighlight ? AppColors.primary : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
          ),
        ],
      ),
    );
  }
}
