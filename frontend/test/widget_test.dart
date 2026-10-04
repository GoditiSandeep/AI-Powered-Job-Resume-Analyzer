import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_job_resume_analyzer/widgets/custom_button.dart';
import 'package:ai_job_resume_analyzer/widgets/score_gauge.dart';
import 'package:ai_job_resume_analyzer/widgets/skill_chip.dart';
import 'package:ai_job_resume_analyzer/widgets/empty_state_view.dart';
import 'package:ai_job_resume_analyzer/core/network/api_client.dart';
import 'package:ai_job_resume_analyzer/core/storage/secure_storage.dart';
import 'package:ai_job_resume_analyzer/main.dart';
import 'package:ai_job_resume_analyzer/providers/auth_provider.dart';
import 'package:ai_job_resume_analyzer/providers/theme_provider.dart';

void main() {
  group('Frontend Widgets Unit and Component Tests', () {
    testWidgets('CustomButton renders label and triggers callback', (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Test Button',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      await tester.tap(find.text('Test Button'));
      expect(pressed, true);
    });

    testWidgets('ScoreGauge displays percentage score correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScoreGauge(
              score: 85.0,
              title: 'ATS Match',
            ),
          ),
        ),
      );

      expect(find.text('85%'), findsOneWidget);
      expect(find.text('ATS Match'), findsOneWidget);
    });

    testWidgets('SkillChip renders matched and missing states', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SkillChip(label: 'Python', isMatched: true),
                SkillChip(label: 'Docker', isMissing: true),
                SkillChip(label: 'MLOps', priority: 'high'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Python'), findsOneWidget);
      expect(find.text('Docker'), findsOneWidget);
      expect(find.text('MLOps'), findsOneWidget);
      expect(find.text('HIGH'), findsOneWidget);
    });

    testWidgets('EmptyStateView renders title, description, and action', (WidgetTester tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateView(
              title: 'No Jobs Found',
              description: 'Try adjusting your search criteria.',
              actionText: 'Retry Search',
              onAction: () => actionTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('No Jobs Found'), findsOneWidget);
      expect(find.text('Try adjusting your search criteria.'), findsOneWidget);
      expect(find.text('Retry Search'), findsOneWidget);

      await tester.tap(find.text('Retry Search'));
      expect(actionTriggered, true);
    });

    testWidgets('app startup advances from splash when no token is stored', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final storageService = await StorageService.getInstance();
      final authProvider = AuthProvider(ApiClient(storageService), storageService);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: ThemeProvider(storageService)),
          ],
          child: const JobResumeAnalyzerApp(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 1700));
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Job & Resume AI'), findsNothing);
    });
  });
}
