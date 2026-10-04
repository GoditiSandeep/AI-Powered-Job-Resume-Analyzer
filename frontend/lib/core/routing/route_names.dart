class RouteNames {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';

  // User routes
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String settings = '/settings';

  static const String resumes = '/resumes';
  static const String resumeUpload = '/resumes/upload';
  static const String resumeAnalysis = '/resumes/:id/analysis';
  static const String resumeScore = '/resumes/:id/score';
  static const String resumeImprovement = '/resumes/:id/improve';

  static const String jobs = '/jobs';
  static const String jobDetails = '/jobs/:id';
  static const String jobMatch = '/jobs/:id/match';
  static const String savedJobs = '/jobs/saved';

  static const String applications = '/applications';
  static const String applicationDetails = '/applications/:id';

  static const String skillGap = '/skills/gaps';
  static const String recommendations = '/recommendations';

  // Admin routes
  static const String adminDashboard = '/admin';
  static const String adminUsers = '/admin/users';
  static const String adminUserDetails = '/admin/users/:id';
  static const String adminJobs = '/admin/jobs';
  static const String adminAddJob = '/admin/jobs/new';
  static const String adminEditJob = '/admin/jobs/:id/edit';
  static const String adminAnalytics = '/admin/analytics';
  static const String adminSettings = '/admin/settings';

  // Fallbacks
  static const String accessDenied = '/access-denied';
  static const String notFound = '/not-found';
}
