import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/routing/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/resume_provider.dart';
import '../../widgets/app_nav_shell.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/resume_card.dart';

class ResumeListScreen extends StatefulWidget {
  const ResumeListScreen({super.key});

  @override
  State<ResumeListScreen> createState() => _ResumeListScreenState();
}

class _ResumeListScreenState extends State<ResumeListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ResumeProvider>().loadResumes();
    });
  }

  Future<void> _handleDelete(int resumeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Resume'),
        content: const Text('Are you sure you want to delete this resume and its analysis history?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<ResumeProvider>().deleteResume(resumeId);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resume deleted successfully.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final resumeProv = context.watch<ResumeProvider>();

    return AppNavShell(
      selectedIndex: 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Resumes', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => resumeProv.loadResumes(),
              tooltip: 'Refresh',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.go(RouteNames.resumeUpload),
          icon: const Icon(Icons.upload_file),
          label: const Text('Upload Resume'),
        ),
        body: resumeProv.isLoading
            ? const LoadingIndicator(message: 'Loading resumes...')
            : resumeProv.resumes.isEmpty
                ? EmptyStateView(
                    icon: Icons.description_outlined,
                    title: 'No resumes found',
                    description: 'Upload your resume to extract skills, calculate ATS score, and receive AI improvements.',
                    actionText: 'Upload Resume',
                    onAction: () => context.go(RouteNames.resumeUpload),
                  )
                : RefreshIndicator(
                    onRefresh: () => resumeProv.loadResumes(),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      itemCount: resumeProv.resumes.length,
                      itemBuilder: (context, index) {
                        final resume = resumeProv.resumes[index];
                        return ResumeCard(
                          resume: resume,
                          onTap: () => context.go(RouteNames.resumeAnalysis.replaceAll(':id', resume.id.toString())),
                          onReanalyze: () async {
                            await resumeProv.reanalyzeResume(resume.id);
                            if (context.mounted) {
                              context.go(RouteNames.resumeAnalysis.replaceAll(':id', resume.id.toString()));
                            }
                          },
                          onDelete: () => _handleDelete(resume.id),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
