// lib/screens/admin/admin_screen.dart
// ignore_for_file: dead_null_aware_expression

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../main.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/backup_io.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _currentIndex = 0;
  Map<String, List<dynamic>> _users = {
    'parent': [],
    'psychologist': [],
    'educator': []
  };
  List<dynamic> _children = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _backupData(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Backing up data...')),
    );

    try {
      final stats = await ApiService.getSystemStats();
      final logs = await ApiService.getSystemLogs();
      final backup = {
        'generated_at': DateTime.now().toIso8601String(),
        'system_stats': stats,
        'system_logs': logs,
      };

      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      final filename = 'autisense_backup_$timestamp.json';
      final path = await saveBackupFile(filename, jsonEncode(backup));

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(
        content:
            Text(kIsWeb ? 'Backup downloaded: $path' : 'Backup saved to $path'),
        duration: const Duration(seconds: 6),
        action: canOpenDirectory
            ? SnackBarAction(
                label: 'Open folder',
                onPressed: () => openDirectory(path),
              )
            : null,
      ));
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
          SnackBar(content: Text('Backup failed: ${e.toString()}')));
    }
  }

  Future<void> _showFullReport(BuildContext context) async {
    try {
      final stats = await ApiService.getSystemStats();
      if (!context.mounted) return;
      if (stats.isEmpty) {
        throw Exception('Failed to load report data.');
      }

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('System Report'),
          content: SingleChildScrollView(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _reportStat('Total children', stats['total_children']),
              _reportStat('Total assessments', stats['total_assessments']),
              _reportStat('Pending reviews', stats['pending_reviews']),
              const SizedBox(height: 12),
              const Text('Users',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              _reportStat('Parents', stats['total_parents']),
              _reportStat('Psychologists', stats['total_psychologists']),
              _reportStat('Educators', stats['total_educators']),
              const SizedBox(height: 12),
              const Text('Severity breakdown',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              _reportStat('Mild', stats['severity_breakdown']?['mild']),
              _reportStat('Moderate', stats['severity_breakdown']?['moderate']),
              _reportStat('Severe', stats['severity_breakdown']?['severe']),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close')),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report error: ${e.toString()}')),
        );
      }
    }
  }

  Widget _reportStat(String label, Object? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text('$label: ${value ?? 'N/A'}'),
    );
  }

  Future<void> _showAddUserDialog(BuildContext context, String role) async {
    await showDialog(
      context: context,
      builder: (_) => _AddUserDialog(role: role, onCreated: _loadData),
    );
  }

  Future<void> _loadData() async {
    final parents = await ApiService.getAllUsers(role: 'parent') ?? [];
    final psychs = await ApiService.getAllUsers(role: 'psychologist') ?? [];
    final educators = await ApiService.getAllUsers(role: 'educator') ?? [];
    final children = await ApiService.getChildren() ?? [];

    if (mounted) {
      setState(() {
        _users = {
          'parent': parents,
          'psychologist': psychs,
          'educator': educators
        };
        _children = children;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final pages = [
      _AdminDashboard(
        users: _users,
        children: _children,
        onAddUser: () => _showAddUserDialog(context, 'parent'),
        onBackup: () => _backupData(context),
        onFullReport: () => _showFullReport(context),
      ),
      _UserManagementTab(users: _users, onRefresh: _loadData),
      const _AnnouncementsTab(),
      _SystemLogTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(children: [
          const Text('AutiSense Admin',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Text(user?.name ?? '',
              style:
                  const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ]),
        backgroundColor: const Color.fromARGB(255, 43, 109, 208),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Confirm Logout'),
                    content: const Text(
                        'Are you sure you want to log out of AutiSense Admin?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.danger,
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  final authService = context.read<AuthService>();
                  await authService.logout();
                  if (!context.mounted) return;
                  Navigator.pushReplacementNamed(context, '/login');
                }
              }),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        indicatorColor: const Color(0xFF6C3483).withValues(alpha: 0.2),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.manage_accounts_outlined),
              selectedIcon: Icon(Icons.manage_accounts),
              label: 'Users'),
          NavigationDestination(
              icon: Icon(Icons.campaign_outlined),
              selectedIcon: Icon(Icons.campaign),
              label: 'Announcements'),
          NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'Logs'),
        ],
      ),
    );
  }
}

class _AddUserDialog extends StatefulWidget {
  final String role;
  final VoidCallback onCreated;

  const _AddUserDialog({required this.role, required this.onCreated});

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
          'Add ${widget.role[0].toUpperCase()}${widget.role.substring(1)}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Full Name'),
            enabled: !_submitting,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailCtrl,
            decoration: const InputDecoration(labelText: 'Email'),
            enabled: !_submitting,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _passCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
            enabled: !_submitting,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitting
              ? null
              : () async {
                  final name = _nameCtrl.text.trim();
                  final email = _emailCtrl.text.trim();
                  final pass = _passCtrl.text;

                  if (name.isEmpty || email.isEmpty || pass.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill all fields')),
                    );
                    return;
                  }

                  setState(() => _submitting = true);
                  try {
                    await ApiService.createUser({
                      'name': name,
                      'email': email,
                      'password': pass,
                      'role': widget.role,
                    });
                    if (!mounted) return;
                    Navigator.pop(context);
                    widget.onCreated();
                  } catch (e) {
                    if (!mounted) return;
                    setState(() => _submitting = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to create user: $e')),
                    );
                  }
                },
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}

class _AdminDashboard extends StatelessWidget {
  final Map<String, List<dynamic>> users;
  final List<dynamic> children;
  final VoidCallback onAddUser;
  final VoidCallback onBackup;
  final VoidCallback onFullReport;
  const _AdminDashboard(
      {required this.users,
      required this.children,
      required this.onAddUser,
      required this.onBackup,
      required this.onFullReport});

  @override
  Widget build(BuildContext context) {
    final totalUsers = users.values.fold(0, (s, l) => s + (l.length));
    final parentCount = users['parent']?.length ?? 0;
    final psychCount = users['psychologist']?.length ?? 0;
    final educatorCount = users['educator']?.length ?? 0;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF6C3483), Color(0xFF9B59B6)]),
              borderRadius: BorderRadius.circular(20)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('System Overview',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _AdminStat(label: 'Total Users', value: '$totalUsers'),
              _AdminStat(label: 'Children', value: '${children.length}'),
              _AdminStat(label: 'Psychologists', value: '$psychCount'),
              _AdminStat(label: 'Educators', value: '$educatorCount'),
            ]),
          ]),
        ),
        const SizedBox(height: 20),
        const SectionTitle('User Distribution'),
        Card(
            child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
              height: 200,
              child: PieChart(PieChartData(sections: [
                PieChartSectionData(
                    value: parentCount.toDouble(),
                    title: 'Parents\n$parentCount',
                    color: AppTheme.primary,
                    radius: 80),
                PieChartSectionData(
                    value: psychCount.toDouble(),
                    title: 'Psychs\n$psychCount',
                    color: AppTheme.accent,
                    radius: 80),
                PieChartSectionData(
                    value: educatorCount.toDouble(),
                    title: 'Educators\n$educatorCount',
                    color: AppTheme.warning,
                    radius: 80),
              ], sectionsSpace: 4, centerSpaceRadius: 20))),
        )),
        const SizedBox(height: 16),
        const SectionTitle('Quick Actions'),
        Row(children: [
          Expanded(
              child: _ActionCard(
                  icon: Icons.person_add,
                  label: 'Add User',
                  color: AppTheme.primary,
                  onTap: onAddUser)),
          const SizedBox(width: 12),
          Expanded(
              child: _ActionCard(
                  icon: Icons.backup,
                  label: 'Backup Data',
                  color: AppTheme.accent,
                  onTap: onBackup)),
          const SizedBox(width: 12),
          Expanded(
              child: _ActionCard(
                  icon: Icons.analytics,
                  label: 'Full Report',
                  color: AppTheme.secondary,
                  onTap: onFullReport)),
        ]),
      ],
    );
  }
}

class _AdminStat extends StatelessWidget {
  final String label, value;
  const _AdminStat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ]);
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Card(
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(height: 8),
                  Text(label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ]))),
      );
}

class _UserManagementTab extends StatelessWidget {
  final Map<String, List<dynamic>> users;
  final VoidCallback onRefresh;
  const _UserManagementTab({required this.users, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(children: [
        const TabBar(tabs: [
          Tab(text: 'Parents'),
          Tab(text: 'Psychologists'),
          Tab(text: 'Educators')
        ], labelColor: Color(0xFF6C3483), indicatorColor: Color(0xFF6C3483)),
        Expanded(
            child: TabBarView(
                children: ['parent', 'psychologist', 'educator'].map((role) {
          final roleUsers = users[role] ?? [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${roleUsers.length} ${role}s',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C3483),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6)),
                    onPressed: () => _showAddUserDialog(context, role))
              ]),
              const SizedBox(height: 8),
              if (roleUsers.isEmpty)
                const EmptyState(
                    icon: Icons.person_outline,
                    message: 'No parents registered'),
              ...roleUsers.map((u) => _UserCard(
                  user: u,
                  onDelete: () async {
                    try {
                      await ApiService.deleteUser(u['id']);
                      onRefresh();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Delete failed: $e')),
                        );
                      }
                    }
                  })),
            ],
          );
        }).toList())),
      ]),
    );
  }

  void _showAddUserDialog(BuildContext context, String role) {
    showDialog(
      context: context,
      builder: (_) => _AddUserDialog(role: role, onCreated: onRefresh),
    );
  }
}

class _UserCard extends StatelessWidget {
  final dynamic user;
  final VoidCallback onDelete;
  const _UserCard({required this.user, required this.onDelete});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
            backgroundColor: const Color(0xFF6C3483).withValues(alpha: 0.1),
            child: Text((user['name'] ?? 'U')[0],
                style: const TextStyle(
                    color: Color(0xFF6C3483), fontWeight: FontWeight.bold))),
        title: Text(user['name'] ?? ''),
        subtitle: Text(user['email'] ?? ''),
        trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
            onPressed: () => showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                      title: const Text('Delete User'),
                      content: Text('Remove ${user['name']}?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel')),
                        ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              onDelete();
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.danger),
                            child: const Text('Delete')),
                      ]),
                )),
      ),
    );
  }
}

class _SystemLogTab extends StatefulWidget {
  @override
  State<_SystemLogTab> createState() => _SystemLogTabState();
}

class _SystemLogTabState extends State<_SystemLogTab> {
  List<dynamic> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final data = await ApiService.getSystemLogs() ?? [];
    if (mounted) {
      setState(() {
        _logs = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_logs.isEmpty) {
      return const EmptyState(
          icon: Icons.history, message: 'No system logs yet.');
    }
    return RefreshIndicator(
      onRefresh: _loadLogs,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionTitle('System Activity Logs'),
          ..._logs.map((log) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                      backgroundColor: Color(0xFFF5EEF8),
                      child: Icon(Icons.history, color: Color(0xFF6C3483))),
                  title: Text(log['event'] ?? ''),
                  subtitle: Text('By: ${log['user_name'] ?? 'System'}'),
                  trailing: Text(
                      log['timestamp']?.toString().substring(0, 16) ?? '',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11)),
                ),
              )),
        ],
      ),
    );
  }
}

class _AnnouncementsTab extends StatefulWidget {
  const _AnnouncementsTab();

  @override
  State<_AnnouncementsTab> createState() => _AnnouncementsTabState();
}

class _AnnouncementsTabState extends State<_AnnouncementsTab> {
  final _titleCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  String _category = 'Announcement';
  bool _submitting = false;
  List<dynamic> _announcements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAnnouncements() async {
    try {
      final notifs = await ApiService.getNotifications();
      final filtered =
          notifs.where((n) => n['type'] == 'announcement').toList();
      if (mounted) {
        setState(() {
          _announcements = filtered;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _broadcastAnnouncement() async {
    final title = _titleCtrl.text.trim();
    final message = _msgCtrl.text.trim();

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill in all announcement fields.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final fullTitle = '[$_category] $title';

      final success = await ApiService.sendNotification(
        recipientId: 'all',
        title: fullTitle,
        message: message,
        type: 'announcement',
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('📢 Announcement successfully broadcast to all users!'),
            backgroundColor: Colors.teal,
          ),
        );
        _titleCtrl.clear();
        _msgCtrl.clear();
        setState(() => _category = 'Announcement');
        _loadAnnouncements();
      } else {
        throw Exception('Broadcast failed on the server.');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to broadcast: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadAnnouncements,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 3,
            shadowColor: Colors.teal.withValues(alpha: 0.1),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.campaign,
                            color: Colors.teal, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Broadcast New Announcement',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: const InputDecoration(
                      labelText: 'Announcement Category',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'Announcement',
                          child: Text('📢 General Announcement')),
                      DropdownMenuItem(
                          value: 'Event',
                          child: Text('📅 Special Event / Webinar')),
                      DropdownMenuItem(
                          value: 'Clinical News',
                          child: Text('🧠 Clinical / Medical News')),
                    ],
                    onChanged: _submitting
                        ? null
                        : (val) {
                            if (val != null) {
                              setState(() => _category = val);
                            }
                          },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Announcement Title',
                      placeholder:
                          'e.g. Weekly Activity Schedule / System Upgrade',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !_submitting,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _msgCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Announcement Message',
                      placeholder:
                          'Write the details of the announcement here for all parents, psychologists, and educators...',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    enabled: !_submitting,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      icon: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.campaign),
                      label: Text(
                        _submitting
                            ? 'Broadcasting...'
                            : 'Broadcast Announcement',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      onPressed: _submitting ? null : _broadcastAnnouncement,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          const SectionTitle('Broadcast History'),
          const SizedBox(height: 12),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_announcements.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: EmptyState(
                icon: Icons.campaign_outlined,
                message: 'No announcements broadcast yet.',
              ),
            )
          else
            ..._announcements.map((ann) {
              final title = ann['title'] ?? 'Announcement';
              final message = ann['message'] ?? '';
              final dateStr = ann['created_at'] != null
                  ? DateTime.parse(ann['created_at'].toString())
                      .toLocal()
                      .toString()
                      .substring(0, 16)
                  : '';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: Border.all(
                      color: Colors.teal.withValues(alpha: 0.15), width: 1),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.withValues(alpha: 0.1),
                    child: const Icon(Icons.campaign, color: Colors.teal),
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        message,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dateStr,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
