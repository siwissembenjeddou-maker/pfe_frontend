import 'package:flutter/material.dart';
import '../../main.dart';

class AssessmentResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  const AssessmentResultCard({required this.result, super.key});

  @override
  Widget build(BuildContext context) {
    final _ = result['child_name'] ?? 'Your Child';
    // _parentName removed (unused) to satisfy analyzer.

    final hasPsychologistChange = result['corrected_score'] != null;
    final score = (result['corrected_score'] as num?)?.toDouble() ??
        (result['autism_score'] as num?)?.toDouble() ??
        0.0;
    final severity = result['severity_level'] ?? 'Unknown';
    final transcription = result['audio_transcription'] ??
        result['transcription'] ??
        'No transcription available';
    final analysis = result['ai_analysis'] ?? 'No analysis available';

    return Card(
      margin: const EdgeInsets.only(top: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: AppTheme.primary, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Assessment Complete!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          score.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        Text(
                          hasPsychologistChange
                              ? 'Autism Score'
                              : 'Autism Score',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        if (hasPsychologistChange)
                          const Text(
                            '(changed by the psychologist)',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: score < 3
                          ? AppTheme.accent.withValues(alpha: 0.1)
                          : score < 6
                              ? AppTheme.warning.withValues(alpha: 0.1)
                              : AppTheme.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          severity.toUpperCase(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: score < 3
                                ? AppTheme.accent
                                : score < 6
                                    ? AppTheme.warning
                                    : AppTheme.danger,
                          ),
                        ),
                        const Text(
                          'Severity Level',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'What We Heard:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.fromBorderSide(
                    BorderSide(color: AppTheme.primary, width: 4)),
              ),
              child: Text(
                transcription,
                style: const TextStyle(height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'AI Analysis:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                analysis,
                style: const TextStyle(height: 1.4),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.thumb_up),
                label: const Text('Review with Psychologist'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  // Navigate to psychologist review or show notification
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sent for professional review'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
