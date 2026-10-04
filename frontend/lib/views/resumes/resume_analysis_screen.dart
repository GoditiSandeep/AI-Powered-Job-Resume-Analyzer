import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/resume_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/score_gauge.dart';
import '../../widgets/skill_chip.dart';

class ResumeAnalysisScreen extends StatefulWidget {
  final int resumeId;

  const ResumeAnalysisScreen({super.key, required this.resumeId});

  @override
  State<ResumeAnalysisScreen> createState() => _ResumeAnalysisScreenState();
}

class _ResumeAnalysisScreenState extends State<ResumeAnalysisScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ResumeProvider>().loadAnalysis(widget.resumeId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showImproveDialog(String section, String originalText) {
    final textCtrl = TextEditingController(text: originalText);
    final targetCtrl = TextEditingController(text: 'Software Engineer');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          bool isImproving = false;
          String? improvedResult;
          String? reason;

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('AI Rewrite: $section', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: textCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Original Text to Improve'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: targetCtrl,
                    decoration: const InputDecoration(labelText: 'Target Role (Optional)', prefixIcon: Icon(Icons.work_outline)),
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Generate AI Improvement',
                    icon: Icons.auto_awesome,
                    isLoading: isImproving,
                    onPressed: () async {
                      setModalState(() => isImproving = true);
                      final imp = await context.read<ResumeProvider>().improveSectionText(
                            section: section,
                            originalText: textCtrl.text,
                            roleTarget: targetCtrl.text,
                          );
                      setModalState(() {
                        isImproving = false;
                        improvedResult = imp?.improved;
                        reason = imp?.reason;
                      });
                    },
                  ),
                  if (improvedResult != null) ...[
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.success.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle, color: AppColors.success, size: 18),
                              SizedBox(width: 8),
                              Text('Improved Version', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SelectableText(improvedResult!, style: const TextStyle(fontSize: 14, height: 1.4)),
                          if (reason != null) ...[
                            const Divider(height: 20),
                            Text('Why this is better: $reason', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resumeProv = context.watch<ResumeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final analysis = resumeProv.currentAnalysis;

    if (resumeProv.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Resume Analysis')),
        body: const LoadingIndicator(message: 'Analyzing resume metrics and ATS compatibility...'),
      );
    }

    if (analysis == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Resume Analysis')),
        body: EmptyStateView(
          icon: Icons.analytics_outlined,
          title: 'No analysis available',
          description: 'Could not fetch analysis data for this resume.',
          actionText: 'Analyze Now',
          onAction: () => resumeProv.reanalyzeResume(widget.resumeId),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Intelligence Report', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => resumeProv.reanalyzeResume(widget.resumeId),
            tooltip: 'Re-analyze',
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report copied to clipboard!')),
              );
            },
            tooltip: 'Share Report',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined, size: 18), text: 'Overview'),
            Tab(icon: Icon(Icons.insights_outlined, size: 18), text: 'Keywords & Skills'),
            Tab(icon: Icon(Icons.auto_fix_high_outlined, size: 18), text: 'AI Improvements'),
            Tab(icon: Icon(Icons.segment_outlined, size: 18), text: 'Sections'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Overview
          _buildOverviewTab(analysis, isDark),
          // Tab 2: Keywords & Skills
          _buildKeywordsTab(analysis, isDark),
          // Tab 3: AI Improvements
          _buildImprovementsTab(analysis, isDark),
          // Tab 4: Sections
          _buildSectionsTab(analysis, isDark),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(dynamic analysis, bool isDark) {
    final double ats = analysis.atsScore ?? 0.0;
    final double overall = analysis.overallScore ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score Highlight Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ScoreGauge(
                    score: ats,
                    radius: 54,
                    lineWidth: 8,
                    title: 'ATS Pass Score',
                    subtitle: 'Compatibility',
                  ),
                  ScoreGauge(
                    score: overall,
                    radius: 54,
                    lineWidth: 8,
                    title: 'Overall Quality',
                    subtitle: 'Impact',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Section Breakdown Bars
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Category Performance Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  ScoreBar(label: 'Impact & Quantifiable Metrics', score: (analysis.sectionScores['impact'] as num?)?.toDouble() ?? 75.0),
                  ScoreBar(label: 'Keywords & ATS Match', score: (analysis.sectionScores['keywords'] as num?)?.toDouble() ?? 80.0),
                  ScoreBar(label: 'Structure & Formatting', score: (analysis.sectionScores['structure'] as num?)?.toDouble() ?? 85.0),
                  ScoreBar(label: 'Clarity & Brevity', score: (analysis.sectionScores['clarity'] as num?)?.toDouble() ?? 78.0),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Strengths & Weaknesses
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Strengths
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.thumb_up_alt_outlined, color: AppColors.success, size: 18),
                            SizedBox(width: 8),
                            Text('Strengths', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.success)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if ((analysis.strengths as List).isEmpty)
                          const Text('Clean layout and structure.')
                        else
                          ...analysis.strengths.map(
                            (s) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
                                  Expanded(child: Text(s.toString(), style: const TextStyle(fontSize: 13))),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Weaknesses
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
                            SizedBox(width: 8),
                            Text('Areas to Improve', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.warning)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if ((analysis.weaknesses as List).isEmpty)
                          const Text('Add more quantifiable metrics.')
                        else
                          ...analysis.weaknesses.map(
                            (w) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning)),
                                  Expanded(child: Text(w.toString(), style: const TextStyle(fontSize: 13))),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Action Recommendations
          if ((analysis.recommendations as List).isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text('AI Action Plan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...analysis.recommendations.map(
                      (rec) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.arrow_right, color: AppColors.primary, size: 20),
                            const SizedBox(width: 4),
                            Expanded(child: Text(rec.toString(), style: const TextStyle(fontSize: 13.5))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKeywordsTab(dynamic analysis, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Detected Skills & Keywords
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                      SizedBox(width: 8),
                      Text('Detected Skills & Keywords', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if ((analysis.detectedKeywords as List).isEmpty)
                    const Text('No technical keywords detected.')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (analysis.detectedKeywords as List)
                          .map((kw) => SkillChip(label: kw.toString(), isMatched: true))
                          .toList(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Missing Keywords (High Priority for ATS)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.add_alert_outlined, color: AppColors.error, size: 20),
                      SizedBox(width: 8),
                      Text('Missing High-Impact ATS Keywords', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Adding these industry-relevant terms will significantly increase your resume search visibility.',
                    style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: 12),
                  if ((analysis.missingKeywords as List).isEmpty)
                    const Text('Great job! No major keywords missing.')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (analysis.missingKeywords as List)
                          .map((kw) => SkillChip(label: kw.toString(), isMissing: true))
                          .toList(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementsTab(dynamic analysis, bool isDark) {
    final improvements = analysis.improvements as List;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Smart Bullet Point Rewriter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _showImproveDialog('Experience', 'Built APIs and helped team with bugs.'),
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('Custom Rewrite'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (improvements.isEmpty)
            EmptyStateView(
              icon: Icons.auto_awesome_outlined,
              title: 'No specific bullet suggestions',
              description: 'Use the Custom Rewrite tool above to transform any bullet point into high-impact phrasing.',
              actionText: 'Try Custom Rewrite',
              onAction: () => _showImproveDialog('Experience', 'Built APIs and helped team with bugs.'),
            )
          else
            ...improvements.map(
              (imp) => Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          imp.section.toString().toUpperCase(),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Original
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              imp.original.toString(),
                              style: TextStyle(
                                fontSize: 13.5,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Improved
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SelectableText(
                              imp.improved.toString(),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.success),
                            ),
                          ),
                        ],
                      ),
                      if (imp.reason != null && imp.reason.toString().isNotEmpty) ...[
                        const Divider(height: 18),
                        Text(
                          'Why: ${imp.reason}',
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionsTab(dynamic analysis, bool isDark) {
    final skills = analysis.skills as List;
    final education = analysis.education as List;
    final experience = analysis.experience as List;
    final projects = analysis.projects as List;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard('Work Experience', Icons.work_outline, experience, isDark),
          const SizedBox(height: 16),
          _buildSectionCard('Education', Icons.school_outlined, education, isDark),
          const SizedBox(height: 16),
          _buildSectionCard('Projects & Portfolio', Icons.code_rounded, projects, isDark),
          const SizedBox(height: 16),
          _buildSectionCard('Skills Inventory', Icons.build_outlined, skills, isDark),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<dynamic> items, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Text('No items extracted for $title.', style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))
            else
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: Text(item.toString(), style: const TextStyle(fontSize: 13.5))),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
