import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../../models/models.dart';
import '../../../services/auth_service.dart';
import 'package:provider/provider.dart';

class DashboardTab extends StatelessWidget {
  final List<Child> Function() getChildren;
  final VoidCallback onRefresh;
  final VoidCallback onAddChild;
  final void Function(Child) onViewSolutions;
  final void Function(Child) onEditChild;
  final void Function(Child) onDeleteChild;

  const DashboardTab({
    super.key,
    required this.getChildren,
    required this.onRefresh,
    required this.onAddChild,
    required this.onViewSolutions,
    required this.onEditChild,
    required this.onDeleteChild,
  });

  (String, Color)? _levelForScore(double? score) {
    if (score == null) return null;
    if (score < 3) return ('Mild', AppTheme.accent);
    if (score < 6) return ('Moderate', AppTheme.warning);
    return ('Severe', AppTheme.danger);
  }

  @override
  Widget build(BuildContext context) {
    final children = getChildren();
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${context.read<AuthService>().currentUser?.name ?? 'Parent'}! 👋',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${children.length} child profile(s) registered',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 36,
                      child: OutlinedButton.icon(
                        onPressed: onAddChild,
                        icon: const Icon(Icons.person_add, color: Colors.white),
                        label: const Text('Register Child',
                            style: TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white54),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.family_restroom,
                    color: Colors.white, size: 40),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          const Text(
            'My Children',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (children.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  const Icon(Icons.child_care, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No children added yet.'),
                  const SizedBox(height: 8),
                  const Text('Tap + to add your child.',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onAddChild,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Register Child'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ...children.map((child) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                shadowColor: AppTheme.primary.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            child.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(child.name,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary)),
                            Text(
                                '${child.age} years • ${child.gender.toString().split('.').last.capitalize()}',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 14)),
                            if (child.assessments.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.accent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                    '${child.assessments.length} assessment(s)',
                                    style: const TextStyle(
                                        color: AppTheme.accent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500)),
                              ),
                          ],
                        ),
                      ),
                      Builder(
                        builder: (context) {
                          final level =
                              _levelForScore(child.finalScore as double?);
                          if (level == null) return const SizedBox.shrink();
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
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
                                  (child.finalScore == null)
                                      ? '--'
                                      : (double.tryParse(
                                                  child.finalScore!.toString())
                                              ?.toStringAsFixed(1) ??
                                          child.finalScore!.toString()),
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
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert,
                            color: AppTheme.textSecondary),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            onTap: () => onViewSolutions(child),
                            child: const Row(children: [
                              Icon(Icons.lightbulb, color: AppTheme.accent),
                              SizedBox(width: 8),
                              Text('View Solutions',
                                  style: TextStyle(color: AppTheme.textPrimary))
                            ]),
                          ),
                          PopupMenuItem(
                            onTap: () => onEditChild(child),
                            child: const Row(children: [
                              Icon(Icons.edit, color: AppTheme.primary),
                              SizedBox(width: 8),
                              Text('Edit',
                                  style: TextStyle(color: AppTheme.textPrimary))
                            ]),
                          ),
                          PopupMenuItem(
                            onTap: () => onDeleteChild(child),
                            child: Row(children: [
                              Icon(Icons.delete, color: AppTheme.danger),
                              SizedBox(width: 8),
                              Text('Delete',
                                  style: TextStyle(color: AppTheme.danger))
                            ]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

extension NumToStringAsFixed on num {
  String toStringAsFixed(int digits) => toStringAsFixed(digits);
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
