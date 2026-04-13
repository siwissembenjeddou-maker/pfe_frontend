// lib/screens/parent/parent_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import '../../main.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/common_widgets.dart';
import '../../models/models.dart';
import 'solutions_screen.dart'; //

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

  // ── NEW: tracks which child the parent is viewing solutions for ──
  Child? _selectedChildForSolutions;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user        = context.read<AuthService>().currentUser;
    final childrenData = await ApiService.getChildren(parentId: user?.id);
    final notifData   = await ApiService.getNotifications();
    if (mounted) {
      setState(() {
        _children = childrenData.map((c) => Child.fromJson(c)).toList();
        _notifications = notifData;
        _loading = false;

        // Auto-select the first child that has assessments for Solutions tab
        _selectedChildForSolutions = _children.firstWhere(
              (c) => c.assessments.isNotEmpty,
          orElse: () => _children.isNotEmpty ? _children.first : _selectedChildForSolutions!,
        );
      });
    }
  }

  // ── Called from DashboardTab when parent taps "View Solutions" on a child ──
  void _openSolutionsForChild(Child child) {
    setState(() {
      _selectedChildForSolutions = child;
      _currentIndex = 3; // Solutions tab index
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;

    final pages = [
      // 0 — Home
      _DashboardTab(
        children: _children,
        onRefresh: _loadData,
        onViewSolutions: _openSolutionsForChild, // ← NEW callback
      ),
      // 1 — Assess
      _AssessmentTab(children: _children),
      // 2 — Results
      _ResultsTab(children: _children),
      // 3 — Solutions (NEW)
      _SolutionsWrapper(
        children: _children,
        selectedChild: _selectedChildForSolutions,
        onChildChanged: (child) => setState(() => _selectedChildForSolutions = child),
      ),
      // 4 — Alerts
      _NotificationsTab(notifications: _notifications, onRefresh: _loadData),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(children: [
          const Text('AutiSense', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('Parent: ${user?.name ?? ''}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ]),
        actions: [
          // Notification bell with unread dot
          Stack(children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => setState(() => _currentIndex = 4),
            ),
            if (_notifications.any((n) => n['is_read'] == false))
              Positioned(
                right: 8, top: 8,
                child: Container(
                  width: 10, height: 10,
                  decoration: const BoxDecoration(
                      color: AppTheme.danger, shape: BoxShape.circle),
                ),
              ),
          ]),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthService>().logout();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
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
        indicatorColor: AppTheme.primary.withOpacity(0.15),
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
          // ── NEW TAB ──
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

  void _showAddChildDialog() {
    final nameCtrl = TextEditingController();
    final dobCtrl  = TextEditingController();
    String gender  = 'male';
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Child Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Child's Name"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dobCtrl,
                decoration: const InputDecoration(
                    labelText: 'Date of Birth',
                    suffixIcon: Icon(Icons.calendar_today)),
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
                readOnly: true,
              ),
              const SizedBox(height: 12),
              Row(children: [
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
              ]),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = context.read<AuthService>().currentUser;
                await ApiService.addChild({
                  'name': nameCtrl.text,
                  'date_of_birth': dobCtrl.text,
                  'gender': gender,
                  'parent_id': user?.id,
                });
                if (mounted) {
                  Navigator.pop(ctx);
                  _loadData();
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SOLUTIONS WRAPPER  (NEW)
// Lets the parent pick which child to view solutions for.
// ─────────────────────────────────────────────────────────────
class _SolutionsWrapper extends StatelessWidget {
  final List<Child> children;
  final Child? selectedChild;
  final ValueChanged<Child> onChildChanged;

  const _SolutionsWrapper({
    required this.children,
    required this.selectedChild,
    required this.onChildChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const EmptyState(
        icon: Icons.child_care,
        message: 'No children added yet.\nTap + on the Home tab to add your child.',
      );
    }

    return Column(
      children: [
        // ── Child picker bar ─────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            const Icon(Icons.child_care, color: AppTheme.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Child>(
                  value: selectedChild,
                  isExpanded: true,
                  hint: const Text('Select a child'),
                  items: children.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(
                      '${c.name}  (${c.age} yrs)',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary),
                    ),
                  )).toList(),
                  onChanged: (c) { if (c != null) onChildChanged(c); },
                ),
              ),
            ),
          ]),
        ),
        const Divider(height: 1),

        // ── Solutions content ─────────────────────────────────
        Expanded(
          child: selectedChild == null
              ? const EmptyState(
            icon: Icons.lightbulb_outline,
            message: 'Select a child above to view personalised solutions.',
          )
              : SolutionsTab(child: selectedChild!),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DASHBOARD TAB  (updated — added "View Solutions" button)
// ─────────────────────────────────────────────────────────────
class _DashboardTab extends StatelessWidget {
  final List<Child> children;
  final VoidCallback onRefresh;
  final ValueChanged<Child> onViewSolutions; // ← NEW

  const _DashboardTab({
    required this.children,
    required this.onRefresh,
    required this.onViewSolutions,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Welcome card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${children.length} child profile(s) registered',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.family_restroom, color: Colors.white, size: 50),
            ]),
          ),
          const SizedBox(height: 20),

          const SectionTitle('My Children'),
          if (children.isEmpty)
            const EmptyState(
              icon: Icons.child_care,
              message: 'No children added yet.\nTap + to add your child.',
            ),

          // ── Each child card + Solutions shortcut button ──
          ...children.map((child) => _ChildCardWithSolutions(
            child: child,
            onViewSolutions: () => onViewSolutions(child),
          )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CHILD CARD WITH SOLUTIONS BUTTON  (NEW)
// Wraps the existing ChildCard and adds a Solutions shortcut.
// ─────────────────────────────────────────────────────────────
class _ChildCardWithSolutions extends StatelessWidget {
  final Child child;
  final VoidCallback onViewSolutions;

  const _ChildCardWithSolutions({
    required this.child,
    required this.onViewSolutions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Existing ChildCard content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppTheme.primary.withOpacity(0.1),
                child: Text(
                  child.name[0],
                  style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(child.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      '${child.age} years • ${child.gender}',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    if (child.assessments.isNotEmpty)
                      Text(
                        '${child.assessments.length} assessment(s)',
                        style: const TextStyle(
                            color: AppTheme.primary, fontSize: 12),
                      ),
                  ],
                ),
              ),
              if (child.assessments.isNotEmpty)
                ScoreBadge(
                  score: child.assessments.last.correctedScore ??
                      child.assessments.last.autismScore,
                ),
            ]),
          ),

          // Solutions shortcut — only shown when assessments exist
          if (child.assessments.isNotEmpty) ...[
            const Divider(height: 1),
            InkWell(
              onTap: onViewSolutions,
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Row(children: [
                  const Icon(Icons.lightbulb,
                      color: AppTheme.accent, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'View Personalised Solutions',
                    style: TextStyle(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios,
                      size: 14, color: AppTheme.accent),
                ]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ASSESSMENT TAB  (unchanged from original)
// ─────────────────────────────────────────────────────────────
class _AssessmentTab extends StatefulWidget {
  final List<Child> children;
  const _AssessmentTab({required this.children});
  @override
  State<_AssessmentTab> createState() => _AssessmentTabState();
}

class _AssessmentTabState extends State<_AssessmentTab> {
  Child?   _selectedChild;
  String   _selectedActivity = activityTypes[0];
  bool     _isRecording  = false;
  bool     _isAnalyzing  = false;
  Map<String, dynamic>? _result;
  String   _transcription = '';
  final AudioRecorder _recorder = AudioRecorder();
  String?  _recordingPath;
  Duration _recordingDuration = Duration.zero;

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final micPerm = await Permission.microphone.request();
    if (!micPerm.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required')));
      return;
    }
    final dir = await getTemporaryDirectory();
    _recordingPath =
    '${dir.path}/assessment_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(), path: _recordingPath!);
    setState(() {
      _isRecording = true;
      _result = null;
      _recordingDuration = Duration.zero;
    });
    _tickTimer();
  }

  void _tickTimer() async {
    await Future.delayed(const Duration(seconds: 1));
    if (_isRecording && mounted) {
      setState(() => _recordingDuration += const Duration(seconds: 1));
      _tickTimer();
    }
  }

  Future<void> _stopAndAnalyze() async {
    await _recorder.stop();
    setState(() { _isRecording = false; _isAnalyzing = true; });
    try {
      final file   = File(_recordingPath!);
      final result = await ApiService.uploadAudio(
          file, _selectedChild!.id, _selectedActivity);
      setState(() {
        _result         = result;
        _transcription  = result['transcription'] ?? '';
        _isAnalyzing    = false;
      });
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('New Assessment'),

          // Child selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Child',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Child>(
                    value: _selectedChild,
                    hint: const Text('Choose your child'),
                    items: widget.children
                        .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text('${c.name} (${c.age} yrs)')))
                        .toList(),
                    onChanged: (c) => setState(() => _selectedChild = c),
                    decoration:
                    const InputDecoration(prefixIcon: Icon(Icons.child_care)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Activity selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Activity Type',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: activityTypes.map((a) {
                      final selected = _selectedActivity == a;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedActivity = a),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppTheme.primary.withOpacity(0.15)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? AppTheme.primary
                                  : Colors.grey.shade300,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            '${activityIcons[a] ?? ''} $a',
                            style: TextStyle(
                              color: selected
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Instructions banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline, color: AppTheme.accent),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Press Record and describe how your child performs the '
                      'selected activity. Be specific and detailed.',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // Recording button
          Center(
            child: Column(children: [
              if (_isRecording)
                Text(
                  '${_recordingDuration.inMinutes.toString().padLeft(2, '0')}:'
                      '${(_recordingDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.danger),
                ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _selectedChild == null
                    ? null
                    : _isRecording
                    ? _stopAndAnalyze
                    : _startRecording,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _selectedChild == null
                        ? Colors.grey.shade300
                        : _isRecording
                        ? AppTheme.danger
                        : AppTheme.primary,
                    boxShadow: [
                      BoxShadow(
                        color: (_isRecording
                            ? AppTheme.danger
                            : AppTheme.primary)
                            .withOpacity(0.4),
                        blurRadius: _isRecording ? 20 : 10,
                        spreadRadius: _isRecording ? 5 : 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _selectedChild == null
                    ? 'Select a child first'
                    : _isRecording
                    ? 'Tap to stop & analyze'
                    : 'Tap to start recording',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // Analyzing indicator
          if (_isAnalyzing)
            const Center(
              child: Column(children: [
                CircularProgressIndicator(),
                SizedBox(height: 8),
                Text('Transcribing & Analyzing with AI…',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ]),
            ),

          // Result card
          if (_result != null) AssessmentResultCard(result: _result!),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// RESULTS TAB  (unchanged from original)
// ─────────────────────────────────────────────────────────────
class _ResultsTab extends StatefulWidget {
  final List<Child> children;
  const _ResultsTab({required this.children});
  @override
  State<_ResultsTab> createState() => _ResultsTabState();
}

class _ResultsTabState extends State<_ResultsTab> {
  List<Assessment> _assessments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await ApiService.getAssessments();
    setState(() {
      _assessments = data.map((a) => Assessment.fromJson(a)).toList();
      _loading     = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionTitle('Assessment History'),
        if (_assessments.isEmpty)
          const EmptyState(
              icon: Icons.bar_chart,
              message: 'No assessments yet.\nRecord your first assessment.'),
        ..._assessments.map((a) => _AssessmentHistoryCard(assessment: a)),
      ],
    );
  }
}

class _AssessmentHistoryCard extends StatelessWidget {
  final Assessment assessment;
  const _AssessmentHistoryCard({required this.assessment});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${activityIcons[assessment.activityType] ?? ''} ${assessment.activityType}',
                  style: const TextStyle(
                      color: AppTheme.primary, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              StatusBadge(status: assessment.status),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _ScoreCircle(
                  score: assessment.autismScore,
                  severity: assessment.severityLevel),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Score: ${assessment.autismScore.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'Level: ${assessment.severityLevel.toUpperCase()}',
                      style: TextStyle(
                          color: assessment.severityColor,
                          fontWeight: FontWeight.w600),
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy').format(assessment.createdAt),
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ]),
            if (assessment.psychologistNote != null &&
                assessment.psychologistNote!.isNotEmpty) ...[
              const Divider(),
              Row(children: [
                const Icon(Icons.psychology,
                    size: 16, color: AppTheme.secondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(assessment.psychologistNote!,
                      style: const TextStyle(
                          color: AppTheme.secondary, fontSize: 13)),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScoreCircle extends StatelessWidget {
  final double score;
  final String severity;
  const _ScoreCircle({required this.score, required this.severity});

  Color get _color {
    if (score < 3) return AppTheme.accent;
    if (score < 6) return AppTheme.warning;
    return AppTheme.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64, height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _color, width: 3),
      ),
      child: Center(
        child: Text(
          score.toStringAsFixed(1),
          style: TextStyle(
              color: _color, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NOTIFICATIONS TAB  (unchanged from original)
// ─────────────────────────────────────────────────────────────
class _NotificationsTab extends StatelessWidget {
  final List<dynamic> notifications;
  final VoidCallback onRefresh;
  const _NotificationsTab(
      {required this.notifications, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionTitle('Notifications'),
          if (notifications.isEmpty)
            const EmptyState(
                icon: Icons.notifications_none,
                message: 'No notifications yet'),
          ...notifications.map((n) => _NotifCard(notif: n)),
        ],
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final dynamic notif;
  const _NotifCard({required this.notif});

  IconData get _icon {
    switch (notif['type']) {
      case 'assessment_result': return Icons.assessment;
      case 'review_complete':   return Icons.check_circle;
      case 'message':           return Icons.message;
      case 'reminder':          return Icons.alarm;
      default:                  return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRead = notif['is_read'] == true;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: isRead ? null : AppTheme.primary.withOpacity(0.05),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withOpacity(0.1),
          child: Icon(_icon, color: AppTheme.primary),
        ),
        title: Text(
          notif['title'] ?? '',
          style: TextStyle(
              fontWeight: isRead ? FontWeight.normal : FontWeight.bold),
        ),
        subtitle: Text(notif['message'] ?? ''),
        trailing: isRead
            ? null
            : Container(
          width: 10, height: 10,
          decoration: const BoxDecoration(
              color: AppTheme.primary, shape: BoxShape.circle),
        ),
        onTap: () => ApiService.markNotificationRead(notif['id']),
      ),
    );
  }
}