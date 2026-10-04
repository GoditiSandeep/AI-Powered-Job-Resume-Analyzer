import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/job_model.dart';
import '../../models/user_model.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/app_nav_shell.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/score_gauge.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = context.read<AdminProvider>();
      admin.loadDashboard();
      admin.loadAnalytics();
      admin.loadUsers();
      admin.loadAdminJobs();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddJobModal(BuildContext context) {
    final titleCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final salaryCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final skillsCtrl = TextEditingController();

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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Post New Job Opening', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Job Title *')),
                  const SizedBox(height: 10),
                  TextField(controller: companyCtrl, decoration: const InputDecoration(labelText: 'Company *')),
                  const SizedBox(height: 10),
                  TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Location *')),
                  const SizedBox(height: 10),
                  TextField(controller: salaryCtrl, decoration: const InputDecoration(labelText: r'Salary Range (e.g. $120k-$150k)')),
                  const SizedBox(height: 10),
                  TextField(
                    controller: skillsCtrl,
                    decoration: const InputDecoration(labelText: 'Required Skills (comma separated)', hintText: 'Python, FastAPI, Docker'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Description *'),
                  ),
                  const SizedBox(height: 18),
                  CustomButton(
                    text: 'Create Job Posting',
                    isLoading: isSubmitting,
                    onPressed: () async {
                      if (titleCtrl.text.isEmpty || companyCtrl.text.isEmpty || descCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields.')));
                        return;
                      }

                      setModalState(() => isSubmitting = true);
                      final skills = skillsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

                      final success = await context.read<AdminProvider>().createJob({
                        'title': titleCtrl.text.trim(),
                        'company': companyCtrl.text.trim(),
                        'location': locationCtrl.text.trim().isNotEmpty ? locationCtrl.text.trim() : 'Remote',
                        'salary': salaryCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'required_skills': skills,
                      });

                      setModalState(() => isSubmitting = false);
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Job posted successfully!'), backgroundColor: AppColors.success),
                          );
                        }
                      }
                    },
                  ),
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
    final admin = context.watch<AdminProvider>();
    final stats = admin.dashboardStats;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppNavShell(
      selectedIndex: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Operations Hub', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                admin.loadDashboard();
                admin.loadAnalytics();
                admin.loadUsers();
                admin.loadAdminJobs();
              },
              tooltip: 'Refresh',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.dashboard_outlined, size: 18), text: 'KPIs & Activity'),
              Tab(icon: Icon(Icons.people_alt_outlined, size: 18), text: 'User Management'),
              Tab(icon: Icon(Icons.work_outline, size: 18), text: 'Job Postings'),
              Tab(icon: Icon(Icons.analytics_outlined, size: 18), text: 'Analytics'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: KPI & Activity
            admin.isLoading && stats == null
                ? const LoadingIndicator(message: 'Loading admin dashboard stats...')
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (stats != null) ...[
                          GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: 1.5,
                            children: [
                              _buildAdminStatCard('Total Users', stats.totalUsers.toString(), Icons.people_outline, AppColors.primary),
                              _buildAdminStatCard('Resumes Analyzed', stats.totalResumes.toString(), Icons.description_outlined, AppColors.secondary),
                              _buildAdminStatCard('Total Jobs', stats.totalJobs.toString(), Icons.work_outline, AppColors.accent),
                              _buildAdminStatCard('Avg System ATS', '${stats.averageAtsScore.toInt()}%', Icons.auto_awesome, AppColors.success),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                        const Text('Recent System Audit Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        if (admin.auditLogs.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text('No system audit entries yet.'),
                            ),
                          )
                        else
                          ...admin.auditLogs.map(
                            (log) => Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.history, color: AppColors.primary, size: 20),
                                ),
                                title: Text(log['action']?.toString() ?? 'Action', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                subtitle: Text(log['details']?.toString() ?? '', style: const TextStyle(fontSize: 12.5)),
                                trailing: Text(
                                  log['ip_address']?.toString() ?? '',
                                  style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

            // Tab 2: User Management
            admin.isLoading && admin.users.isEmpty
                ? const LoadingIndicator(message: 'Loading registered users...')
                : RefreshIndicator(
                    onRefresh: () => admin.loadUsers(),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      itemCount: admin.users.length,
                      itemBuilder: (context, index) {
                        final u = admin.users[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: u.isAdmin ? AppColors.primary : AppColors.secondary,
                              child: Text(u.name.isNotEmpty ? u.name[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white)),
                            ),
                            title: Row(
                              children: [
                                Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                if (u.isAdmin) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                                    child: const Text('ADMIN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Text('${u.email} • Resumes: ${u.resumesCount} • Apps: ${u.applicationsCount}'),
                            trailing: Switch(
                              value: u.isActive,
                              onChanged: (val) => admin.toggleUserStatus(u.id, val),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

            // Tab 3: Job Management
            Scaffold(
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _showAddJobModal(context),
                icon: const Icon(Icons.add),
                label: const Text('Post New Job'),
              ),
              body: admin.isLoading && admin.adminJobs.isEmpty
                  ? const LoadingIndicator(message: 'Loading job postings...')
                  : RefreshIndicator(
                      onRefresh: () => admin.loadAdminJobs(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        itemCount: admin.adminJobs.length,
                        itemBuilder: (context, index) {
                          final job = admin.adminJobs[index];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(job.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${job.company} • ${job.location} • ${job.employmentType}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                onPressed: () => admin.deleteJob(job.id),
                                tooltip: 'Delete Job',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),

            // Tab 4: Analytics
            admin.analytics == null
                ? const LoadingIndicator(message: 'Calculating system analytics...')
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ATS Score Distribution Across Resumes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              children: admin.analytics!.scoreDistribution.entries
                                  .map(
                                    (e) => ScoreBar(
                                      label: e.key,
                                      score: e.value.toDouble(),
                                      maxScore: (admin.dashboardStats?.totalResumes ?? 10).toDouble(),
                                    ),
                                  )
                                  .toList(),
                          ),
                        ),
                        ),
                        const SizedBox(height: 20),
                        const Text('Top In-Demand Skills in Jobs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: admin.analytics!.topJobSkills
                                  .map((s) => Chip(label: Text(s.toString()), backgroundColor: AppColors.primary.withOpacity(0.12)))
                                  .toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
