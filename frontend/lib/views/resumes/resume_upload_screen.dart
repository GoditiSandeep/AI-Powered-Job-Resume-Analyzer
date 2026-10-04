import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/routing/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/resume_provider.dart';
import '../../widgets/custom_button.dart';

class ResumeUploadScreen extends StatefulWidget {
  const ResumeUploadScreen({super.key});

  @override
  State<ResumeUploadScreen> createState() => _ResumeUploadScreenState();
}

class _ResumeUploadScreenState extends State<ResumeUploadScreen> {
  String? _selectedFileName;
  String? _selectedFilePath;
  Uint8List? _selectedFileBytes;
  int? _selectedFileSize;

  final _textResumeController = TextEditingController();
  final _targetJobController = TextEditingController();
  bool _isPasteMode = false;

  @override
  void dispose() {
    _textResumeController.dispose();
    _targetJobController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'doc', 'txt'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _selectedFileName = file.name;
          _selectedFilePath = file.path;
          _selectedFileBytes = file.bytes;
          _selectedFileSize = file.size;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _handleUpload() async {
    final resumeProv = context.read<ResumeProvider>();

    if (!_isPasteMode && _selectedFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a resume file or paste your resume text.')),
      );
      return;
    }

    if (_isPasteMode && _textResumeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste your resume content.')),
      );
      return;
    }

    String fileName = _selectedFileName ?? 'Resume_Pasted_${DateTime.now().millisecondsSinceEpoch}.txt';
    Uint8List? bytes = _selectedFileBytes;
    if (_isPasteMode) {
      bytes = Uint8List.fromList(utf8.encode(_textResumeController.text.trim()));
      fileName = 'Pasted_Resume.txt';
    }

    final newResume = await resumeProv.uploadResume(
      fileName: fileName,
      filePath: _selectedFilePath,
      fileBytes: bytes,
    );

    if (!mounted) return;

    if (newResume != null) {
      // If user specified target job, trigger targeted re-analysis
      if (_targetJobController.text.trim().isNotEmpty) {
        await resumeProv.reanalyzeResume(
          newResume.id,
          targetJobTitle: _targetJobController.text.trim(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resume uploaded and analyzed successfully!'), backgroundColor: AppColors.success),
        );
        context.go(RouteNames.resumeAnalysis.replaceAll(':id', newResume.id.toString()));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resumeProv.errorMessage ?? 'Upload failed. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final resumeProv = context.watch<ResumeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload & Analyze Resume', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Mode Toggle (File Upload vs Paste Text)
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.upload_file, size: 18),
                            SizedBox(width: 8),
                            Text('Upload Document'),
                          ],
                        ),
                        selected: !_isPasteMode,
                        onSelected: (val) => setState(() => _isPasteMode = !val),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.text_fields, size: 18),
                            SizedBox(width: 8),
                            Text('Paste Resume Text'),
                          ],
                        ),
                        selected: _isPasteMode,
                        onSelected: (val) => setState(() => _isPasteMode = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (!_isPasteMode) ...[
                  // File Drop / Selection Card
                  InkWell(
                    onTap: resumeProv.isUploading ? null : _pickFile,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedFileName != null ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _selectedFileName != null ? Icons.check_circle_outline : Icons.cloud_upload_outlined,
                              size: 36,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedFileName ?? 'Click to select resume document',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _selectedFileSize != null
                                ? 'Size: ${(_selectedFileSize! / 1024).toStringAsFixed(1)} KB'
                                : 'Supports PDF, DOCX, DOC, and TXT (up to 10MB)',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                          if (_selectedFileName != null) ...[
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: _pickFile,
                              icon: const Icon(Icons.change_circle_outlined, size: 16),
                              label: const Text('Change File'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Paste Text Area
                  TextField(
                    controller: _textResumeController,
                    maxLines: 12,
                    decoration: InputDecoration(
                      labelText: 'Paste your raw resume text here',
                      alignLabelWithHint: true,
                      hintText: 'Work Experience\nSoftware Engineer at Tech Corp (2022 - Present)\n- Built scalable REST APIs in Python FastAPI...',
                      fillColor: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                      filled: true,
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Optional Target Job Tuning
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.tune_rounded, size: 18, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text('Optional Job Target', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Specify a target role (e.g. Senior Full Stack Developer) for specialized ATS keyword optimization.',
                          style: TextStyle(fontSize: 12.5, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _targetJobController,
                          decoration: const InputDecoration(
                            labelText: 'Target Job Title (Optional)',
                            prefixIcon: Icon(Icons.work_outline),
                            hintText: 'e.g. Senior Python Developer',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Upload & Analyze Button
                CustomButton(
                  text: 'Analyze Resume with AI',
                  icon: Icons.auto_awesome,
                  isLoading: resumeProv.isUploading || resumeProv.isAnalyzing,
                  onPressed: _handleUpload,
                  height: 52,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
