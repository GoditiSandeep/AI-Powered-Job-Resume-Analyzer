import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/career_recommendation_model.dart';
import '../models/skill_model.dart';

class SkillProvider extends ChangeNotifier {
  final ApiClient apiClient;

  bool _isLoading = false;
  String? _errorMessage;

  List<SkillModel> _allSkills = [];
  List<SkillGapModel> _skillGaps = [];
  List<CareerRecommendationModel> _recommendations = [];

  SkillProvider(this.apiClient);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<SkillModel> get allSkills => _allSkills;
  List<SkillGapModel> get skillGaps => _skillGaps;
  List<CareerRecommendationModel> get recommendations => _recommendations;

  Future<void> loadSkills() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await apiClient.get(ApiConstants.skills);
      if (res.data is List) {
        _allSkills = (res.data as List).map((e) => SkillModel.fromJson(e)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSkillGaps({int? resumeId, String? targetRole}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Map<String, dynamic> params = {};
      if (resumeId != null) params['resume_id'] = resumeId;
      if (targetRole != null && targetRole.isNotEmpty) params['target_role'] = targetRole;

      final res = await apiClient.get(ApiConstants.skillGaps, queryParameters: params);
      if (res.data is List) {
        _skillGaps = (res.data as List).map((e) => SkillGapModel.fromJson(e)).toList();
      } else if (res.data is Map<String, dynamic>) {
        _skillGaps = [SkillGapModel.fromJson(res.data)];
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRecommendations({int? resumeId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Map<String, dynamic> params = {};
      if (resumeId != null) params['resume_id'] = resumeId;

      final res = await apiClient.get(ApiConstants.recommendations, queryParameters: params);
      if (res.data is List) {
        _recommendations = (res.data as List).map((e) => CareerRecommendationModel.fromJson(e)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
