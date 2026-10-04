class JobModel {
  final int id;
  final String title;
  final String company;
  final String location;
  final String? salary;
  final String employmentType;
  final String experience;
  final String description;
  final List<String> responsibilities;
  final List<String> requiredSkills;
  final List<String> preferredSkills;
  final bool isActive;
  final DateTime? createdAt;
  final bool isSaved;
  final String? applicationStatus;
  final double? matchPercentage;

  JobModel({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    this.salary,
    this.employmentType = 'Full-time',
    this.experience = '1-3 years',
    required this.description,
    this.responsibilities = const [],
    this.requiredSkills = const [],
    this.preferredSkills = const [],
    this.isActive = true,
    this.createdAt,
    this.isSaved = false,
    this.applicationStatus,
    this.matchPercentage,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    List<String> toStrList(dynamic val) {
      if (val is List) {
        return val.map((e) => e.toString()).toList();
      }
      return [];
    }

    return JobModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? '',
      company: json['company'] ?? '',
      location: json['location'] ?? '',
      salary: json['salary'],
      employmentType: json['employment_type'] ?? 'Full-time',
      experience: json['experience'] ?? '1-3 years',
      description: json['description'] ?? '',
      responsibilities: toStrList(json['responsibilities']),
      requiredSkills: toStrList(json['required_skills']),
      preferredSkills: toStrList(json['preferred_skills']),
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      isSaved: json['is_saved'] ?? false,
      applicationStatus: json['application_status'],
      matchPercentage: (json['match_percentage'] as num?)?.toDouble(),
    );
  }
}

class JobMatchModel {
  final int jobId;
  final String jobTitle;
  final String company;
  final double overallMatchPercentage;
  final double skillMatchScore;
  final double keywordMatchScore;
  final double experienceMatchScore;
  final double educationMatchScore;
  final List<String> matchedSkills;
  final List<String> missingSkills;
  final List<String> matchReasons;
  final List<String> improvementRecommendations;

  JobMatchModel({
    required this.jobId,
    required this.jobTitle,
    required this.company,
    required this.overallMatchPercentage,
    required this.skillMatchScore,
    required this.keywordMatchScore,
    required this.experienceMatchScore,
    required this.educationMatchScore,
    this.matchedSkills = const [],
    this.missingSkills = const [],
    this.matchReasons = const [],
    this.improvementRecommendations = const [],
  });

  factory JobMatchModel.fromJson(Map<String, dynamic> json) {
    List<String> toStrList(dynamic val) {
      if (val is List) {
        return val.map((e) => e.toString()).toList();
      }
      return [];
    }

    return JobMatchModel(
      jobId: json['job_id'] is int ? json['job_id'] : int.tryParse(json['job_id'].toString()) ?? 0,
      jobTitle: json['job_title'] ?? '',
      company: json['company'] ?? '',
      overallMatchPercentage: (json['overall_match_percentage'] as num?)?.toDouble() ?? 0.0,
      skillMatchScore: (json['skill_match_score'] as num?)?.toDouble() ?? 0.0,
      keywordMatchScore: (json['keyword_match_score'] as num?)?.toDouble() ?? 0.0,
      experienceMatchScore: (json['experience_match_score'] as num?)?.toDouble() ?? 0.0,
      educationMatchScore: (json['education_match_score'] as num?)?.toDouble() ?? 0.0,
      matchedSkills: toStrList(json['matched_skills']),
      missingSkills: toStrList(json['missing_skills']),
      matchReasons: toStrList(json['match_reasons']),
      improvementRecommendations: toStrList(json['improvement_recommendations']),
    );
  }
}
