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
    final nameCtrl = TextEditingController();
    final dobCtrl = TextEditingController();
    String gender = 'male';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Add Child Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: "Child's Name",
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dobCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime(2018),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      dobCtrl.text = DateFormat('yyyy-MM-dd').format(date);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Gender: '),
                    ChoiceChip(
                      label: const Text('Male'),
                      selected: gender == 'male',
                      onSelected: (_) => setS(() => gender = 'male'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Female'),
                      selected: gender == 'female',
                      onSelected: (_) => setS(() => gender = 'female'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final user = context.read<AuthService>().currentUser;
                  await ApiService.addChild({
                    'name': nameCtrl.text,
                    'date_of_birth': dobCtrl.text,
                    'gender': gender,
                    'parent_id': user?.id,
                  });
                  if (!context.mounted) return;
                  Navigator.pop(ctx);
                  await _loadData();
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding child: $e')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    nameCtrl.dispose();
    dobCtrl.dispose();
  }

  void _showEditChildDialog(Child child) {
    final nameCtrl = TextEditingController(text: child.name);
    final dobCtrl = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(child.dateOfBirth),
    );
    String gender = child.gender;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Edit Child Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: "Child's Name",
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dobCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: child.dateOfBirth,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      dobCtrl.text = DateFormat('yyyy-MM-dd').format(date);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Gender: '),
                    ChoiceChip(
                      label: const Text('Male'),
                      selected: gender == 'male',
                      onSelected: (_) => setS(() => gender = 'male'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Female'),
                      selected: gender == 'female',
                      onSelected: (_) => setS(() => gender = 'female'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ApiService.updateChild(child.id, {
                    'name': nameCtrl.text,
                    'date_of_birth': dobCtrl.text,
                    'gender': gender,
                  });
                  if (!context.mounted) return;
                  Navigator.pop(ctx);
                  await _loadData();
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating child: $e')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    nameCtrl.dispose();
    dobCtrl.dispose();
  }

  void _confirmDeleteChild(Child child) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Child'),
        content: Text('Remove ${child.name}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
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
                Navigator.pop(ctx);
                await _loadData();
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
