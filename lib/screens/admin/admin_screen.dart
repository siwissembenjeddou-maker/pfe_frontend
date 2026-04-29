// lib/screens/admin/admin_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../main.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _currentIndex = 0;
  Map<String, List<dynamic>> _users = {'parent': [], 'psychologist': [], 'educator': []};
  List<dynamic> _children = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final parents = await ApiService.getAllUsers(role: 'parent');
    final psychs = await ApiService.getAllUsers(role: 'psychologist');
    final educators = await ApiService.getAllUsers(role: 'educator');
    final children = await ApiService.getChildren();
    if (mounted) {
      setState(() {
        _users = {'parent': parents, 'psychologist': psychs, 'educator': educators};
        _children = children;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final pages = [
      _AdminDashboard(users: _users, children: _children),
      _UserManagementTab(users: _users, onRefresh: _loadData),
      _SystemLogTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(children: [
          const Text('AutiSense Admin', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(user?.name ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ]),
        backgroundColor: const Color(0xFFF5EEF8),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          IconButton(icon: const Icon(Icons.logout), onPressed: () async {
            await context.read<AuthService>().logout();
            if (mounted) Navigator.pushReplacementNamed(context, '/login');
          }),
        ],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        indicatorColor: const Color(0xFF6C3483).withOpacity(0.2),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.manage_accounts_outlined), selectedIcon: Icon(Icons.manage_accounts), label: 'Users'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'Logs'),
        ],
      ),
    );
  }
}

class _AdminDashboard extends StatelessWidget {
  final Map<String, List<dynamic>> users;
  final List<dynamic> children;
  const _AdminDashboard({required this.users, required this.children});

  @override
  Widget build(BuildContext context) {
    final totalUsers = users.values.fold(0, (s, l) => s + l.length);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6C3483), Color(0xFF9B59B6)]), borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('System Overview', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _AdminStat(label: 'Total Users', value: '$totalUsers'),
              _AdminStat(label: 'Children', value: '${children.length}'),
              _AdminStat(label: 'Psychologists', value: '${users['psychologist']?.length ?? 0}'),
              _AdminStat(label: 'Educators', value: '${users['educator']?.length ?? 0}'),
            ]),
          ]),
        ),
        const SizedBox(height: 20),
        const SectionTitle('User Distribution'),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: SizedBox(
          height: 200,
          child: PieChart(PieChartData(sections: [
            PieChartSectionData(value: users['parent']!.length.toDouble(), title: 'Parents\n${users['parent']!.length}', color: AppTheme.primary, radius: 80),
            PieChartSectionData(value: users['psychologist']!.length.toDouble(), title: 'Psychs\n${users['psychologist']!.length}', color: AppTheme.accent, radius: 80),
            PieChartSectionData(value: users['educator']!.length.toDouble(), title: 'Educators\n${users['educator']!.length}', color: AppTheme.warning, radius: 80),
          ], sectionsSpace: 4, centerSpaceRadius: 20))),
        ))),
        const SizedBox(height: 16),
        const SectionTitle('Quick Actions'),
        Row(children: [
          Expanded(child: _ActionCard(icon: Icons.person_add, label: 'Add User', color: AppTheme.primary, onTap: () {})),
          const SizedBox(width: 12),
          Expanded(child: _ActionCard(icon: Icons.backup, label: 'Backup Data', color: AppTheme.accent, onTap: () {})),
          const SizedBox(width: 12),
          Expanded(child: _ActionCard(icon: Icons.analytics, label: 'Full Report', color: AppTheme.secondary, onTap: () {})),
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
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
    Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
  ]);
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(12),
    child: Card(child: Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Column(children: [
      Icon(icon, color: color, size: 28), const SizedBox(height: 8),
      Text(label, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
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
        const TabBar(tabs: [Tab(text: 'Parents'), Tab(text: 'Psychologists'), Tab(text: 'Educators')], labelColor: Color(0xFF6C3483), indicatorColor: Color(0xFF6C3483)),
        Expanded(child: TabBarView(children: ['parent', 'psychologist', 'educator'].map((role) {
          final roleUsers = users[role] ?? [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${roleUsers.length} ${role}s', style: const TextStyle(fontWeight: FontWeight.bold)),
                ElevatedButton.icon(icon: const Icon(Icons.add, size: 16), label: const Text('Add'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C3483), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)), onPressed: () => _showAddUserDialog(context, role)),
              ]),
              const SizedBox(height: 8),
              if (roleUsers.isEmpty) EmptyState(icon: Icons.person_outline, message: 'No ${role}s registered'),
              ...roleUsers.map((u) => _UserCard(user: u, onDelete: () async {
                await ApiService.deleteUser(u['id']);
                onRefresh();
              })),
            ],
          );
        }).toList())),
      ]),
    );
  }

  void _showAddUserDialog(BuildContext context, String role) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add ${role[0].toUpperCase()}${role.substring(1)}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
          const SizedBox(height: 8),
          TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 8),
          TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ApiService.createUser({'name': nameCtrl.text, 'email': emailCtrl.text, 'password': passCtrl.text, 'role': role});
              if (context.mounted) { Navigator.pop(context); onRefresh(); }
            },
            child: const Text('Create'),
          ),
        ],
      ),
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
        leading: CircleAvatar(backgroundColor: const Color(0xFF6C3483).withOpacity(0.1), child: Text((user['name'] ?? 'U')[0], style: const TextStyle(color: Color(0xFF6C3483), fontWeight: FontWeight.bold))),
        title: Text(user['name'] ?? ''),
        subtitle: Text(user['email'] ?? ''),
        trailing: IconButton(icon: const Icon(Icons.delete_outline, color: AppTheme.danger), onPressed: () => showDialog(
          context: context,
          builder: (_) => AlertDialog(title: const Text('Delete User'), content: Text('Remove ${user['name']}?'), actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(onPressed: () { Navigator.pop(context); onDelete(); }, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger), child: const Text('Delete')),
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
    final data = await ApiService.getSystemLogs();
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
      return const EmptyState(icon: Icons.history, message: 'No system logs yet.');
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
              leading: const CircleAvatar(backgroundColor: Color(0xFFF5EEF8), child: Icon(Icons.history, color: Color(0xFF6C3483))),
              title: Text(log['event'] ?? ''),
              subtitle: Text('By: ${log['user_name'] ?? 'System'}'),
              trailing: Text(log['timestamp']?.toString().substring(0, 16) ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ),
          )),
        ],
      ),
    );
  }
}
