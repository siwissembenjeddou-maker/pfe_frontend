// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../models/models.dart';
import '../../../main.dart';
import '../../../services/api_service.dart';

class AssessmentTab extends StatefulWidget {
  const AssessmentTab(
      {super.key, required this.children, this.onAssessmentSaved});
  final List<Child> children;
  final Future<void> Function()? onAssessmentSaved;

  @override
  State<AssessmentTab> createState() => _AssessmentTabState();
}

class _AssessmentTabState extends State<AssessmentTab> {
  Child? _selectedChild;
  String _selectedActivity =
      activityTypes.first; // default from models.activityTypes[0]
  bool _isRecording = false;
  bool _isAnalyzing = false;
  bool _useTextInput = false;
  final AudioRecorder _recorder = AudioRecorder();
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _timer;
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Audio recording is not supported on the web. Please use Android or iOS.',
            ),
          ),
        );
      }
      return;
    }

    try {
      final status = await Permission.microphone.request();

      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Microphone permission required. Status: $status',
              ),
            ),
          );
        }
        return;
      }

      final dir = await getTemporaryDirectory();
      _recordingPath =
          '${dir.path}/assessment_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(const RecordConfig(), path: _recordingPath!);

      if (!mounted) return;
      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });
      _startTimer();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recording failed to start: $e')),
        );
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRecording && mounted) {
        setState(() => _recordingDuration += const Duration(seconds: 1));
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _stopAndAnalyze() async {
    await _recorder.stop();
    _timer?.cancel();

    setState(() {
      _isRecording = false;
      _isAnalyzing = true;
    });

    try {
      if (_recordingPath == null || _selectedChild == null) {
        throw Exception('No recording or child selected');
      }

      final response = await ApiService.uploadAudio(
          File(_recordingPath!), _selectedChild!.id, _selectedActivity);

      if (response.containsKey('error')) {
        throw Exception(response['error'] ?? 'Unknown server error');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Analysis complete! Check the Results tab.'),
            backgroundColor: Colors.green,
          ),
        );
        await widget.onAssessmentSaved?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  Future<void> _submitTextAssessment() async {
    if (_selectedChild == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Select a child before submitting text.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final text = _textController.text.trim();
    if (text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter the observation text first.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final response = await ApiService.analyzeText(
        text,
        _selectedChild!.id,
        _selectedActivity,
      );

      if (response.containsKey('error')) {
        throw Exception(response['error'] ?? 'Unknown server error');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Text assessment submitted! Check Results.'),
            backgroundColor: Colors.green,
          ),
        );
        _textController.clear();
        await widget.onAssessmentSaved?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Text analysis failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'New Assessment',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Child selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Child',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Child>(
                    initialValue: _selectedChild,
                    hint: const Text('Choose your child'),
                    items: widget.children
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text('${c.name} (${c.age} yrs)'),
                            ))
                        .toList(),
                    onChanged: (child) =>
                        setState(() => _selectedChild = child),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.child_care),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Activity selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Activity Type',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: activityTypes.map((activity) {
                      final isSelected = _selectedActivity == activity;
                      final icon = activityIcons[activity] ?? '🏷️';
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedActivity = activity),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          constraints: const BoxConstraints(minWidth: 130),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primary.withValues(alpha: 0.16)
                                : AppTheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.textMuted.withValues(alpha: 0.3),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? AppTheme.primary.withValues(alpha: 0.2)
                                    : Colors.black.withValues(alpha: 0.04),
                                blurRadius: isSelected ? 8 : 12,
                                offset: isSelected
                                    ? const Offset(0, 2)
                                    : const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                icon,
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      activity,
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? AppTheme.primary
                                            : AppTheme.textPrimary,
                                      ),
                                    ),
                                    if (isSelected)
                                      Text(
                                        'Selected',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Input mode toggle
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Voice'),
                  selected: !_useTextInput,
                  selectedColor: AppTheme.primary.withValues(alpha: 0.18),
                  backgroundColor: AppTheme.surface,
                  labelStyle: TextStyle(
                    color: !_useTextInput
                        ? AppTheme.primary
                        : AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _useTextInput = false;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Text input'),
                  selected: _useTextInput,
                  selectedColor: AppTheme.primary.withValues(alpha: 0.18),
                  backgroundColor: AppTheme.surface,
                  labelStyle: TextStyle(
                    color:
                        _useTextInput ? AppTheme.primary : AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _useTextInput = true;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _useTextInput
                        ? 'Enter the child observation text below and submit it for analysis. Include details about behavior, speech, and activity performance.'
                        : 'Press Record and describe how your child performs the selected activity. Be specific and detailed (1-2 minutes).',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (_useTextInput) ...[
            TextField(
              controller: _textController,
              minLines: 6,
              maxLines: 12,
              decoration: InputDecoration(
                hintText:
                    'Describe what your child did, how they responded, and any important details.',
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedChild == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Select a child before submitting text.',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade700,
                ),
                onPressed: _selectedChild == null || _isAnalyzing
                    ? null
                    : _submitTextAssessment,
                icon: const Icon(Icons.send),
                label: Text(_isAnalyzing ? 'Submitting...' : 'Submit Text'),
              ),
            ),
          ] else ...[
            Column(
              children: [
                if (_isRecording)
                  Text(
                    '${_recordingDuration.inMinutes.toString().padLeft(2, '0')}:${(_recordingDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      letterSpacing: 2,
                    ),
                  ),
                if (_isAnalyzing) ...[
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue)),
                  const SizedBox(height: 16),
                  const Text('Analyzing your recording...',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ],
                if (kIsWeb)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Audio recording is not supported on web. Use a mobile device for assessments.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary),
                    ),
                  )
                else
                  const SizedBox(height: 24),
                GestureDetector(
                  onTap: (kIsWeb || _selectedChild == null || _isAnalyzing)
                      ? null
                      : _isRecording
                          ? _stopAndAnalyze
                          : _startRecording,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (kIsWeb || _selectedChild == null || _isAnalyzing)
                          ? Colors.grey
                          : _isRecording
                              ? Colors.red
                              : AppTheme.primary,
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording ? Colors.red : AppTheme.primary)
                              .withValues(alpha: 0.4),
                          blurRadius: _isRecording ? 30 : 15,
                          spreadRadius: _isRecording ? 8 : 3,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isAnalyzing
                          ? Icons.hourglass_empty
                          : _isRecording
                              ? Icons.stop
                              : Icons.mic,
                      color: Colors.white,
                      size: 56,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  kIsWeb
                      ? 'Recording disabled in web mode'
                      : _isAnalyzing
                          ? 'Processing with AI...'
                          : _selectedChild == null
                              ? 'Select child first'
                              : _isRecording
                                  ? 'Tap to stop recording'
                                  : 'Tap microphone to start',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
