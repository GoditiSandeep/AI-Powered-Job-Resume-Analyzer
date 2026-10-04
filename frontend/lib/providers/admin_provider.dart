import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/admin_stats_model.dart';
import '../models/job_model.dart';
import '../models/user_model.dart';

class AdminProvider extends ChangeNotifier {
  final ApiClient apiClient;

  bool _isLoading = false;
  String? _errorMessage;

  AdminDashboardStatsModel? _dashboardStats;
  AdminAnalyticsModel? _analytics;
  List<UserModel> _users = [];
  List<JobModel> _adminJobs = [];
  List<dynamic> _auditLogs = [];

  AdminProvider(this.apiClient);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AdminDashboardStatsModel? get dashboardStats => _dashboardStats;
  AdminAnalyticsModel? get analytics => _analytics;
  List<UserModel> get users => _users;
  List<JobModel> get adminJobs => _adminJobs;
  List<dynamic> get auditLogs => _auditLogs;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await apiClient.get(ApiConstants.adminDashboard);
      if (res.data is Map<String, dynamic>) {
        _dashboardStats = AdminDashboardStatsModel.fromJson(res.data['stats'] ?? res.data);
        if (res.data['recent_activity'] is List) {
          _auditLogs = res.data['recent_activity'];
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAnalytics() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await apiClient.get(ApiConstants.adminAnalytics);
      _analytics = AdminAnalyticsModel.fromJson(res.data);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await apiClient.get(ApiConstants.adminUsers);
      if (res.data is List) {
        _users = (res.data as List).map((e) => UserModel.fromJson(e)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAdminJobs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await apiClient.get(ApiConstants.adminJobs);
      if (res.data is List) {
        _adminJobs = (res.data as List).map((e) => JobModel.fromJson(e)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createJob(Map<String, dynamic> jobData) async {
    try {
      final res = await apiClient.post(ApiConstants.adminJobs, data: jobData);
      final newJob = JobModel.fromJson(res.data);
      _adminJobs.insert(0, newJob);
      await loadDashboard();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> updateJob(int jobId, Map<String, dynamic> jobData) async {
    try {
      final res = await apiClient.put('${ApiConstants.adminJobs}/$jobId', data: jobData);
      final updated = JobModel.fromJson(res.data);
      final idx = _adminJobs.indexWhere((j) => j.id == jobId);
      if (idx != -1) {
        _adminJobs[idx] = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> deleteJob(int jobId) async {
    try {
      await apiClient.delete('${ApiConstants.adminJobs}/$jobId');
      _adminJobs.removeWhere((j) => j.id == jobId);
      await loadDashboard();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> toggleUserStatus(int userId, bool isActive) async {
    try {
      await apiClient.patch('${ApiConstants.adminUsers}/$userId/status', data: {'is_active': isActive});
      final idx = _users.indexWhere((u) => u.id == userId);
      if (idx != -1) {
        final u = _users[idx];
        _users[idx] = UserModel(
          id: u.id,
          name: u.name,
          email: u.email,
          username: u.username,
          role: u.role,
          isActive: isActive,
          title: u.title,
          location: u.location,
          bio: u.bio,
          createdAt: u.createdAt,
          resumesCount: u.resumesCount,
          applicationsCount: u.applicationsCount,
          savedJobsCount: u.savedJobsCount,
          latestResumeScore: u.latestResumeScore,
          latestAtsScore: u.latestAtsScore,
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }
}
