import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../../models/models.dart';
import '../../../widgets/common_widgets.dart';
import 'solutions_screen.dart';

class SolutionsWrapper extends StatelessWidget {
  final List<Child> Function() getChildren;
  final Child? Function() getSelectedChild;
  final void Function(Child) onChildChanged;

  const SolutionsWrapper({
    super.key,
    required this.getChildren,
    required this.getSelectedChild,
    required this.onChildChanged,
  });

  @override
  Widget build(BuildContext context) {
    final children = getChildren();
    final selectedChild = getSelectedChild();

    if (children.isEmpty) {
      return const EmptyState(
        icon: Icons.child_care,
        message:
            'No children added yet.\nTap + on the Home tab to add your child.',
      );
    }

    return Column(
      children: [
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.child_care,
                    color: AppTheme.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Child>(
                    value: selectedChild,
                    isExpanded: true,
                    hint: const Text('Select child to view solutions',
                        style: TextStyle(color: AppTheme.textSecondary)),
                    icon: const Icon(Icons.arrow_drop_down,
                        color: AppTheme.primary),
                    items: children
                        .map((child) => DropdownMenuItem(
                              value: child,
                              child: Text(
                                '${child.name} (${child.age} years)',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary),
                              ),
                            ))
                        .toList(),
                    onChanged: (child) {
                      if (child != null) onChildChanged(child);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1),
        Expanded(
          child: selectedChild == null
              ? const Padding(
                  padding: EdgeInsets.all(40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.lightbulb_outline,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Select a child above',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'to view personalized solutions and recommendations',
                        style: TextStyle(color: AppTheme.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              // Keyed to selected child to avoid keeping old tab state
              // when switching dropdown values.
              : SolutionsTab(
                  key: ValueKey(selectedChild.id), child: selectedChild),
        ),
      ],
    );
  }
}
