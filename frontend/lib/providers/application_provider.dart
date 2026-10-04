import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/application_model.dart';

class ApplicationProvider extends ChangeNotifier {
  final ApiClient apiClient;

  bool _isLoading = false;
  String? _errorMessage;

  List<ApplicationModel> _applications = [];
  ApplicationStatsModel? _stats;
  String? _selectedStatusFilter;

  ApplicationProvider(this.apiClient);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ApplicationModel> get applications => _applications;
  ApplicationStatsModel? get stats => _stats;
  String? get selectedStatusFilter => _selectedStatusFilter;

  Future<void> loadApplications({String? status}) async {
    _isLoading = true;
    _errorMessage = null;
    _selectedStatusFilter = status;
    notifyListeners();

    try {
      final Map<String, dynamic> params = {};
      if (status != null && status.isNotEmpty) params['status_filter'] = status;

      final res = await apiClient.get(ApiConstants.applications, queryParameters: params);
      if (res.data is List) {
        _applications = (res.data as List).map((e) => ApplicationModel.fromJson(e)).toList();
      }
      await loadStats();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStats() async {
    try {
      final res = await apiClient.get(ApiConstants.applicationStats);
      _stats = ApplicationStatsModel.fromJson(res.data);
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> createApplication({
    required int jobId,
    String status = 'Applied',
    String? notes,
    DateTime? interviewDate,
  }) async {
    try {
      final res = await apiClient.post(
        ApiConstants.applications,
        data: {
          'job_id': jobId,
          'status': status,
          'notes': notes,
          'interview_date': interviewDate?.toIso8601String(),
        },
      );
      final newApp = ApplicationModel.fromJson(res.data);
      _applications.removeWhere((a) => a.jobId == jobId);
      _applications.insert(0, newApp);
      await loadStats();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> updateApplicationStatus(
    int appId, {
    required String status,
    String? notes,
    DateTime? interviewDate,
  }) async {
    try {
      final res = await apiClient.put(
        '${ApiConstants.applications}/$appId',
        data: {
          'status': status,
          if (notes != null) 'notes': notes,
          if (interviewDate != null) 'interview_date': interviewDate.toIso8601String(),
        },
      );
      final updated = ApplicationModel.fromJson(res.data);
      int idx = _applications.indexWhere((a) => a.id == appId);
      if (idx != -1) {
        _applications[idx] = updated;
      }
      await loadStats();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> deleteApplication(int appId) async {
    try {
      await apiClient.delete('${ApiConstants.applications}/$appId');
      _applications.removeWhere((a) => a.id == appId);
      await loadStats();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }
}
