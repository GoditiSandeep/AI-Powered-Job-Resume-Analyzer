import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../core/theme/app_colors.dart';

class ScoreGauge extends StatelessWidget {
  final double score;
  final double radius;
  final double lineWidth;
  final String title;
  final String? subtitle;
  final bool showPercentSign;

  const ScoreGauge({
    super.key,
    required this.score,
    this.radius = 65.0,
    this.lineWidth = 10.0,
    this.title = 'ATS Score',
    this.subtitle,
    this.showPercentSign = true,
  });

  Color _getScoreColor(double val) {
    if (val >= 80) return AppColors.scoreHigh;
    if (val >= 60) return AppColors.scoreMedium;
    return AppColors.scoreLow;
  }

  @override
  Widget build(BuildContext context) {
    final clampedScore = score.clamp(0.0, 100.0);
    final scoreColor = _getScoreColor(clampedScore);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularPercentIndicator(
          radius: radius,
          lineWidth: lineWidth,
          animation: true,
          animationDuration: 1200,
          percent: clampedScore / 100.0,
          circularStrokeCap: CircularStrokeCap.round,
          progressColor: scoreColor,
          backgroundColor: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
          center: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${clampedScore.toInt()}${showPercentSign ? '%' : ''}',
                style: TextStyle(
                  fontSize: radius * 0.42,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: radius * 0.18,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
            ],
          ),
        ),
        if (title.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ],
    );
  }
}

class ScoreBar extends StatelessWidget {
  final String label;
  final double score;
  final double maxScore;
  final Color? color;

  const ScoreBar({
    super.key,
    required this.label,
    required this.score,
    this.maxScore = 100.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ratio = (score / maxScore).clamp(0.0, 1.0);
    final barColor = color ?? (ratio >= 0.8 ? AppColors.scoreHigh : (ratio >= 0.6 ? AppColors.scoreMedium : AppColors.scoreLow));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              Text(
                '${score.toInt()} / ${maxScore.toInt()}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearPercentIndicator(
            lineHeight: 8.0,
            percent: ratio,
            animation: true,
            animationDuration: 1000,
            progressColor: barColor,
            backgroundColor: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
            barRadius: const Radius.circular(4),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
