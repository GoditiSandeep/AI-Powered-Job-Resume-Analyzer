class CareerRecommendationModel {
  final int? id;
  final String roleTitle;
  final double matchPercentage;
  final List<String> currentSkills;
  final List<String> requiredSkills;
  final List<String> skillGaps;
  final List<String> nextSteps;
  final String? salaryRange;
  final String demandLevel;

  CareerRecommendationModel({
    this.id,
    required this.roleTitle,
    required this.matchPercentage,
    this.currentSkills = const [],
    this.requiredSkills = const [],
    this.skillGaps = const [],
    this.nextSteps = const [],
    this.salaryRange,
    this.demandLevel = 'High',
  });

  factory CareerRecommendationModel.fromJson(Map<String, dynamic> json) {
    List<String> toStrList(dynamic val) {
      if (val is List) {
        return val.map((e) => e.toString()).toList();
      }
      return [];
    }

    return CareerRecommendationModel(
      id: json['id'] is int ? json['id'] : (json['id'] != null ? int.tryParse(json['id'].toString()) : null),
      roleTitle: json['role_title'] ?? '',
      matchPercentage: (json['match_percentage'] as num?)?.toDouble() ?? 0.0,
      currentSkills: toStrList(json['current_skills']),
      requiredSkills: toStrList(json['required_skills']),
      skillGaps: toStrList(json['skill_gaps']),
      nextSteps: toStrList(json['next_steps']),
      salaryRange: json['salary_range'],
      demandLevel: json['demand_level'] ?? 'High',
    );
  }
}
