import 'package:flutter_test/flutter_test.dart';
import 'package:ai_job_resume_analyzer/models/user_model.dart';
import 'package:ai_job_resume_analyzer/models/job_model.dart';
import 'package:ai_job_resume_analyzer/models/resume_model.dart';
import 'package:ai_job_resume_analyzer/models/resume_analysis_model.dart';
import 'package:ai_job_resume_analyzer/models/application_model.dart';
import 'package:ai_job_resume_analyzer/models/skill_model.dart';
import 'package:ai_job_resume_analyzer/models/career_recommendation_model.dart';
import 'package:ai_job_resume_analyzer/models/admin_stats_model.dart';

void main() {
  group('Frontend Models Serialization and Parsing Tests', () {
    test('UserModel deserializes correctly', () {
      final json = {
        'id': 1,
        'name': 'Godithi Sandeep',
        'email': 'admin@analyzer.local',
        'role': 'ADMIN',
        'is_active': true,
        'resumes_count': 5,
        'applications_count': 3,
        'latest_ats_score': 88.5,
      };
      final user = UserModel.fromJson(json);

      expect(user.id, 1);
      expect(user.name, 'Godithi Sandeep');
      expect(user.isAdmin, true);
      expect(user.latestAtsScore, 88.5);
    });

    test('JobModel and JobMatchModel parse correctly', () {
      final jobJson = {
        'id': 10,
        'title': 'Senior Python AI Engineer',
        'company': 'NextGen AI Labs',
        'location': 'Remote',
        'salary': r'$130k - $160k',
        'required_skills': ['Python', 'FastAPI', 'PyTorch'],
        'is_saved': true,
        'match_percentage': 92.0,
      };
      final job = JobModel.fromJson(jobJson);

      expect(job.id, 10);
      expect(job.title, 'Senior Python AI Engineer');
      expect(job.requiredSkills.length, 3);
      expect(job.isSaved, true);
      expect(job.matchPercentage, 92.0);

      final matchJson = {
        'job_id': 10,
        'job_title': 'Senior Python AI Engineer',
        'company': 'NextGen AI Labs',
        'overall_match_percentage': 92.0,
        'skill_match_score': 95.0,
        'keyword_match_score': 88.0,
        'experience_match_score': 90.0,
        'education_match_score': 95.0,
        'matched_skills': ['Python', 'FastAPI'],
        'missing_skills': ['PyTorch'],
      };
      final match = JobMatchModel.fromJson(matchJson);

      expect(match.overallMatchPercentage, 92.0);
      expect(match.matchedSkills, contains('Python'));
      expect(match.missingSkills, contains('PyTorch'));
    });

    test('ResumeModel and ResumeAnalysisModel parse correctly', () {
      final resumeJson = {
        'id': 4,
        'user_id': 1,
        'file_name': 'Sandeep_Resume.pdf',
        'file_type': 'pdf',
        'file_path': 'uploads/sandeep.pdf',
        'latest_analysis': {
          'overall_score': 85.0,
          'ats_score': 90.0,
        },
      };
      final resume = ResumeModel.fromJson(resumeJson);

      expect(resume.id, 4);
      expect(resume.fileName, 'Sandeep_Resume.pdf');
      expect(resume.latestAtsScore, 90.0);

      final analysisJson = {
        'id': 1,
        'resume_id': 4,
        'overall_score': 85.0,
        'ats_score': 90.0,
        'strengths': ['Clear layout', 'High impact bullet points'],
        'weaknesses': ['Add Docker certification'],
        'detected_keywords': ['Python', 'FastAPI', 'Flutter'],
        'missing_keywords': ['Kubernetes'],
        'section_scores': {'impact': 85, 'keywords': 90},
        'improvements': [
          {
            'section': 'Experience',
            'original': 'Did backend work',
            'improved': 'Architected scalable REST backend handling 10k requests/sec',
            'reason': 'Quantified business impact',
          }
        ],
      };
      final analysis = ResumeAnalysisModel.fromJson(analysisJson);

      expect(analysis.atsScore, 90.0);
      expect(analysis.strengths.length, 2);
      expect(analysis.detectedKeywords, contains('Flutter'));
      expect(analysis.improvements.first.improved, contains('Architected scalable'));
    });

    test('ApplicationModel and SkillGapModel parse correctly', () {
      final appJson = {
        'id': 2,
        'user_id': 1,
        'job_id': 10,
        'status': 'Interview',
        'notes': 'Round 1 technical scheduled',
      };
      final app = ApplicationModel.fromJson(appJson);

      expect(app.id, 2);
      expect(app.status, 'Interview');

      final gapJson = {
        'target_role': 'Lead ML Engineer',
        'match_percentage': 82.0,
        'high_priority': ['TensorFlow', 'MLOps'],
        'learning_recommendations': [
          {'skill': 'MLOps', 'recommendation': 'Coursera MLOps Specialization'}
        ],
      };
      final gap = SkillGapModel.fromJson(gapJson);

      expect(gap.targetRole, 'Lead ML Engineer');
      expect(gap.highPriority, contains('MLOps'));
      expect(gap.learningRecommendations.first['skill'], 'MLOps');
    });

    test('CareerRecommendation and AdminStats parse correctly', () {
      final careerJson = {
        'role_title': 'Staff AI Architect',
        'match_percentage': 88.0,
        'salary_range': r'$160k - $210k',
        'demand_level': 'Very High',
        'skill_gaps': ['Distributed Systems', 'Kubernetes'],
        'next_steps': ['Gain CKA certification', 'Lead architecture review'],
      };
      final career = CareerRecommendationModel.fromJson(careerJson);

      expect(career.roleTitle, 'Staff AI Architect');
      expect(career.matchPercentage, 88.0);
      expect(career.demandLevel, 'Very High');

      final adminStatsJson = {
        'total_users': 15,
        'active_users': 14,
        'total_resumes': 28,
        'total_analyses': 35,
        'total_jobs': 12,
        'total_applications': 18,
        'average_resume_score': 82.5,
        'average_ats_score': 86.4,
      };
      final adminStats = AdminDashboardStatsModel.fromJson(adminStatsJson);

      expect(adminStats.totalUsers, 15);
      expect(adminStats.averageAtsScore, 86.4);
    });
  });
}
