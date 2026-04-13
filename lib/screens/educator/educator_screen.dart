// lib/screens/educator/educator_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../main.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/common_widgets.dart';

class EducatorScreen extends StatefulWidget {
  const EducatorScreen({super.key});
  @override
  State<EducatorScreen> createState() => _EducatorScreenState();
}

class _EducatorScreenState extends State<EducatorScreen> {
  int _currentIndex = 0;
  List<Child> _children = [];
  List<dynamic> _schedules = [];
  bool _loading = true;
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final childrenData = await ApiService.getChildren();
    final scheduleData = await ApiService.getSchedules();
    if (mounted) {
      setState(() {
        _children = childrenData.map((c) => Child.fromJson(c)).toList();
        _schedules = scheduleData;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final pages = [
      _EducatorDashboard(children: _children, schedules: _schedules),
      _ScheduleTab(schedules: _schedules, onRefresh: _loadData, selectedDay: _selectedDay,
          onDaySelected: (d) => setState(() => _selectedDay = d)),
      _AttendanceTab(children: _children),
      _ReportsTab(children: _children),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('AutoSense', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Educator: ${user?.name ?? ''}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
        backgroundColor: const Color(0xFFFFF8F0),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await context.read<AuthService>().logout();
                if (mounted) Navigator.pushReplacementNamed(context, '/login');
              }),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        indicatorColor: AppTheme.warning.withOpacity(0.2),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Schedule'),
          NavigationDestination(icon: Icon(Icons.fact_check_outlined), selectedIcon: Icon(Icons.fact_check), label: 'Attendance'),
          NavigationDestination(icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description), label: 'Reports'),
        ],
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
        onPressed: _showAddScheduleDialog,
        backgroundColor: AppTheme.warning,
        child: const Icon(Icons.add),
      )
          : null,
    );
  }

  void _showAddScheduleDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedActivity = activityTypes[0];
    TimeOfDay selectedTime = TimeOfDay.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Activity',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                    labelText: 'Activity Title',
                    prefixIcon: Icon(Icons.title)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedActivity,
                decoration: const InputDecoration(labelText: 'Activity Type'),
                items: activityTypes
                    .map((a) =>
                    DropdownMenuItem(value: a, child: Text('${activityIcons[a]} $a')))
                    .toList(),
                onChanged: (v) => setS(() => selectedActivity = v!),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: Text('Time: ${selectedTime.format(ctx)}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final t = await showTimePicker(context: ctx, initialTime: selectedTime);
                  if (t != null) setS(() => selectedTime = t);
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
                  onPressed: () async {
                    await ApiService.createSchedule({
                      'title': titleCtrl.text,
                      'description': descCtrl.text,
                      'activity_type': selectedActivity,
                      'date': DateFormat('yyyy-MM-dd').format(_selectedDay),
                      'time': selectedTime.format(ctx),
                    });
                    if (mounted) {
                      Navigator.pop(ctx);
                      _loadData();
                    }
                  },
                  child: const Text('Add Activity'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EducatorDashboard extends StatelessWidget {
  final List<Child> children;
  final List<dynamic> schedules;
  const _EducatorDashboard({required this.children, required this.schedules});

  @override
  Widget build(BuildContext context) {
    final today = schedules.where((s) {
      final date = DateTime.tryParse(s['date'] ?? '');
      return date != null && isSameDay(date, DateTime.now());
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Welcome
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFE67E22), Color(0xFFF39C12)]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Good ${_greeting()}! 👋',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    Text('${children.length} children · ${today.length} activities today',
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              const Icon(Icons.school, color: Colors.white, size: 50),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Quick Stats
        Row(children: [
          Expanded(
              child: _EduStatCard(
                  label: 'Students', value: '${children.length}', icon: Icons.people, color: AppTheme.primary)),
          const SizedBox(width: 12),
          Expanded(
              child: _EduStatCard(
                  label: "Today's Activities", value: '${today.length}', icon: Icons.today, color: AppTheme.warning)),
          const SizedBox(width: 12),
          Expanded(
              child: _EduStatCard(
                  label: 'This Week', value: '${schedules.length}', icon: Icons.calendar_view_week, color: AppTheme.accent)),
        ]),
        const SizedBox(height: 20),

        const SectionTitle("Today's Schedule"),
        if (today.isEmpty)
          const EmptyState(icon: Icons.calendar_today, message: 'No activities scheduled for today'),
        ...today.map((s) => _ScheduleCard(schedule: s)),

        const SizedBox(height: 12),
        const SectionTitle('Student Overview'),
        ...children.map((c) => ChildCard(child: c)),
      ],
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }
}

class _EduStatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _EduStatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
        ],
      ),
    ),
  );
}

class _ScheduleTab extends StatelessWidget {
  final List<dynamic> schedules;
  final VoidCallback onRefresh;
  final DateTime selectedDay;
  final Function(DateTime) onDaySelected;
  const _ScheduleTab(
      {required this.schedules, required this.onRefresh,
        required this.selectedDay, required this.onDaySelected});

  @override
  Widget build(BuildContext context) {
    final daySchedules = schedules.where((s) {
      final d = DateTime.tryParse(s['date'] ?? '');
      return d != null && isSameDay(d, selectedDay);
    }).toList();

    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime(2024),
          lastDay: DateTime(2027),
          focusedDay: selectedDay,
          selectedDayPredicate: (d) => isSameDay(d, selectedDay),
          onDaySelected: (selected, _) => onDaySelected(selected),
          calendarStyle: const CalendarStyle(
            selectedDecoration: BoxDecoration(
                color: AppTheme.warning, shape: BoxShape.circle),
            todayDecoration: BoxDecoration(
                color: AppTheme.primary, shape: BoxShape.circle),
          ),
          headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
        ),
        const Divider(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionTitle(
                  DateFormat('EEEE, MMM dd').format(selectedDay)),
              if (daySchedules.isEmpty)
                const EmptyState(icon: Icons.event_available, message: 'No activities for this day.\nTap + to add one.'),
              ...daySchedules.map((s) => _ScheduleCard(schedule: s)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final dynamic schedule;
  const _ScheduleCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.warning.withOpacity(0.1),
          child: Text(activityIcons[schedule['activity_type']] ?? '📋',
              style: const TextStyle(fontSize: 22)),
        ),
        title: Text(schedule['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(schedule['description'] ?? ''),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(schedule['time'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.warning)),
          ],
        ),
      ),
    );
  }
}

class _AttendanceTab extends StatefulWidget {
  final List<Child> children;
  const _AttendanceTab({required this.children});
  @override
  State<_AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<_AttendanceTab> {
  final Map<String, String> _attendance = {}; // childId → 'present'|'absent'|'late'

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
                child: SectionTitle('Today\'s Attendance')),
            ElevatedButton.icon(
              icon: const Icon(Icons.save, size: 16),
              label: const Text('Save'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warning,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Attendance saved!')));
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...widget.children.map((child) {
          final status = _attendance[child.id] ?? 'present';
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    child: Text(child.name[0],
                        style: const TextStyle(
                            color: AppTheme.primary, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(child.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('${child.age} years · ${child.gender}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                      )),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'present', icon: Icon(Icons.check, size: 14), label: Text('P', style: TextStyle(fontSize: 11))),
                      ButtonSegment(value: 'late', icon: Icon(Icons.schedule, size: 14), label: Text('L', style: TextStyle(fontSize: 11))),
                      ButtonSegment(value: 'absent', icon: Icon(Icons.close, size: 14), label: Text('A', style: TextStyle(fontSize: 11))),
                    ],
                    selected: {status},
                    onSelectionChanged: (s) =>
                        setState(() => _attendance[child.id] = s.first),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          if (status == 'present') return AppTheme.accent.withOpacity(0.2);
                          if (status == 'late') return AppTheme.warning.withOpacity(0.2);
                          return AppTheme.danger.withOpacity(0.2);
                        }
                        return null;
                      }),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}

class _ReportsTab extends StatelessWidget {
  final List<Child> children;
  const _ReportsTab({required this.children});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionTitle('Progress Reports'),
        ...children.map((c) => _ChildReportCard(child: c)),
      ],
    );
  }
}

class _ChildReportCard extends StatelessWidget {
  final Child child;
  const _ChildReportCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.warning.withOpacity(0.1),
                  radius: 22,
                  child: Text(child.name[0],
                      style: const TextStyle(
                          color: AppTheme.warning,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(child.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${child.age} years · ${child.assessments.length} assessments',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.warning,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: const Text('View Report', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            if (child.assessments.isNotEmpty) ...[
              const Divider(height: 20),
              Text('Latest: ${child.assessments.last.activityType}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              Row(
                children: [
                  ScoreBadge(score: child.assessments.last.autismScore),
                  const SizedBox(width: 8),
                  SeverityBadge(severity: child.assessments.last.severityLevel),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}