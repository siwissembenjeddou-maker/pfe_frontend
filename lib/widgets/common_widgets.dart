import 'package:flutter/material.dart';
import '../main.dart';
import '../models/models.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const EmptyState({required this.icon, required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 40, color: AppTheme.primary),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class ScoreBadge extends StatelessWidget {
  final double score;
  final double? correctedScore;
  const ScoreBadge(this.score, {this.correctedScore, super.key});

  double get _effectiveScore => correctedScore ?? score;

  Color get _color {
    final s = _effectiveScore;
    if (s < 3) return AppTheme.accent;
    if (s < 6) return AppTheme.warning;
    return AppTheme.danger;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final shown = _effectiveScore;
    final isCorrected = correctedScore != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(38),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(shown.toStringAsFixed(1),
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(width: 4),
          Icon(
            isCorrected ? Icons.edit : Icons.star,
            size: 14,
            color: color,
          ),
        ],
      ),
    );
  }
}

class SeverityBadge extends StatelessWidget {
  final String severity;
  const SeverityBadge(this.severity, {super.key});

  Color get _color {
    switch (severity.toLowerCase()) {
      case 'mild':
        return AppTheme.accent;
      case 'moderate':
        return AppTheme.warning;
      case 'severe':
        return AppTheme.danger;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(38),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        severity.toUpperCase(),
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status.toLowerCase()) {
      'pending' => (AppTheme.warning, Icons.pending_outlined),
      'confirmed' => (AppTheme.accent, Icons.check_circle),
      'corrected' => (AppTheme.primary, Icons.edit),
      _ => (AppTheme.textSecondary, Icons.help_outline),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(status,
            style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class ChildCard extends StatelessWidget {
  final Child child;
  const ChildCard({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
              child: Text(
                child.name[0].toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${child.age} years • ${child.gender}',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  if (child.parentName != null)
                    Text(
                      'Parent: ${child.parentName}',
                      style: TextStyle(
                        color: AppTheme.primary.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (child.assessments.isNotEmpty)
                    Text(
                      '${child.assessments.length} assessments',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 12,
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
  }
}
