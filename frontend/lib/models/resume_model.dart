class ResumeModel {
  final int id;
  final int userId;
  final String fileName;
  final String fileType;
  final String filePath;
  final int? fileSizeBytes;
  final String? extractedText;
  final DateTime? createdAt;
  final double? latestScore;
  final double? latestAtsScore;

  ResumeModel({
    required this.id,
    required this.userId,
    required this.fileName,
    required this.fileType,
    required this.filePath,
    this.fileSizeBytes,
    this.extractedText,
    this.createdAt,
    this.latestScore,
    this.latestAtsScore,
  });

  factory ResumeModel.fromJson(Map<String, dynamic> json) {
    double? score;
    double? ats;
    if (json['latest_analysis'] is Map) {
      score = (json['latest_analysis']['overall_score'] as num?)?.toDouble();
      ats = (json['latest_analysis']['ats_score'] as num?)?.toDouble();
    }

    return ResumeModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString()) ?? 0,
      fileName: json['file_name'] ?? 'Resume',
      fileType: json['file_type'] ?? 'pdf',
      filePath: json['file_path'] ?? '',
      fileSizeBytes: json['file_size_bytes'],
      extractedText: json['extracted_text'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      latestScore: score,
      latestAtsScore: ats,
    );
  }
}
