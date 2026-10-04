class UserModel {
  final int id;
  final String name;
  final String email;
  final String? username;
  final String role;
  final bool isActive;
  final String? title;
  final String? location;
  final String? bio;
  final DateTime? createdAt;
  final int resumesCount;
  final int applicationsCount;
  final int savedJobsCount;
  final double? latestResumeScore;
  final double? latestAtsScore;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.username,
    required this.role,
    this.isActive = true,
    this.title,
    this.location,
    this.bio,
    this.createdAt,
    this.resumesCount = 0,
    this.applicationsCount = 0,
    this.savedJobsCount = 0,
    this.latestResumeScore,
    this.latestAtsScore,
  });

  bool get isAdmin => role.toUpperCase() == 'ADMIN';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      username: json['username'],
      role: json['role'] ?? 'USER',
      isActive: json['is_active'] ?? true,
      title: json['title'],
      location: json['location'],
      bio: json['bio'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      resumesCount: json['resumes_count'] ?? 0,
      applicationsCount: json['applications_count'] ?? 0,
      savedJobsCount: json['saved_jobs_count'] ?? 0,
      latestResumeScore: json['latest_resume_score'] != null ? (json['latest_resume_score'] as num).toDouble() : null,
      latestAtsScore: json['latest_ats_score'] != null ? (json['latest_ats_score'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'username': username,
      'role': role,
      'is_active': isActive,
      'title': title,
      'location': location,
      'bio': bio,
      'resumes_count': resumesCount,
      'applications_count': applicationsCount,
      'saved_jobs_count': savedJobsCount,
      'latest_resume_score': latestResumeScore,
      'latest_ats_score': latestAtsScore,
    };
  }
}
