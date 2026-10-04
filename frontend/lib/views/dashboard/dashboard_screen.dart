import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/routing/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/resume_provider.dart';
import '../../providers/application_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/app_nav_shell.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/job_card.dart';
import '../../widgets/resume_card.dart';
import '../../widgets/score_gauge.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    final resumeProv = context.read<ResumeProvider>();
    final jobProv = context.read<JobProvider>();
    final appProv = context.read<ApplicationProvider>();

    await Future.wait([
      resumeProv.loadResumes(),
      jobProv.loadJobs(),
      jobProv.loadSavedJobs(),
      appProv.loadApplications(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final resumeProv = context.watch<ResumeProvider>();
    final jobProv = context.watch<JobProvider>();
    final appProv = context.watch<ApplicationProvider>();
    final theme = context.watch<ThemeProvider>();
    final isDark = theme.isDarkMode;

    final user = auth.currentUser;
    final userName = user?.name.isNotEmpty == true ? user!.name : 'Professional';

    // Calculate metrics
    final totalResumes = resumeProv.resumes.length;
    double avgScore = 0.0;
    if (totalResumes > 0) {
      final scoredResumes = resumeProv.resumes.where((r) => r.latestAtsScore != null || r.latestScore != null).toList();
      if (scoredResumes.isNotEmpty) {
        avgScore = scoredResumes.map((r) => r.latestAtsScore ?? r.latestScore ?? 0.0).reduce((a, b) => a + b) / scoredResumes.length;
      }
    }

    final activeApps = appProv.applications.length;
    final savedJobsCount = jobProv.savedJobs.length;

    return AppNavShell(
      selectedIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
              onPressed: () => theme.toggleTheme(!isDark),
              tooltip: 'Toggle Theme',
            ),
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () => context.go(RouteNames.profile),
              tooltip: 'Profile & Settings',
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Hero Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, $userName 👋',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Your AI career assistant is ready to optimize your resumes & applications.',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => context.go(RouteNames.resumeUpload),
                              icon: const Icon(Icons.upload_file, size: 18, color: AppColors.primaryDark),
                              label: const Text(
                                'Upload New Resume',
                                style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (avgScore > 0) ...[
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ScoreGauge(
                            score: avgScore,
                            radius: 38,
                            lineWidth: 6,
                            title: 'Avg ATS',
                            subtitle: 'Rating',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // KPI Stat Cards Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 600;
                    return GridView.count(
                      crossAxisCount: isWide ? 4 : 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: isWide ? 1.4 : 1.3,
                      children: [
                        _buildStatCard(
                          title: 'Resumes',
                          value: totalResumes.toString(),
                          icon: Icons.description_outlined,
                          color: AppColors.primary,
                          onTap: () => context.go(RouteNames.resumes),
                        ),
                        _buildStatCard(
                          title: 'Avg ATS Score',
                          value: avgScore > 0 ? '${avgScore.toInt()}%' : 'N/A',
                          icon: Icons.auto_awesome,
                          color: AppColors.success,
                          onTap: () => context.go(RouteNames.resumes),
                        ),
                        _buildStatCard(
                          title: 'Applications',
                          value: activeApps.toString(),
                          icon: Icons.assignment_turned_in_outlined,
                          color: AppColors.secondary,
                          onTap: () => context.go(RouteNames.applications),
                        ),
                        _buildStatCard(
                          title: 'Saved Jobs',
                          value: savedJobsCount.toString(),
                          icon: Icons.bookmark_border,
                          color: AppColors.warning,
                          onTap: () => context.go(RouteNames.savedJobs),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),

                // Quick Navigation Actions
                const Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildActionChip(
                        icon: Icons.upload_file,
                        label: 'Upload Resume',
                        color: AppColors.primary,
                        onTap: () => context.go(RouteNames.resumeUpload),
                      ),
                      const SizedBox(width: 10),
                      _buildActionChip(
                        icon: Icons.search,
                        label: 'Browse Jobs',
                        color: AppColors.secondary,
                        onTap: () => context.go(RouteNames.jobs),
                      ),
                      const SizedBox(width: 10),
                      _buildActionChip(
                        icon: Icons.insights,
                        label: 'Skill Gap & Roadmap',
                        color: AppColors.accent,
                        onTap: () => context.go(RouteNames.skillGap),
                      ),
                      if (auth.isAdmin) ...[
                        const SizedBox(width: 10),
                        _buildActionChip(
                          icon: Icons.admin_panel_settings,
                          label: 'Admin Portal',
                          color: AppColors.warning,
                          onTap: () => context.go(RouteNames.adminDashboard),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Recent Resumes Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recent Resumes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () => context.go(RouteNames.resumes),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (resumeProv.resumes.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.description_outlined, size: 40, color: AppColors.primary),
                            const SizedBox(height: 8),
                            const Text('No resumes uploaded yet', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            const Text('Upload your PDF or DOCX resume to get instant ATS feedback.'),
                            const SizedBox(height: 14),
                            ElevatedButton(
                              onPressed: () => context.go(RouteNames.resumeUpload),
                              child: const Text('Upload Resume'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ...resumeProv.resumes.take(3).map(
                        (resume) => ResumeCard(
                          resume: resume,
                          onTap: () => context.go(RouteNames.resumeAnalysis.replaceAll(':id', resume.id.toString())),
                        ),
                      ),
                const SizedBox(height: 24),

                // Recommended Jobs Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recommended Jobs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () => context.go(RouteNames.jobs),
                      child: const Text('Explore Jobs'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (jobProv.jobs.isEmpty)
                  const Center(child: Text('No job listings available right now.'))
                else
                  ...jobProv.jobs.take(3).map(
                        (job) => JobCard(
                          job: job,
                          onTap: () => context.go(RouteNames.jobDetails.replaceAll(':id', job.id.toString())),
                          onSaveToggle: () => jobProv.toggleSaveJob(job),
                        ),
                      ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
