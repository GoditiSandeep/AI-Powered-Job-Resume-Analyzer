import 'job_model.dart';

class ApplicationModel {
  final int id;
  final int userId;
  final int jobId;
  final String status; // Saved, Applied, Interview, Selected, Rejected
  final String? notes;
  final DateTime? interviewDate;
  final DateTime appliedDate;
  final DateTime? createdAt;
  final JobModel? job;

  ApplicationModel({
    required this.id,
    required this.userId,
    required this.jobId,
    required this.status,
    this.notes,
    this.interviewDate,
    required this.appliedDate,
    this.createdAt,
    this.job,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString()) ?? 0,
      jobId: json['job_id'] is int ? json['job_id'] : int.tryParse(json['job_id'].toString()) ?? 0,
      status: json['status'] ?? 'Applied',
      notes: json['notes'],
      interviewDate: json['interview_date'] != null ? DateTime.tryParse(json['interview_date'].toString()) : null,
      appliedDate: json['applied_date'] != null ? DateTime.tryParse(json['applied_date'].toString()) ?? DateTime.now() : DateTime.now(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      job: json['job'] != null ? JobModel.fromJson(json['job']) : null,
    );
  }
}

class ApplicationStatsModel {
  final int totalApplications;
  final int saved;
  final int applied;
  final int interviews;
  final int selected;
  final int rejected;

  ApplicationStatsModel({
    required this.totalApplications,
    required this.saved,
    required this.applied,
    required this.interviews,
    required this.selected,
    required this.rejected,
  });

  factory ApplicationStatsModel.fromJson(Map<String, dynamic> json) {
    return ApplicationStatsModel(
      totalApplications: json['total_applications'] ?? 0,
      saved: json['saved'] ?? 0,
      applied: json['applied'] ?? 0,
      interviews: json['interviews'] ?? 0,
      selected: json['selected'] ?? 0,
      rejected: json['rejected'] ?? 0,
    );
  }
}
