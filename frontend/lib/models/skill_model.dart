class SkillModel {
  final int id;
  final String name;
  final String category;

  SkillModel({
    required this.id,
    required this.name,
    this.category = 'technical',
  });

  factory SkillModel.fromJson(Map<String, dynamic> json) {
    return SkillModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      category: json['category'] ?? 'technical',
    );
  }
}

class SkillGapModel {
  final String targetRole;
  final double matchPercentage;
  final List<String> matchedSkills;
  final List<String> missingSkills;
  final List<String> highPriority;
  final List<String> mediumPriority;
  final List<String> lowPriority;
  final List<Map<String, String>> learningRecommendations;

  SkillGapModel({
    required this.targetRole,
    required this.matchPercentage,
    this.matchedSkills = const [],
    this.missingSkills = const [],
    this.highPriority = const [],
    this.mediumPriority = const [],
    this.lowPriority = const [],
    this.learningRecommendations = const [],
  });

  factory SkillGapModel.fromJson(Map<String, dynamic> json) {
    List<String> toStrList(dynamic val) {
      if (val is List) {
        return val.map((e) => e.toString()).toList();
      }
      return [];
    }

    List<Map<String, String>> toRecList(dynamic val) {
      if (val is List) {
        return val.map((e) {
          if (e is Map) {
            return {
              'skill': e['skill']?.toString() ?? '',
              'recommendation': e['recommendation']?.toString() ?? '',
            };
          }
          return {'skill': '', 'recommendation': e.toString()};
        }).toList();
      }
      return [];
    }

    return SkillGapModel(
      targetRole: json['target_role'] ?? '',
      matchPercentage: (json['match_percentage'] as num?)?.toDouble() ?? 0.0,
      matchedSkills: toStrList(json['matched_skills']),
      missingSkills: toStrList(json['missing_skills']),
      highPriority: toStrList(json['high_priority']),
      mediumPriority: toStrList(json['medium_priority']),
      lowPriority: toStrList(json['low_priority']),
      learningRecommendations: toRecList(json['learning_recommendations']),
    );
  }
}
