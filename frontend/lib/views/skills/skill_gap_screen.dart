import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/skill_provider.dart';
import '../../widgets/app_nav_shell.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/score_gauge.dart';
import '../../widgets/skill_chip.dart';

class SkillGapScreen extends StatefulWidget {
  const SkillGapScreen({super.key});

  @override
  State<SkillGapScreen> createState() => _SkillGapScreenState();
}

class _SkillGapScreenState extends State<SkillGapScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final skillProv = context.read<SkillProvider>();
      skillProv.loadRecommendations();
      skillProv.loadSkillGaps();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skillProv = context.watch<SkillProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppNavShell(
      selectedIndex: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Skill Gap & Career Roadmap', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                skillProv.loadRecommendations();
                skillProv.loadSkillGaps();
              },
              tooltip: 'Refresh',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.trending_up_rounded, size: 18), text: 'Career Progression'),
              Tab(icon: Icon(Icons.school_outlined, size: 18), text: 'Skill Gaps & Courses'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Career Progression
            skillProv.isLoading
                ? const LoadingIndicator(message: 'Generating career progression trajectories...')
                : skillProv.recommendations.isEmpty
                    ? EmptyStateView(
                        icon: Icons.alt_route_outlined,
                        title: 'No career paths available',
                        description: 'Upload your latest resume to discover customized career advancement paths.',
                        actionText: 'Generate Paths',
                        onAction: () => skillProv.loadRecommendations(),
                      )
                    : RefreshIndicator(
                        onRefresh: () => skillProv.loadRecommendations(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          itemCount: skillProv.recommendations.length,
                          itemBuilder: (context, index) {
                            final rec = skillProv.recommendations[index];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(rec.roleTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  if (rec.salaryRange != null) ...[
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.success.withOpacity(0.12),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        rec.salaryRange!,
                                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                  ],
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary.withOpacity(0.12),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      '${rec.demandLevel} Demand',
                                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        ScoreGauge(
                                          score: rec.matchPercentage,
                                          radius: 36,
                                          lineWidth: 6,
                                          title: 'Match',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // Missing Skills to Acquire
                                    if (rec.skillGaps.isNotEmpty) ...[
                                      const Text('Skills to Bridge:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: rec.skillGaps.map((sg) => SkillChip(label: sg, isMissing: true)).toList(),
                                      ),
                                      const SizedBox(height: 14),
                                    ],

                                    // Next Steps Roadmap
                                    if (rec.nextSteps.isNotEmpty) ...[
                                      const Text('Actionable Next Steps:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      ...rec.nextSteps.map(
                                        (step) => Padding(
                                          padding: const EdgeInsets.only(bottom: 6),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Icon(Icons.check_circle_outline, size: 16, color: AppColors.primary),
                                              const SizedBox(width: 6),
                                              Expanded(child: Text(step, style: const TextStyle(fontSize: 13))),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

            // Tab 2: Skill Gaps & Learning Courses
            skillProv.isLoading
                ? const LoadingIndicator(message: 'Analyzing skill gaps...')
                : skillProv.skillGaps.isEmpty
                    ? EmptyStateView(
                        icon: Icons.school_outlined,
                        title: 'No skill gap data',
                        description: 'Upload a resume or select a target job role to perform gap analysis.',
                        actionText: 'Load Analysis',
                        onAction: () => skillProv.loadSkillGaps(),
                      )
                    : RefreshIndicator(
                        onRefresh: () => skillProv.loadSkillGaps(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          itemCount: skillProv.skillGaps.length,
                          itemBuilder: (context, index) {
                            final gap = skillProv.skillGaps[index];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Target Role: ${gap.targetRole}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Overall Readiness: ${gap.matchPercentage.toInt()}%',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
                                    ),
                                    const SizedBox(height: 16),

                                    // High Priority
                                    if (gap.highPriority.isNotEmpty) ...[
                                      const Row(
                                        children: [
                                          Icon(Icons.priority_high, size: 16, color: AppColors.error),
                                          SizedBox(width: 4),
                                          Text('High Priority Gaps (Crucial):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.error)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: gap.highPriority.map((s) => SkillChip(label: s, priority: 'high')).toList(),
                                      ),
                                      const SizedBox(height: 14),
                                    ],

                                    // Medium Priority
                                    if (gap.mediumPriority.isNotEmpty) ...[
                                      const Row(
                                        children: [
                                          Icon(Icons.trending_neutral, size: 16, color: AppColors.warning),
                                          SizedBox(width: 4),
                                          Text('Medium Priority Gaps:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.warning)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: gap.mediumPriority.map((s) => SkillChip(label: s, priority: 'medium')).toList(),
                                      ),
                                      const SizedBox(height: 14),
                                    ],

                                    // Course Recommendations
                                    if (gap.learningRecommendations.isNotEmpty) ...[
                                      const Text('Recommended Learning Resources:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      ...gap.learningRecommendations.map(
                                        (rec) => Card(
                                          color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                                          margin: const EdgeInsets.only(bottom: 8),
                                          child: ListTile(
                                            leading: const Icon(Icons.menu_book, color: AppColors.primary),
                                            title: Text(rec['skill'] ?? 'Skill Topic', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                            subtitle: Text(rec['recommendation'] ?? '', style: const TextStyle(fontSize: 12.5)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ],
        ),
      ),
    );
  }
}
