import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/application_provider.dart';
import '../../providers/job_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/score_gauge.dart';
import '../../widgets/skill_chip.dart';

class JobDetailScreen extends StatefulWidget {
  final int jobId;

  const JobDetailScreen({super.key, required this.jobId});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobProvider>().loadJobDetails(widget.jobId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showApplyModal(BuildContext context) {
    final notesController = TextEditingController();
    final appProv = context.read<ApplicationProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          bool isSubmitting = false;

          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Apply for Position', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Submit your application and track the status in your application pipeline.'),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Cover Note (Optional)',
                    hintText: 'Add any specific notes or referral details...',
                  ),
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: 'Submit Application',
                  icon: Icons.send_rounded,
                  isLoading: isSubmitting,
                  onPressed: () async {
                    setModalState(() => isSubmitting = true);
                    final success = await appProv.createApplication(
                      jobId: widget.jobId,
                      notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                    );
                    setModalState(() => isSubmitting = false);
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Application submitted successfully!'), backgroundColor: AppColors.success),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobProv = context.watch<JobProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final job = jobProv.selectedJob;
    final match = jobProv.currentJobMatch;

    if (jobProv.isLoading || job == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job Details')),
        body: const LoadingIndicator(message: 'Loading job specifics & ATS match scores...'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(job.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(job.isSaved ? Icons.bookmark : Icons.bookmark_border),
            color: job.isSaved ? AppColors.primary : null,
            onPressed: () => jobProv.toggleSaveJob(job),
            tooltip: job.isSaved ? 'Saved' : 'Save Job',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Job Details'),
            Tab(text: 'AI Match Analysis'),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Apply Now',
                icon: Icons.send_rounded,
                onPressed: () => _showApplyModal(context),
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Details
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(job.company, style: const TextStyle(fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildInfoChip(Icons.location_on_outlined, job.location),
                            _buildInfoChip(Icons.work_outline, job.employmentType),
                            _buildInfoChip(Icons.timeline_outlined, job.experience),
                            if (job.salary != null && job.salary!.isNotEmpty)
                              _buildInfoChip(Icons.attach_money, job.salary!, isHighlight: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Description
                const Text('Job Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text(
                      job.description,
                      style: const TextStyle(fontSize: 14.5, height: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Responsibilities
                if (job.responsibilities.isNotEmpty) ...[
                  const Text('Key Responsibilities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: job.responsibilities
                            .map(
                              (r) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                                    Expanded(child: Text(r, style: const TextStyle(fontSize: 14, height: 1.4))),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Required Skills
                const Text('Required Skills & Technologies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: job.requiredSkills.map((s) => SkillChip(label: s)).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),

          // Tab 2: AI Match Breakdown
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: match == null
                ? const Center(child: Text('Calculating match analysis...'))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Match Score Highlight
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              ScoreGauge(
                                score: match.overallMatchPercentage,
                                radius: 54,
                                lineWidth: 8,
                                title: 'Overall Match',
                              ),
                              ScoreGauge(
                                score: match.skillMatchScore,
                                radius: 54,
                                lineWidth: 8,
                                title: 'Skill Match',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Match Category Breakdown
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Match Criteria Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 14),
                              ScoreBar(label: 'Skill Compatibility', score: match.skillMatchScore),
                              ScoreBar(label: 'Keyword Alignment', score: match.keywordMatchScore),
                              ScoreBar(label: 'Experience Fit', score: match.experienceMatchScore),
                              ScoreBar(label: 'Education Fit', score: match.educationMatchScore),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Matched Skills
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
                                  Text('Matching Skills Found in Resume', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (match.matchedSkills.isEmpty)
                                const Text('No matching technical skills detected.')
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: match.matchedSkills.map((s) => SkillChip(label: s, isMatched: true)).toList(),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Missing Skills
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.cancel_outlined, color: AppColors.error, size: 20),
                                  SizedBox(width: 8),
                                  Text('Missing Skills for this Position', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (match.missingSkills.isEmpty)
                                const Text('You meet all required technical skills for this job!')
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: match.missingSkills.map((s) => SkillChip(label: s, isMissing: true)).toList(),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // AI Improvement Recommendations
                      if (match.improvementRecommendations.isNotEmpty) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                                    SizedBox(width: 8),
                                    Text('How to Maximize Your Match', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...match.improvementRecommendations.map(
                                  (rec) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.arrow_right, color: AppColors.primary, size: 20),
                                        const SizedBox(width: 4),
                                        Expanded(child: Text(rec, style: const TextStyle(fontSize: 13.5))),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 80),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isHighlight ? AppColors.primary.withOpacity(0.12) : AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: isHighlight ? AppColors.primary : AppColors.textSecondaryLight),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              color: isHighlight ? AppColors.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}
