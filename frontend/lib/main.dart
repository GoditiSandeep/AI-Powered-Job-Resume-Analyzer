import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/network/api_client.dart';
import 'core/routing/app_router.dart';
import 'core/storage/secure_storage.dart';
import 'core/theme/app_theme.dart';
import 'providers/admin_provider.dart';
import 'providers/application_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/job_provider.dart';
import 'providers/resume_provider.dart';
import 'providers/skill_provider.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = await StorageService.getInstance();
  final apiClient = ApiClient(storageService);

  final authProvider = AuthProvider(apiClient, storageService);
  final resumeProvider = ResumeProvider(apiClient);
  final jobProvider = JobProvider(apiClient);
  final appProvider = ApplicationProvider(apiClient);
  final skillProvider = SkillProvider(apiClient);
  final adminProvider = AdminProvider(apiClient);
  final themeProvider = ThemeProvider(storageService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: resumeProvider),
        ChangeNotifierProvider.value(value: jobProvider),
        ChangeNotifierProvider.value(value: appProvider),
        ChangeNotifierProvider.value(value: skillProvider),
        ChangeNotifierProvider.value(value: adminProvider),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: const JobResumeAnalyzerApp(),
    ),
  );
}

class JobResumeAnalyzerApp extends StatefulWidget {
  const JobResumeAnalyzerApp({super.key});

  @override
  State<JobResumeAnalyzerApp> createState() => _JobResumeAnalyzerAppState();
}

class _JobResumeAnalyzerAppState extends State<JobResumeAnalyzerApp> {
  late final router = AppRouter.createRouter(context.read<AuthProvider>());

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp.router(
      title: 'AI Powered Job & Resume Analyzer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      routerConfig: router,
    );
  }

  @override
  void dispose() {
    router.dispose();
    super.dispose();
  }
}
