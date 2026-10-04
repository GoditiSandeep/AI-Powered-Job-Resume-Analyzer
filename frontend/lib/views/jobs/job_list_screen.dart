import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/routing/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/job_provider.dart';
import '../../widgets/app_nav_shell.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/job_card.dart';
import '../../widgets/loading_indicator.dart';

class JobListScreen extends StatefulWidget {
  const JobListScreen({super.key});

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  final _searchController = TextEditingController();
  String? _selectedType;
  bool _showSavedOnly = false;

  final List<String> _employmentTypes = ['All', 'Full-time', 'Part-time', 'Contract', 'Remote', 'Internship'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobProvider>().loadJobs();
      context.read<JobProvider>().loadSavedJobs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final type = _selectedType == 'All' ? null : _selectedType;
    context.read<JobProvider>().loadJobs(
          search: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
          employmentType: type,
        );
  }

  @override
  Widget build(BuildContext context) {
    final jobProv = context.watch<JobProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final displayJobs = _showSavedOnly ? jobProv.savedJobs : jobProv.jobs;

    return AppNavShell(
      selectedIndex: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Jobs & Matching', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: Icon(_showSavedOnly ? Icons.bookmark : Icons.bookmark_border),
              color: _showSavedOnly ? AppColors.primary : null,
              onPressed: () => setState(() => _showSavedOnly = !_showSavedOnly),
              tooltip: _showSavedOnly ? 'Show All Jobs' : 'Show Saved Only',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _onSearch(),
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: Column(
          children: [
            // Search and Filter Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _onSearch(),
                    decoration: InputDecoration(
                      hintText: 'Search jobs by title, skills, or company...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _onSearch();
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _employmentTypes.map((type) {
                        final isSelected = (_selectedType == null && type == 'All') || (_selectedType == type);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(type),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedType = type == 'All' ? null : type;
                              });
                              _onSearch();
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Job List Content
            Expanded(
              child: jobProv.isLoading
                  ? const LoadingIndicator(message: 'Searching open job opportunities...')
                  : displayJobs.isEmpty
                      ? EmptyStateView(
                          icon: Icons.work_off_outlined,
                          title: _showSavedOnly ? 'No saved jobs' : 'No jobs found',
                          description: _showSavedOnly
                              ? 'You have not saved any jobs yet. Browse available jobs and bookmark your favorites.'
                              : 'Try adjusting your search query or filters to find available positions.',
                          actionText: _showSavedOnly ? 'Explore All Jobs' : 'Clear Filters',
                          onAction: () {
                            setState(() {
                              _showSavedOnly = false;
                              _searchController.clear();
                              _selectedType = null;
                            });
                            _onSearch();
                          },
                        )
                      : RefreshIndicator(
                          onRefresh: () => jobProv.loadJobs(),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            itemCount: displayJobs.length,
                            itemBuilder: (context, index) {
                              final job = displayJobs[index];
                              return JobCard(
                                job: job,
                                onTap: () => context.go(RouteNames.jobDetails.replaceAll(':id', job.id.toString())),
                                onSaveToggle: () => jobProv.toggleSaveJob(job),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
