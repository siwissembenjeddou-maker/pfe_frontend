import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../../models/models.dart';
import '../../../widgets/common_widgets.dart';
import '../../../services/api_service.dart';

class ResultsTab extends StatefulWidget {
  final List<Child> Function() getChildren;
  final Future<void> Function()? onAssessmentChanged;
  const ResultsTab(
      {super.key, required this.getChildren, this.onAssessmentChanged});

  @override
  State<ResultsTab> createState() => _ResultsTabState();
}

class _ResultsTabState extends State<ResultsTab> {
  (String, Color)? _levelForScore(Object? score) {
    if (score == null) return null;
    final s =
        (score is num) ? score.toDouble() : double.tryParse(score.toString());
    if (s == null) return null;
    if (s < 3) return ('Mild', AppTheme.accent);
    if (s < 6) return ('Moderate', AppTheme.warning);
    return ('Severe', AppTheme.danger);
  }

  Future<void> _deleteAssessment(
      String assessmentId, String activityType) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assessment?'),
        content: Text(
          'Are you sure you want to delete the "$activityType" assessment? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.deleteAssessment(assessmentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assessment deleted successfully.'),
            backgroundColor: Colors.green,
          ),
        );
        await widget.onAssessmentChanged?.call();
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final children = widget.getChildren();
    if (children.isEmpty) {
      return const EmptyState(
        icon: Icons.bar_chart_outlined,
        message: 'No children. Add a child on the Home tab to see results.',
      );
    }

    return RefreshIndicator(
      onRefresh: widget.onAssessmentChanged ?? () async {},
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: children.length,
        itemBuilder: (context, index) {
          final child = children[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              child.name[0],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                child.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                '${child.age} years • ${child.gender}',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (child.assessments.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          final level = _levelForScore(child.finalScore);
                          if (level == null) return const SizedBox.shrink();
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: level.$2.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: level.$2.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Final Score: ${double.tryParse(child.finalScore.toString())?.toStringAsFixed(1) ?? child.finalScore.toString()}',
                                  style: TextStyle(
                                    color: level.$2,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  level.$1,
                                  style: TextStyle(
                                    color: level.$2,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Recent Assessments:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ...child.assessments.take(3).map(
                            (assessment) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Card(
                                margin: EdgeInsets.zero,
                                child: ExpansionTile(
                                  title: Text(
                                    '${assessment.activityType} - ${assessment.severityLevel}',
                                  ),
                                  subtitle: (() {
                                    final corrected = assessment.correctedScore;
                                    final score =
                                        corrected ?? assessment.autismScore;
                                    final suffix = corrected != null
                                        ? ' (changed by the psychologist)'
                                        : '';
                                    return Text(
                                        // ignore: unnecessary_type_check
                                        '${(score is num) ? score.toDouble().toStringAsFixed(1) : (double.tryParse(score.toString())?.toStringAsFixed(1) ?? 0.0.toStringAsFixed(1))} score$suffix');
                                  })(),
                                  leading: Icon(
                                    Icons.assessment,
                                    color: assessment.severityColor,
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (assessment.audioTranscription
                                              .isNotEmpty) ...[
                                            const Text(
                                              'Transcription:',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.grey
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: SelectableText(
                                                assessment.audioTranscription,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: AppTheme.textPrimary,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                          ],
                                          const Text(
                                            'AI Analysis:',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            assessment.aiAnalysis ??
                                                'No analysis',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.textPrimary,
                                              height: 1.4,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              onPressed: () =>
                                                  _deleteAssessment(
                                                assessment.id,
                                                assessment.activityType,
                                              ),
                                              icon: const Icon(Icons.delete),
                                              label: const Text('Delete'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red
                                                    .withValues(alpha: 0.1),
                                                foregroundColor:
                                                    Colors.red[700],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                    ] else
                      const EmptyState(
                        icon: Icons.analytics_outlined,
                        message: 'No assessments yet. Use the Assess tab.',
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
