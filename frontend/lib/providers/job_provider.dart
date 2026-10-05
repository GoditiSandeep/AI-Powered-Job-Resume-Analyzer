import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/job_model.dart';

class JobProvider extends ChangeNotifier {
  final ApiClient apiClient;

  bool _isLoading = false;
  String? _errorMessage;

  List<JobModel> _jobs = [];
  List<JobModel> _savedJobs = [];
  JobModel? _selectedJob;
  JobMatchModel? _currentJobMatch;

  JobProvider(this.apiClient);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<JobModel> get jobs => _jobs;
  List<JobModel> get savedJobs => _savedJobs;
  JobModel? get selectedJob => _selectedJob;
  JobMatchModel? get currentJobMatch => _currentJobMatch;

  Future<void> loadJobs({String? search, String? location, String? employmentType}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Map<String, dynamic> params = {};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (location != null && location.isNotEmpty) params['location'] = location;
      if (employmentType != null && employmentType.isNotEmpty) params['employment_type'] = employmentType;

      final res = await apiClient.get(ApiConstants.jobs, queryParameters: params);
      if (res.data is List) {
        _jobs = (res.data as List).map((e) => JobModel.fromJson(e)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSavedJobs() async {
    try {
      final res = await apiClient.get(ApiConstants.savedJobs);
      if (res.data is List) {
        _savedJobs = (res.data as List).map((e) => JobModel.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> loadJobDetails(int jobId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await apiClient.get('${ApiConstants.jobs}/$jobId');
      _selectedJob = JobModel.fromJson(res.data);
      await calculateJobMatch(jobId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> calculateJobMatch(int jobId, {int? resumeId}) async {
    try {
      final Map<String, dynamic> params = {};
      if (resumeId != null) params['resume_id'] = resumeId;

      final res = await apiClient.get('${ApiConstants.jobs}/$jobId/match', queryParameters: params);
      _currentJobMatch = JobMatchModel.fromJson(res.data);
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> toggleSaveJob(JobModel job) async {
    try {
      if (job.isSaved) {
        await apiClient.delete('${ApiConstants.jobs}/${job.id}/save');
        _savedJobs.removeWhere((j) => j.id == job.id);
      } else {
        await apiClient.post('${ApiConstants.jobs}/${job.id}/save');
        _savedJobs.add(job);
      }

      // Update local item
      int idx = _jobs.indexWhere((j) => j.id == job.id);
      if (idx != -1) {
        _jobs[idx] = JobModel(
          id: job.id,
          title: job.title,
          company: job.company,
          location: job.location,
          salary: job.salary,
          employmentType: job.employmentType,
          experience: job.experience,
          description: job.description,
          responsibilities: job.responsibilities,
          requiredSkills: job.requiredSkills,
          preferredSkills: job.preferredSkills,
          isActive: job.isActive,
          createdAt: job.createdAt,
          isSaved: !job.isSaved,
          applicationStatus: job.applicationStatus,
          matchPercentage: job.matchPercentage,
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
