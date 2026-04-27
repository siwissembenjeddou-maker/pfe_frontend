// lib/screens/psychologist/psychologist_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../main.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/common_widgets.dart';
import 'dart:convert';

class PsychologistScreen extends StatefulWidget {
  const PsychologistScreen({super.key});
  @override
  State<PsychologistScreen> createState() => _PsychologistScreenState();
}

class _PsychologistScreenState extends State<PsychologistScreen> {
  int _currentIndex = 0;
  List<Assessment> _pending = [];
  List<Assessment> _reviewed = [];
  List<Child> _allChildren = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final pendingData = await ApiService.getAssessments(status: 'pending');
    final reviewedData = await ApiService.getAssessments(status: 'confirmed');
    final childrenData = await ApiService.getChildren();
    if (mounted) {
      setState(() {
        _pending = pendingData.map((a) => Assessment.fromJson(a)).toList();
        _reviewed = reviewedData.map((a) => Assessment.fromJson(a)).toList();
        _allChildren = childrenData.map((c) => Child.fromJson(c)).toList();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final pages = [
      _PsychDashboard(
          pending: _pending, reviewed: _reviewed, children: _allChildren),
      _ReviewTab(pending: _pending, onRefresh: _loadData),
      _ChildrenOverviewTab(children: _allChildren),
      _MessagesTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('AutiSense', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Dr. ${user?.name ?? ''}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
        backgroundColor: const Color(0xFFF0FFF4),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData),
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
        indicatorColor: const Color(0xFF27AE60).withOpacity(0.2),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Overview'),
          NavigationDestination(icon: Icon(Icons.pending_actions_outlined), selectedIcon: Icon(Icons.pending_actions), label: 'Review'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Children'),
          NavigationDestination(icon: Icon(Icons.chat_outlined), selectedIcon: Icon(Icons.chat), label: 'Messages'),
        ],
      ),
    );
  }
}

// ──────────── PSYCH DASHBOARD ────────────
class _PsychDashboard extends StatelessWidget {
  final List<Assessment> pending;
  final List<Assessment> reviewed;
  final List<Child> children;
  const _PsychDashboard(
      {required this.pending, required this.reviewed, required this.children});

  @override
  Widget build(BuildContext context) {
    final avgScore = reviewed.isEmpty
        ? 0.0
        : reviewed.map((a) => a.autismScore).reduce((a, b) => a + b) /
        reviewed.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stats Row
        Row(children: [
          Expanded(
              child: _StatCard(
                  label: 'Pending Review',
                  value: '${pending.length}',
                  icon: Icons.pending_actions,
                  color: AppTheme.warning)),
          const SizedBox(width: 12),
          Expanded(
              child: _StatCard(
                  label: 'Reviewed',
                  value: '${reviewed.length}',
                  icon: Icons.check_circle,
                  color: AppTheme.accent)),
          const SizedBox(width: 12),
          Expanded(
              child: _StatCard(
                  label: 'Avg Score',
                  value: avgScore.toStringAsFixed(1),
                  icon: Icons.analytics,
                  color: AppTheme.primary)),
        ]),
        const SizedBox(height: 20),

        // Chart
        if (reviewed.isNotEmpty) ...[
          const SectionTitle('Score Distribution'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    barGroups: _buildBarGroups(),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, meta) {
                            final labels = ['0-2', '2-4', '4-6', '6-8', '8-10'];
                            if (val.toInt() < labels.length) {
                              return Text(labels[val.toInt()],
                                  style: const TextStyle(fontSize: 10));
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: true),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Recent Pending
        const SectionTitle('Needs Your Review'),
        if (pending.isEmpty)
          const EmptyState(icon: Icons.check_circle, message: 'All caught up! No pending reviews.'),
        ...pending.take(3).map((a) => _PendingCard(assessment: a, isCompact: true)),
      ],
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    final bins = [0, 0, 0, 0, 0];
    for (final a in reviewed) {
      final idx = (a.autismScore / 2).floor().clamp(0, 4);
      bins[idx]++;
    }
    return List.generate(
        5,
            (i) => BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: bins[i].toDouble(),
              color: [
                AppTheme.accent,
                const Color(0xFF7DCEA0),
                AppTheme.warning,
                const Color(0xFFE59866),
                AppTheme.danger,
              ][i],
              width: 20,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            )
          ],
        ));
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
        required this.value,
        required this.icon,
        required this.color});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
    ),
  );
}

// ──────────── REVIEW TAB ────────────
class _ReviewTab extends StatelessWidget {
  final List<Assessment> pending;
  final VoidCallback onRefresh;
  const _ReviewTab({required this.pending, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionTitle('Pending Reviews'),
          if (pending.isEmpty)
            const EmptyState(
                icon: Icons.check_circle_outline,
                message: 'All assessments reviewed!'),
          ...pending.map((a) => _PendingCard(
              assessment: a, isCompact: false, onReviewed: onRefresh)),
        ],
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final Assessment assessment;
  final bool isCompact;
  final VoidCallback? onReviewed;
  const _PendingCard(
      {required this.assessment, required this.isCompact, this.onReviewed});

  void _showReviewDialog(BuildContext context) {
    final noteCtrl = TextEditingController();
    final scoreCtrl =
    TextEditingController(text: assessment.autismScore.toString());
    String action = 'confirmed';

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
              const Text('Review Assessment',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Activity: ${assessment.activityType}',
                  style: const TextStyle(color: AppTheme.textSecondary)),
              const Divider(height: 24),

              // AI Transcription
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📝 Transcription',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(assessment.audioTranscription,
                        style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // AI Analysis
              if (assessment.aiAnalysis != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppTheme.primary.withOpacity(0.2))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🤖 AI Analysis',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary)),
                      const SizedBox(height: 4),
                      Text(assessment.aiAnalysis!,
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // Score display
              Row(children: [
                const Text('AI Score: ',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ScoreBadge(score: assessment.autismScore),
                const SizedBox(width: 6),
                SeverityBadge(severity: assessment.severityLevel),
              ]),
              const SizedBox(height: 16),

              // Action
              Row(
                children: [
                  const Text('Action: ',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('✅ Confirm'),
                    selected: action == 'confirmed',
                    onSelected: (_) => setS(() => action = 'confirmed'),
                    selectedColor: AppTheme.accent.withOpacity(0.2),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('✏️ Correct'),
                    selected: action == 'corrected',
                    onSelected: (_) => setS(() => action = 'corrected'),
                    selectedColor: AppTheme.warning.withOpacity(0.2),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (action == 'corrected')
                TextField(
                  controller: scoreCtrl,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Corrected Score (0-10)',
                    prefixIcon: Icon(Icons.edit),
                  ),
                ),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Clinical Notes (optional)',
                  prefixIcon: Icon(Icons.note_outlined),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: Text(action == 'confirmed'
                      ? 'Confirm & Notify Parent'
                      : 'Submit Correction'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: action == 'confirmed'
                        ? AppTheme.accent
                        : AppTheme.warning,
                  ),
                  onPressed: () async {
                    await ApiService.reviewAssessment(
                      assessment.id,
                      status: action,
                      note: noteCtrl.text.isNotEmpty ? noteCtrl.text : null,
                      correctedScore: action == 'corrected'
                          ? double.tryParse(scoreCtrl.text)
                          : null,
                    );
                    // Send notification to parent
                    await ApiService.sendNotification(
                      recipientId: assessment.childId,
                      title: 'Assessment Reviewed',
                      message:
                      'Dr. has $action the assessment for ${assessment.activityType}',
                      type: 'assessment_result',
                    );
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      onReviewed?.call();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showReviewDialog(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                        '${activityIcons[assessment.activityType] ?? ''} ${assessment.activityType}',
                        style: const TextStyle(
                            color: AppTheme.warning,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                  const Spacer(),
                  Text(
                      DateFormat('MMM dd, HH:mm').format(assessment.createdAt),
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 8),
              if (!isCompact)
                Text(
                  assessment.audioTranscription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ScoreBadge(score: assessment.autismScore),
                  const SizedBox(width: 8),
                  SeverityBadge(severity: assessment.severityLevel),
                  const Spacer(),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.rate_review, size: 14),
                    label: const Text('Review', style: TextStyle(fontSize: 12)),
                    onPressed: () => _showReviewDialog(context),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF27AE60),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────── CHILDREN OVERVIEW ────────────
class _ChildrenOverviewTab extends StatelessWidget {
  final List<Child> children;
  const _ChildrenOverviewTab({required this.children});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionTitle('All Children'),
        if (children.isEmpty)
          const EmptyState(icon: Icons.child_care, message: 'No children registered yet'),
        ...children.map((c) => ChildCard(child: c)),
      ],
    );
  }
}

// ──────────── MESSAGES TAB ────────────
class _MessagesTab extends StatefulWidget {
  @override
  State<_MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<_MessagesTab> {
  // Use a Future to hold the API call result
  late Future<List<dynamic>> _conversationsFuture;

  @override
  void initState() {
    super.initState();
    // Initialize the API call when the tab opens
    _conversationsFuture = ApiService.getConversations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<dynamic>>(
        future: _conversationsFuture,
        builder: (context, snapshot) {
          // 1. Show a loading spinner while waiting for the Backend
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Show an error message if the Backend is down or the token expired
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 40),
                  const SizedBox(height: 10),
                  Text('Connection Error: ${snapshot.error}'),
                  TextButton(
                    onPressed: () => setState(() {
                      _conversationsFuture = ApiService.getConversations();
                    }),
                    child: const Text('Try Again'),
                  )
                ],
              ),
            );
          }

          // 3. Check if we actually got data
          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return const EmptyState(
              icon: Icons.chat_bubble_outline,
              message: 'No conversations yet.\nContact parents directly after reviewing assessments.',
            );
          }

          // 4. Show the real list of conversations from the database
          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (_, i) {
              final conversation = conversations[i];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                // Matches the JSON keys from your Backend
                title: Text(conversation['other_user_name'] ?? 'User'),
                subtitle: Text(
                  conversation['last_message'] ?? 'Click to start chatting',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Navigate to the Chat Detail screen
                },
              );
            },
          );
        },
      ),
    );
  }
}