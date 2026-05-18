// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../main.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/common_widgets.dart';
import '../../models/models.dart';

import 'dashboard_tab.dart';
import '_assessment_tab.dart';
import '_results_tab.dart';
import '_notifications_tab.dart';
import '_solutions_wrapper.dart';

import 'solutions_screen.dart';
import 'assessment_result_card.dart';

class ParentScreen extends StatefulWidget {
  const ParentScreen({super.key});

  @override
  State<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> {
  int _currentIndex = 0;
  List<Child> _children = [];
  List<dynamic> _notifications = [];
  bool _loading = true;
  Child? _selectedChildForSolutions;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final user = context.read<AuthService>().currentUser;
      final childrenData = await ApiService.getChildren(parentId: user?.id);
      final notifData = await ApiService.getNotifications();

      if (!mounted) return;
      setState(() {
        _children = childrenData.map((c) => Child.fromJson(c)).toList();
        _notifications = notifData;
        _loading = false;
        _selectedChildForSolutions = _children.isNotEmpty
            ? _children.firstWhere(
                (c) => c.assessments.isNotEmpty,
                orElse: () => _children.first,
              )
            : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: $e')),
      );
    }
  }

  void _openSolutionsForChild(Child child) {
    setState(() {
      _selectedChildForSolutions = child;
      _currentIndex = 3;
    });
  }

  Future<void> _showAddChildDialog() async {
    final bool? shouldRefresh = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => _AddChildDialog(parentContext: context),
    );

    if (shouldRefresh == true) {
      await _loadData();
    }
  }

  Future<void> _showEditChildDialog(Child child) async {
    final bool? shouldRefresh = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) =>
          _EditChildDialog(child: child, parentContext: context),
    );

    if (shouldRefresh == true) {
      await _loadData();
    }
  }

  void _confirmDeleteChild(Child child) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Child'),
        content: Text('Remove ${child.name}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
            ),
            onPressed: () async {
              try {
                await ApiService.deleteChild(child.id);
                if (!context.mounted) return;
                Navigator.pop(dialogCtx, true);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting child: $e')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;

    final pages = [
      DashboardTab(
        getChildren: () => _children,
        onRefresh: _loadData,
        onAddChild: _showAddChildDialog,
        onViewSolutions: _openSolutionsForChild,
        onEditChild: (child) => _showEditChildDialog(child),
        onDeleteChild: (child) => _confirmDeleteChild(child),
      ),
      AssessmentTab(
        children: _children,
        onAssessmentSaved: _loadData,
      ),
      ResultsTab(
        getChildren: () => _children,
        onAssessmentChanged: _loadData,
      ),
      SolutionsWrapper(
        getChildren: () => _children,
        getSelectedChild: () => _selectedChildForSolutions,
        onChildChanged: (child) =>
            setState(() => _selectedChildForSolutions = child),
      ),
      NotificationsTab(
        getNotifications: () => _notifications,
        onRefresh: _loadData,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AutiSense',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Parent: ${user?.name ?? ''}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => setState(() => _currentIndex = 4),
              ),
              if (_notifications.any((n) => n['is_read'] == false))
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppTheme.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthService>().logout();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        indicatorColor: AppTheme.primary.withAlpha(38),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.mic_outlined),
            selectedIcon: Icon(Icons.mic),
            label: 'Assess',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Results',
          ),
          NavigationDestination(
            icon: Icon(Icons.lightbulb_outline),
            selectedIcon: Icon(Icons.lightbulb),
            label: 'Solutions',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _showAddChildDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Child'),
              backgroundColor: AppTheme.primary,
            )
          : null,
    );
  }
}

class _AddChildDialog extends StatefulWidget {
  final BuildContext parentContext;
  const _AddChildDialog({required this.parentContext});

  @override
  State<_AddChildDialog> createState() => _AddChildDialogState();
}

class _AddChildDialogState extends State<_AddChildDialog> {
  final _nameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  String _gender = 'male';
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Add Child Profile'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: "Child's Name"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dobCtrl,
              decoration: const InputDecoration(
                labelText: 'Date of Birth',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime(2018),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  _dobCtrl.text = DateFormat('yyyy-MM-dd').format(date);
                }
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Gender: '),
                ChoiceChip(
                  label: const Text('Male'),
                  selected: _gender == 'male',
                  onSelected: (_) => setState(() => _gender = 'male'),
                ),
                ChoiceChip(
                  label: const Text('Female'),
                  selected: _gender == 'female',
                  onSelected: (_) => setState(() => _gender = 'female'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitting
              ? null
              : () async {
                  if (_nameCtrl.text.isEmpty || _dobCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(widget.parentContext).showSnackBar(
                      const SnackBar(content: Text('Please fill all fields')),
                    );
                    return;
                  }
                  setState(() => _submitting = true);
                  try {
                    final user =
                        widget.parentContext.read<AuthService>().currentUser;
                    await ApiService.addChild({
                      'name': _nameCtrl.text,
                      'date_of_birth': _dobCtrl.text,
                      'gender': _gender,
                      'parent_id': user?.id,
                    });
                    if (!mounted) return;
                    Navigator.pop(context, true);
                  } catch (e) {
                    setState(() => _submitting = false);
                    if (!mounted) return;
                    ScaffoldMessenger.of(widget.parentContext).showSnackBar(
                      SnackBar(content: Text('Error adding child: $e')),
                    );
                  }
                },
          child: _submitting
              ? const SizedBox(
                  width: 20, height: 20, child: CircularProgressIndicator())
              : const Text('Add'),
        ),
      ],
    );
  }
}

class _EditChildDialog extends StatefulWidget {
  final Child child;
  final BuildContext parentContext;
  const _EditChildDialog({required this.child, required this.parentContext});

  @override
  State<_EditChildDialog> createState() => _EditChildDialogState();
}

class _EditChildDialogState extends State<_EditChildDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _dobCtrl;
  late String _gender;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.child.name);
    _dobCtrl = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(widget.child.dateOfBirth),
    );
    _gender = widget.child.gender;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Edit Child Profile'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: "Child's Name"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dobCtrl,
              decoration: const InputDecoration(
                labelText: 'Date of Birth',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: widget.child.dateOfBirth,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  _dobCtrl.text = DateFormat('yyyy-MM-dd').format(date);
                }
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Gender: '),
                ChoiceChip(
                  label: const Text('Male'),
                  selected: _gender == 'male',
                  onSelected: (_) => setState(() => _gender = 'male'),
                ),
                ChoiceChip(
                  label: const Text('Female'),
                  selected: _gender == 'female',
                  onSelected: (_) => setState(() => _gender = 'female'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitting
              ? null
              : () async {
                  setState(() => _submitting = true);
                  try {
                    await ApiService.updateChild(widget.child.id, {
                      'name': _nameCtrl.text,
                      'date_of_birth': _dobCtrl.text,
                      'gender': _gender,
                    });
                    if (!mounted) return;
                    Navigator.pop(context, true);
                  } catch (e) {
                    setState(() => _submitting = false);
                    if (!mounted) return;
                    ScaffoldMessenger.of(widget.parentContext).showSnackBar(
                      SnackBar(content: Text('Error updating child: $e')),
                    );
                  }
                },
          child: _submitting
              ? const SizedBox(
                  width: 20, height: 20, child: CircularProgressIndicator())
              : const Text('Save'),
        ),
      ],
    );
  }
}
