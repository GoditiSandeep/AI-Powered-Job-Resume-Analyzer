import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/resume_model.dart';
import '../models/resume_analysis_model.dart';

class ResumeProvider extends ChangeNotifier {
  final ApiClient apiClient;

  bool _isLoading = false;
  bool _isUploading = false;
  bool _isAnalyzing = false;
  String? _errorMessage;

  List<ResumeModel> _resumes = [];
  ResumeAnalysisModel? _currentAnalysis;

  ResumeProvider(this.apiClient);

  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  bool get isAnalyzing => _isAnalyzing;
  String? get errorMessage => _errorMessage;
  List<ResumeModel> get resumes => _resumes;
  ResumeAnalysisModel? get currentAnalysis => _currentAnalysis;
  ResumeModel? get latestResume => _resumes.isNotEmpty ? _resumes.first : null;

  Future<void> loadResumes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await apiClient.get(ApiConstants.resumes);
      if (res.data is List) {
        _resumes = (res.data as List).map((e) => ResumeModel.fromJson(e)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ResumeModel?> uploadResume({
    required String fileName,
    String? filePath,
    Uint8List? fileBytes,
  }) async {
    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      MultipartFile multipartFile;
      String ext = fileName.split('.').last.toLowerCase();

      MediaType mediaType = MediaType('application', 'octet-stream');
      if (ext == 'pdf') mediaType = MediaType('application', 'pdf');
      if (ext == 'txt') mediaType = MediaType('text', 'plain');

      if (fileBytes != null) {
        multipartFile = MultipartFile.fromBytes(fileBytes, filename: fileName, contentType: mediaType);
      } else if (filePath != null) {
        multipartFile = await MultipartFile.fromFile(filePath, filename: fileName, contentType: mediaType);
      } else {
        throw Exception('No file data provided.');
      }

      FormData formData = FormData.fromMap({'file': multipartFile});
      final res = await apiClient.post(ApiConstants.resumeUpload, data: formData);
      final newResume = ResumeModel.fromJson(res.data);

      await loadResumes();
      if (newResume.id > 0) {
        await loadAnalysis(newResume.id);
      }
      return newResume;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  Future<void> loadAnalysis(int resumeId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await apiClient.get('${ApiConstants.resumes}/$resumeId/analysis');
      _currentAnalysis = ResumeAnalysisModel.fromJson(res.data);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ResumeAnalysisModel?> reanalyzeResume(
    int resumeId, {
    String? targetJobTitle,
    String? targetJobDescription,
    bool forceFallback = false,
  }) async {
    _isAnalyzing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await apiClient.post(
        '${ApiConstants.resumes}/$resumeId/analyze',
        data: {
          'target_job_title': targetJobTitle,
          'target_job_description': targetJobDescription,
          'force_fallback': forceFallback,
        },
      );
      _currentAnalysis = ResumeAnalysisModel.fromJson(res.data);
      await loadResumes();
      return _currentAnalysis;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  Future<ImprovementModel?> improveSectionText({
    required String section,
    required String originalText,
    String roleTarget = 'Software Engineer',
  }) async {
    try {
      final res = await apiClient.post(
        ApiConstants.resumeImproveText,
        data: {
          'section': section,
          'original_text': originalText,
          'role_target': roleTarget,
        },
      );
      return ImprovementModel.fromJson(res.data);
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    }
  }

  Future<bool> deleteResume(int resumeId) async {
    try {
      await apiClient.delete('${ApiConstants.resumes}/$resumeId');
      _resumes.removeWhere((r) => r.id == resumeId);
      if (_currentAnalysis?.resumeId == resumeId) {
        _currentAnalysis = null;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }
}
