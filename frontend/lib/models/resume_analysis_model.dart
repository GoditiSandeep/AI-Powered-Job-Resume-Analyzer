class ImprovementModel {
  final String section;
  final String original;
  final String improved;
  final String reason;

  ImprovementModel({
    required this.section,
    required this.original,
    required this.improved,
    required this.reason,
  });

  factory ImprovementModel.fromJson(Map<String, dynamic> json) {
    return ImprovementModel(
      section: json['section'] ?? '',
      original: json['original'] ?? json['original_text'] ?? '',
      improved: json['improved'] ?? json['improved_text'] ?? '',
      reason: json['reason'] ?? 'Optimized active phrasing and quantifiable impact.',
    );
  }
}

class ResumeAnalysisModel {
  final int id;
  final int resumeId;
  final double overallScore;
  final double atsScore;
  final String analysisMode;
  final Map<String, dynamic> contactInfo;
  final Map<String, dynamic> summaryAnalysis;
  final List<dynamic> skills;
  final List<dynamic> education;
  final List<dynamic> experience;
  final List<dynamic> projects;
  final List<dynamic> certifications;
  final List<String> achievements;
  final Map<String, dynamic> sectionScores;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> detectedKeywords;
  final List<String> missingKeywords;
  final List<String> industryKeywords;
  final Map<String, dynamic> contentFeedback;
  final Map<String, dynamic> atsFeedback;
  final List<String> recommendations;
  final List<ImprovementModel> improvements;
  final DateTime? createdAt;

  ResumeAnalysisModel({
    required this.id,
    required this.resumeId,
    required this.overallScore,
    required this.atsScore,
    this.analysisMode = 'deterministic_fallback',
    this.contactInfo = const {},
    this.summaryAnalysis = const {},
    this.skills = const [],
    this.education = const [],
    this.experience = const [],
    this.projects = const [],
    this.certifications = const [],
    this.achievements = const [],
    this.sectionScores = const {},
    this.strengths = const [],
    this.weaknesses = const [],
    this.detectedKeywords = const [],
    this.missingKeywords = const [],
    this.industryKeywords = const [],
    this.contentFeedback = const {},
    this.atsFeedback = const {},
    this.recommendations = const [],
    this.improvements = const [],
    this.createdAt,
  });

  factory ResumeAnalysisModel.fromJson(Map<String, dynamic> json) {
    List<ImprovementModel> impList = [];
    if (json['improvements'] is List) {
      for (var item in json['improvements']) {
        if (item is Map<String, dynamic>) {
          impList.add(ImprovementModel.fromJson(item));
        }
      }
    }

    List<String> toStrList(dynamic val) {
      if (val is List) {
        return val.map((e) => e.toString()).toList();
      }
      return [];
    }

    return ResumeAnalysisModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      resumeId: json['resume_id'] is int ? json['resume_id'] : int.tryParse(json['resume_id'].toString()) ?? 0,
      overallScore: (json['overall_score'] as num?)?.toDouble() ?? 0.0,
      atsScore: (json['ats_score'] as num?)?.toDouble() ?? 0.0,
      analysisMode: json['analysis_mode'] ?? 'deterministic_fallback',
      contactInfo: json['contact_info'] is Map ? Map<String, dynamic>.from(json['contact_info']) : {},
      summaryAnalysis: json['summary_analysis'] is Map ? Map<String, dynamic>.from(json['summary_analysis']) : {},
      skills: json['skills'] is List ? json['skills'] : [],
      education: json['education'] is List ? json['education'] : [],
      experience: json['experience'] is List ? json['experience'] : [],
      projects: json['projects'] is List ? json['projects'] : [],
      certifications: json['certifications'] is List ? json['certifications'] : [],
      achievements: toStrList(json['achievements']),
      sectionScores: json['section_scores'] is Map ? Map<String, dynamic>.from(json['section_scores']) : {},
      strengths: toStrList(json['strengths']),
      weaknesses: toStrList(json['weaknesses']),
      detectedKeywords: toStrList(json['detected_keywords']),
      missingKeywords: toStrList(json['missing_keywords']),
      industryKeywords: toStrList(json['industry_keywords']),
      contentFeedback: json['content_feedback'] is Map ? Map<String, dynamic>.from(json['content_feedback']) : {},
      atsFeedback: json['ats_feedback'] is Map ? Map<String, dynamic>.from(json['ats_feedback']) : {},
      recommendations: toStrList(json['recommendations']),
      improvements: impList,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}
