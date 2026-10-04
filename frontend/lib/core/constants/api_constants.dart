import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String localBaseUrl = 'http://127.0.0.1:8000';
  static const String configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
  static String get baseUrl => configuredBaseUrl.isNotEmpty
      ? configuredBaseUrl
      : (kIsWeb && kReleaseMode ? Uri.base.origin : localBaseUrl);
  static const String emulatorBaseUrl = 'http://10.0.2.2:8000';

  // Endpoints
  static const String health = '/health';
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String logout = '/api/auth/logout';
  static const String me = '/api/auth/me';

  static const String resumes = '/api/resumes';
  static const String resumeUpload = '/api/resumes/upload';
  static const String resumeImproveText = '/api/resumes/improve-text';

  static const String jobs = '/api/jobs';
  static const String savedJobs = '/api/jobs/saved';
  static const String recommendations = '/api/recommendations';

  static const String applications = '/api/applications';
  static const String applicationStats = '/api/applications/stats';

  static const String skills = '/api/skills';
  static const String skillGaps = '/api/skills/gaps';

  static const String adminDashboard = '/api/admin/dashboard';
  static const String adminAnalytics = '/api/admin/analytics';
  static const String adminUsers = '/api/admin/users';
  static const String adminJobs = '/api/admin/jobs';
}
