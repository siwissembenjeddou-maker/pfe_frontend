// lib/widgets/common_widgets.dart
import 'package:flutter/material.dart';
import '../main.dart';
import '../models/models.dart';

// ──────────── SECTION TITLE ────────────
class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(title,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary)),
  );
}

// ──────────── EMPTY STATE ────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const EmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(icon, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    ),
  );
}

// ──────────── CHILD CARD ────────────
class ChildCard extends StatelessWidget {
  final Child child;
  const ChildCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppTheme.primary.withOpacity(0.1),
            child: Text(child.name[0],
                style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(child.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${child.age} years • ${child.gender}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
                if (child.assessments.isNotEmpty)
                  Text('${child.assessments.length} assessments',
                      style: const TextStyle(
                          color: AppTheme.primary, fontSize: 12)),
              ],
            ),
          ),
          if (child.assessments.isNotEmpty)
            ScoreBadge(score: child.assessments.last.autismScore),
        ],
      ),
    ),
  );
}

// ──────────── SCORE BADGE ────────────
class ScoreBadge extends StatelessWidget {
  final double score;
  const ScoreBadge({super.key, required this.score});

  Color get _color {
    if (score < 3) return AppTheme.accent;
    if (score < 6) return AppTheme.warning;
    return AppTheme.danger;
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withOpacity(0.3))),
    child: Text(score.toStringAsFixed(2),
        style: TextStyle(
            color: _color, fontWeight: FontWeight.bold, fontSize: 13)),
  );
}

// ──────────── SEVERITY BADGE ────────────
class SeverityBadge extends StatelessWidget {
  final String severity;
  const SeverityBadge({super.key, required this.severity});

  Color get _color {
    switch (severity.toLowerCase()) {
      case 'mild': return AppTheme.accent;
      case 'moderate': return AppTheme.warning;
      case 'severe': return AppTheme.danger;
      default: return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8)),
    child: Text(severity.toUpperCase(),
        style: TextStyle(
            color: _color, fontWeight: FontWeight.bold, fontSize: 11)),
  );
}

// ──────────── STATUS BADGE ────────────
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  Color get _color {
    switch (status) {
      case 'pending': return AppTheme.warning;
      case 'confirmed': return AppTheme.accent;
      case 'corrected': return AppTheme.primary;
      default: return AppTheme.textSecondary;
    }
  }

  IconData get _icon {
    switch (status) {
      case 'pending': return Icons.pending;
      case 'confirmed': return Icons.check_circle;
      case 'corrected': return Icons.edit;
      default: return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(_icon, color: _color, size: 14),
      const SizedBox(width: 4),
      Text(status.toUpperCase(),
          style: TextStyle(
              color: _color, fontSize: 11, fontWeight: FontWeight.bold)),
    ],
  );
}

// ──────────── ASSESSMENT RESULT CARD ────────────
class AssessmentResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  const AssessmentResultCard({super.key, required this.result});

  Color get _scoreColor {
    final score = (result['autism_score'] as num?)?.toDouble() ?? 0;
    if (score < 3) return AppTheme.accent;
    if (score < 6) return AppTheme.warning;
    return AppTheme.danger;
  }

  @override
  Widget build(BuildContext context) {
    final score = (result['autism_score'] as num?)?.toDouble() ?? 0;
    final severity = result['severity_level'] ?? 'unknown';
    final transcription = result['transcription'] ?? '';
    final analysis = result['ai_analysis'] ?? '';
    final dimensions =
    Map<String, dynamic>.from(result['dimension_scores'] ?? {});

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _scoreColor.withOpacity(0.3), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology, color: AppTheme.primary),
                const SizedBox(width: 8),
                const Text('AI Analysis Result',
                    style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: const Color(0xFFEBF5FB),
                      borderRadius: BorderRadius.circular(6)),
                  child: const Text('AI',
                      style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11)),
                ),
              ],
            ),
            const Divider(height: 20),

            // Score display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(score.toStringAsFixed(2),
                        style: TextStyle(
                            color: _scoreColor,
                            fontSize: 48,
                            fontWeight: FontWeight.bold)),
                    Text('Autism Score / 10',
                        style: TextStyle(color: _scoreColor, fontSize: 13)),
                    const SizedBox(height: 6),
                    SeverityBadge(severity: severity),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Dimension Scores
            if (dimensions.isNotEmpty) ...[
              const Text('Dimension Breakdown',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...dimensions.entries.map((e) {
                final val = (e.value as num).toDouble();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key,
                              style: const TextStyle(fontSize: 13)),
                          Text(val.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: val / 10,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(
                          val < 3 ? AppTheme.accent : val < 6 ? AppTheme.warning : AppTheme.danger,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 6,
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],

            // Transcription
            if (transcription.isNotEmpty) ...[
              const Text('📝 Transcription',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8)),
                child: Text(transcription,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
              ),
              const SizedBox(height: 12),
            ],

            // AI Analysis
            if (analysis.isNotEmpty) ...[
              const Text('🤖 AI Interpretation',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.primary.withOpacity(0.15))),
                child: Text(analysis,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
              ),
              const SizedBox(height: 10),
            ],

            const Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: AppTheme.textSecondary),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                      'This is an AI-generated assessment. A psychologist will review and confirm these results.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}