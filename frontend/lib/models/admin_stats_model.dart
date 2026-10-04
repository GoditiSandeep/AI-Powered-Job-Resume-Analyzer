class AdminDashboardStatsModel {
  final int totalUsers;
  final int activeUsers;
  final int totalResumes;
  final int totalAnalyses;
  final int totalJobs;
  final int totalApplications;
  final double averageResumeScore;
  final double averageAtsScore;

  AdminDashboardStatsModel({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalResumes,
    required this.totalAnalyses,
    required this.totalJobs,
    required this.totalApplications,
    required this.averageResumeScore,
    required this.averageAtsScore,
  });

  factory AdminDashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardStatsModel(
      totalUsers: json['total_users'] ?? 0,
      activeUsers: json['active_users'] ?? 0,
      totalResumes: json['total_resumes'] ?? 0,
      totalAnalyses: json['total_analyses'] ?? 0,
      totalJobs: json['total_jobs'] ?? 0,
      totalApplications: json['total_applications'] ?? 0,
      averageResumeScore: (json['average_resume_score'] as num?)?.toDouble() ?? 0.0,
      averageAtsScore: (json['average_ats_score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AdminAnalyticsModel {
  final AdminDashboardStatsModel stats;
  final List<dynamic> usersGrowth;
  final List<dynamic> analysesOverTime;
  final Map<String, int> applicationsByStatus;
  final Map<String, int> scoreDistribution;
  final List<dynamic> topResumeSkills;
  final List<dynamic> topJobSkills;
  final List<dynamic> popularJobs;

  AdminAnalyticsModel({
    required this.stats,
    this.usersGrowth = const [],
    this.analysesOverTime = const [],
    this.applicationsByStatus = const {},
    this.scoreDistribution = const {},
    this.topResumeSkills = const [],
    this.topJobSkills = const [],
    this.popularJobs = const [],
  });

  factory AdminAnalyticsModel.fromJson(Map<String, dynamic> json) {
    Map<String, int> toIntMap(dynamic val) {
      if (val is Map) {
        return val.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
      }
      return {};
    }

    return AdminAnalyticsModel(
      stats: AdminDashboardStatsModel.fromJson(json['stats'] ?? {}),
      usersGrowth: json['users_growth'] is List ? json['users_growth'] : [],
      analysesOverTime: json['analyses_over_time'] is List ? json['analyses_over_time'] : [],
      applicationsByStatus: toIntMap(json['applications_by_status']),
      scoreDistribution: toIntMap(json['score_distribution']),
      topResumeSkills: json['top_resume_skills'] is List ? json['top_resume_skills'] : [],
      topJobSkills: json['top_job_skills'] is List ? json['top_job_skills'] : [],
      popularJobs: json['popular_jobs'] is List ? json['popular_jobs'] : [],
    );
  }
}
