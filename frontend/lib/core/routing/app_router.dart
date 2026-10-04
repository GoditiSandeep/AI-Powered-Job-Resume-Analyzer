import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../views/admin/admin_dashboard_screen.dart';
import '../../views/applications/applications_screen.dart';
import '../../views/auth/login_screen.dart';
import '../../views/auth/register_screen.dart';
import '../../views/dashboard/dashboard_screen.dart';
import '../../views/jobs/job_detail_screen.dart';
import '../../views/jobs/job_list_screen.dart';
import '../../views/profile/profile_screen.dart';
import '../../views/resumes/resume_analysis_screen.dart';
import '../../views/resumes/resume_list_screen.dart';
import '../../views/resumes/resume_upload_screen.dart';
import '../../views/skills/skill_gap_screen.dart';
import '../../views/splash/splash_screen.dart';
import 'route_names.dart';

class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: RouteNames.splash,
      refreshListenable: authProvider,
      redirect: (BuildContext context, GoRouterState state) {
        final isAuth = authProvider.isAuthenticated;
        final isLoggingIn = state.matchedLocation == RouteNames.login || state.matchedLocation == RouteNames.register;
        final isSplash = state.matchedLocation == RouteNames.splash;

        if (isSplash) return null;

        if (!isAuth && !isLoggingIn) {
          return RouteNames.login;
        }

        if (isAuth && isLoggingIn) {
          return RouteNames.dashboard;
        }

        if (state.matchedLocation.startsWith('/admin') && !authProvider.isAdmin) {
          return RouteNames.dashboard;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: RouteNames.splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: RouteNames.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: RouteNames.register,
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: RouteNames.dashboard,
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: RouteNames.profile,
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: RouteNames.resumes,
          builder: (context, state) => const ResumeListScreen(),
        ),
        GoRoute(
          path: RouteNames.resumeUpload,
          builder: (context, state) => const ResumeUploadScreen(),
        ),
        GoRoute(
          path: RouteNames.resumeAnalysis,
          builder: (context, state) {
            final idStr = state.pathParameters['id'] ?? '1';
            final id = int.tryParse(idStr) ?? 1;
            return ResumeAnalysisScreen(resumeId: id);
          },
        ),
        GoRoute(
          path: RouteNames.jobs,
          builder: (context, state) => const JobListScreen(),
        ),
        GoRoute(
          path: RouteNames.savedJobs,
          builder: (context, state) => const JobListScreen(),
        ),
        GoRoute(
          path: RouteNames.jobDetails,
          builder: (context, state) {
            final idStr = state.pathParameters['id'] ?? '1';
            final id = int.tryParse(idStr) ?? 1;
            return JobDetailScreen(jobId: id);
          },
        ),
        GoRoute(
          path: RouteNames.applications,
          builder: (context, state) => const ApplicationsScreen(),
        ),
        GoRoute(
          path: RouteNames.skillGap,
          builder: (context, state) => const SkillGapScreen(),
        ),
        GoRoute(
          path: RouteNames.recommendations,
          builder: (context, state) => const SkillGapScreen(),
        ),
        GoRoute(
          path: RouteNames.adminDashboard,
          builder: (context, state) => const AdminDashboardScreen(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('404 - Page Not Found', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.go(RouteNames.dashboard),
                child: const Text('Return to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
