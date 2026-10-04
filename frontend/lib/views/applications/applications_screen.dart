import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/application_model.dart';
import '../../providers/application_provider.dart';
import '../../widgets/app_nav_shell.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/loading_indicator.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  String? _selectedFilter;

  final List<String> _statuses = ['All', 'Applied', 'Interview', 'Selected', 'Rejected'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApplicationProvider>().loadApplications();
    });
  }

  void _onFilterChanged(String? filter) {
    setState(() => _selectedFilter = filter == 'All' ? null : filter);
    context.read<ApplicationProvider>().loadApplications(status: _selectedFilter);
  }

  void _showStatusModal(ApplicationModel app) {
    String newStatus = app.status;
    final notesController = TextEditingController(text: app.notes ?? '');
    DateTime? selectedDate = app.interviewDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          bool isUpdating = false;

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
                Text(
                  'Update Status: ${app.job?.title ?? 'Job Application'}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: newStatus,
                  decoration: const InputDecoration(labelText: 'Application Stage'),
                  items: ['Applied', 'Interview', 'Selected', 'Rejected']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => newStatus = val);
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Feedback',
                    hintText: 'Add recruiter feedback, salary discussion, etc.',
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
                  title: Text(
                    selectedDate != null
                        ? 'Interview: ${DateFormat('MMM dd, yyyy HH:mm').format(selectedDate!)}'
                        : 'Set Interview Date (Optional)',
                    style: const TextStyle(fontSize: 14),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setModalState(() => selectedDate = date);
                    }
                  },
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: 'Save Application Stage',
                  isLoading: isUpdating,
                  onPressed: () async {
                    setModalState(() => isUpdating = true);
                    final success = await context.read<ApplicationProvider>().updateApplicationStatus(
                          app.id,
                          status: newStatus,
                          notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                          interviewDate: selectedDate,
                        );
                    setModalState(() => isUpdating = false);
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Status updated!'), backgroundColor: AppColors.success),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selected':
        return AppColors.success;
      case 'interview':
        return AppColors.info;
      case 'applied':
        return AppColors.primary;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProv = context.watch<ApplicationProvider>();
    final stats = appProv.stats;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppNavShell(
      selectedIndex: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Application Tracker', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => appProv.loadApplications(status: _selectedFilter),
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: Column(
          children: [
            // KPI Summary Counters
            if (stats != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCounter('Total', stats.totalApplications.toString(), AppColors.primary),
                    _buildCounter('Applied', stats.applied.toString(), AppColors.info),
                    _buildCounter('Interviews', stats.interviews.toString(), AppColors.warning),
                    _buildCounter('Offers', stats.selected.toString(), AppColors.success),
                    _buildCounter('Rejected', stats.rejected.toString(), AppColors.error),
                  ],
                ),
              ),
            const Divider(height: 1),

            // Status Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: _statuses.map((st) {
                  final isSelected = (_selectedFilter == null && st == 'All') || (_selectedFilter == st);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(st),
                      selected: isSelected,
                      onSelected: (_) => _onFilterChanged(st),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Applications List
            Expanded(
              child: appProv.isLoading
                  ? const LoadingIndicator(message: 'Loading active applications...')
                  : appProv.applications.isEmpty
                      ? EmptyStateView(
                          icon: Icons.assignment_turned_in_outlined,
                          title: 'No applications found',
                          description: 'Apply to jobs from the Jobs tab to track your progress and interview pipeline.',
                        )
                      : RefreshIndicator(
                          onRefresh: () => appProv.loadApplications(status: _selectedFilter),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            itemCount: appProv.applications.length,
                            itemBuilder: (context, index) {
                              final app = appProv.applications[index];
                              final statusColor = _getStatusColor(app.status);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  app.job?.title ?? 'Job Position',
                                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                ),
                                                Text(
                                                  app.job?.company ?? 'Company',
                                                  style: const TextStyle(fontSize: 13.5, color: AppColors.primary),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: statusColor.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: statusColor.withOpacity(0.4)),
                                            ),
                                            child: Text(
                                              app.status,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: statusColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today_outlined, size: 14, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Applied: ${DateFormat('MMM dd, yyyy').format(app.appliedDate)}',
                                            style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                          ),
                                          if (app.interviewDate != null) ...[
                                            const SizedBox(width: 14),
                                            const Icon(Icons.event_available, size: 14, color: AppColors.warning),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Interview: ${DateFormat('MMM dd').format(app.interviewDate!)}',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.warning),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (app.notes != null && app.notes!.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Note: ${app.notes!}',
                                            style: const TextStyle(fontSize: 12.5),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton.icon(
                                            icon: const Icon(Icons.edit_note, size: 16),
                                            label: const Text('Update Stage'),
                                            onPressed: () => _showStatusModal(app),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                            onPressed: () => appProv.deleteApplication(app.id),
                                            tooltip: 'Delete Application',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
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

  Widget _buildCounter(String label, String count, Color color) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
      ],
    );
  }
}
