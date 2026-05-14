// ignore_for_file: use_build_context_synchronously

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/common_widgets.dart';
import '../parent/_notifications_tab.dart';

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

  List<dynamic> _notifications = [];
  bool _loading = true;
  String? _error;

  // Filters
  String? _selectedChildId; // null => All
  String? _selectedParentId; // null => All

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final allData = await ApiService.getAssessments();
      final allAssessments =
          allData.map((a) => Assessment.fromJson(a)).toList();

      List<dynamic> childrenData = [];
      try {
        childrenData = await ApiService.getChildren();
      } catch (_) {
        childrenData = [];
      }

      final notifData = await ApiService.getNotifications();

      if (!mounted) return;

      setState(() {
        _pending = allAssessments.where((a) => a.status == 'pending').toList();
        _reviewed = allAssessments.where((a) => a.status != 'pending').toList();
        _allChildren = childrenData.map((c) => Child.fromJson(c)).toList();
        _notifications = notifData;

        // Reset invalid selections after refresh
        if (_selectedChildId != null &&
            !_allChildren.any((c) => c.id == _selectedChildId)) {
          _selectedChildId = null;
        }
        if (_selectedParentId != null &&
            !_allChildren.any((c) => c.parentId == _selectedParentId)) {
          _selectedParentId = null;
        }

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<Child> _getDisplayChildren() {
    final Map<String, Child> byId = {};

    for (final c in _allChildren) {
      byId[c.id] = c;
    }

    for (final a in [..._pending, ..._reviewed]) {
      if (!byId.containsKey(a.childId)) {
        byId[a.childId] = Child(
          id: a.childId,
          name: a.childName ?? 'Child ${a.childId}',
          age: 0,
          gender: 'Unknown',
          parentId: a.parentId ?? '',
          parentName: a.parentName,
          dateOfBirth: DateTime.now(),
          profileImage: null,
          assessments: [a],
        );
      } else {
        final existing = byId[a.childId]!;
        final allAssessmentsForChild = [..._pending, ..._reviewed]
            .where((x) => x.childId == existing.id)
            .toList();

        if ((existing.parentName == null || existing.parentName!.isEmpty) &&
            a.parentName != null) {
          byId[a.childId] = Child(
            id: existing.id,
            name: existing.name,
            age: existing.age,
            gender: existing.gender,
            parentId: existing.parentId,
            parentName: a.parentName,
            dateOfBirth: existing.dateOfBirth,
            profileImage: existing.profileImage,
            assessments: allAssessmentsForChild,
          );
        } else if (existing.assessments.length !=
            allAssessmentsForChild.length) {
          byId[a.childId] = Child(
            id: existing.id,
            name: existing.name,
            age: existing.age,
            gender: existing.gender,
            parentId: existing.parentId,
            parentName: existing.parentName,
            dateOfBirth: existing.dateOfBirth,
            profileImage: existing.profileImage,
            assessments: allAssessmentsForChild,
          );
        }
      }
    }

    return byId.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  Map<String, String> _getUniqueParents() {
    final Map<String, String> parents = {};
    for (final a in [..._pending, ..._reviewed]) {
      final pid = a.parentId ?? '';
      if (pid.isNotEmpty) {
        parents[pid] = a.parentName ?? 'Parent $pid';
      }
    }
    return parents;
  }

  List<Assessment> _filterAssessments(List<Assessment> source) {
    final displayChildren = _getDisplayChildren();

    final Set<String>? allowedChildIds = _selectedChildId != null
        ? {_selectedChildId!}
        : (_selectedParentId != null
            ? displayChildren
                .where((c) => c.parentId == _selectedParentId)
                .map((c) => c.id)
                .toSet()
            : null);

    if (allowedChildIds == null) return source;
    return source.where((a) => allowedChildIds.contains(a.childId)).toList();
  }

  Widget _buildFilters() {
    final displayChildren = _getDisplayChildren();
    final parents = _getUniqueParents();
    final parentEntries = parents.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final childItems = displayChildren
        .where(
            (c) => _selectedParentId == null || c.parentId == _selectedParentId)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final hasChildren = displayChildren.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      color: const Color(0xFFF0FFF4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Parent & Child',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedParentId,
                  decoration: const InputDecoration(
                    labelText: 'Parent',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    if (_selectedParentId == null)
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Parents'),
                      ),
                    ...parentEntries.map(
                      (e) => DropdownMenuItem<String>(
                        value: e.key,
                        child: Text(e.value),
                      ),
                    ),
                  ].where((e) => true).toList(),
                  onChanged: (v) {
                    setState(() {
                      // DropdownButtonFormField does not support null values consistently in all channels,
                      // so treat empty selection as "All".
                      _selectedParentId = v;
                      if (_selectedChildId != null &&
                          !_allChildren.any((c) =>
                              c.id == _selectedChildId && c.parentId == v)) {
                        _selectedChildId = null;
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedChildId,
                  decoration: const InputDecoration(
                    labelText: 'Child',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    if (_selectedChildId == null)
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Children'),
                      ),
                    ...childItems.map(
                      (c) => DropdownMenuItem<String>(
                        value: c.id,
                        child:
                            Text(c.age > 0 ? '${c.name} (${c.age})' : c.name),
                      ),
                    ),
                  ],
                  onChanged: hasChildren
                      ? (v) {
                          setState(() {
                            _selectedChildId = v;
                            if (_selectedChildId != null) {
                              final child = displayChildren
                                  .firstWhere((c) => c.id == _selectedChildId);
                              _selectedParentId = child.parentId;
                            }
                          });
                        }
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final filteredPending = _filterAssessments(_pending);

    final pages = [
      _PsychDashboard(
        pending: filteredPending,
        allAssessments: [..._pending, ..._reviewed],
        onRefresh: _loadData,
      ),
      _ReviewTab(
        pending: filteredPending,
        allAssessments: [..._pending, ..._reviewed],
        onRefresh: _loadData,
      ),
      _ReportTab(
        allAssessments: [..._pending, ..._reviewed],
        displayChildren: _getDisplayChildren(),
        displayParents: _getUniqueParents(),
        selectedParentId: _selectedParentId,
        selectedChildId: _selectedChildId,
        onRefresh: _loadData,
      ),
      NotificationsTab(
        getNotifications: () => _notifications,
        onRefresh: _loadData,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'AutiSense',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              (user?.name != null &&
                      (user!.name!.startsWith('Dr.') ||
                          user.name!.startsWith('dr.')))
                  ? user.name!
                  : 'Dr. ${user?.name ?? ''}',
              style:
                  const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFF0FFF4),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthService>().logout();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
        bottom: _currentIndex == 3
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(92),
                child: _buildFilters(),
              ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        const Text(
                          'Failed to load psychologist data.',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: const TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        indicatorColor: const Color(0xFF27AE60).withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.pending_actions_outlined),
            selectedIcon: Icon(Icons.pending_actions),
            label: 'Review',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Report',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }
}

class _PsychDashboard extends StatelessWidget {
  final List<Assessment> pending;
  final List<Assessment> allAssessments;
  final VoidCallback onRefresh;

  const _PsychDashboard({
    required this.pending,
    required this.allAssessments,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final reviewed =
        allAssessments.where((a) => a.status != 'pending').toList();
    final scoreValues =
        reviewed.map((a) => a.correctedScore ?? a.autismScore).toList();
    final avgScore = scoreValues.isEmpty
        ? 0.0
        : scoreValues.reduce((b, a) => b + a) / scoreValues.length;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Pending Review',
                  value: '${pending.length}',
                  icon: Icons.pending_actions,
                  color: AppTheme.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Reviewed',
                  value: '${reviewed.length}',
                  icon: Icons.check_circle,
                  color: AppTheme.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Avg Score',
                  value: avgScore > 0 ? avgScore.toStringAsFixed(1) : '—',
                  icon: Icons.analytics,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (allAssessments.isNotEmpty) ...[
            const SectionTitle('Score Distribution'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                    height: 200, child: _buildScoreChart(allAssessments)),
              ),
            ),
            const SizedBox(height: 16),
          ],
          const SectionTitle('Needs Your Review'),
          if (pending.isEmpty)
            const EmptyState(
              icon: Icons.check_circle,
              message: 'All caught up! No pending reviews.',
            ),
          ...pending.map((a) => _PendingCard(
                assessment: a,
                isCompact: false,
                onReviewed: onRefresh,
                parentId: a.parentId,
              )),
          if (reviewed.isNotEmpty) ...[
            const SizedBox(height: 8),
            const SectionTitle('Recently Reviewed'),
            ...reviewed.take(5).map((a) => _ReviewedCard(
                  assessment: a,
                  onRefresh: onRefresh,
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreChart(List<Assessment> all) {
    final bins = [0, 0, 0, 0, 0];
    final labels = ['0-2', '2-4', '4-6', '6-8', '8-10'];
    final colors = [
      AppTheme.accent,
      const Color(0xFF7DCEA0),
      AppTheme.warning,
      const Color(0xFFE59866),
      AppTheme.danger,
    ];

    for (final a in all) {
      final score = a.correctedScore ?? a.autismScore;
      final idx = (score / 2).floor().clamp(0, 4);
      bins[idx]++;
    }

    return BarChart(
      BarChartData(
        barGroups: List.generate(
          5,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: bins[i].toDouble(),
                color: colors[i],
                width: 28,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                return Text(
                  idx < labels.length ? labels[idx] : '',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (val, meta) {
                if (val != val.roundToDouble()) return const SizedBox.shrink();
                return Text(
                  val.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${labels[group.x]}: ${rod.toY.toInt()} assessment(s)',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                    color: color, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
      );
}

class _ReviewTab extends StatelessWidget {
  final List<Assessment> pending;
  final List<Assessment> allAssessments;
  final VoidCallback onRefresh;

  const _ReviewTab({
    required this.pending,
    required this.allAssessments,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final reviewed =
        allAssessments.where((a) => a.status != 'pending').toList();

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionTitle('Pending Reviews'),
          if (pending.isEmpty)
            const EmptyState(
              icon: Icons.check_circle_outline,
              message: 'All assessments reviewed!',
            ),
          ...pending.map((a) => _PendingCard(
                assessment: a,
                isCompact: false,
                onReviewed: onRefresh,
                parentId: a.parentId,
              )),
          if (reviewed.isNotEmpty) ...[
            const SizedBox(height: 8),
            const SectionTitle('Recently Reviewed'),
            ...reviewed.take(10).map((a) => _ReviewedCard(
                  assessment: a,
                  onRefresh: onRefresh,
                )),
          ],
        ],
      ),
    );
  }
}

class _ReviewedCard extends StatefulWidget {
  final Assessment assessment;
  final VoidCallback onRefresh;

  const _ReviewedCard({required this.assessment, required this.onRefresh});

  @override
  State<_ReviewedCard> createState() => _ReviewedCardState();
}

class _ReviewedCardState extends State<_ReviewedCard> {
  void _showReviewDialog(BuildContext context) {
    final assessment = widget.assessment;

    final noteCtrl = TextEditingController();
    final scoreCtrl = TextEditingController(
      text: (assessment.correctedScore ?? assessment.autismScore).toString(),
    );

    String action =
        (assessment.status == 'corrected') ? 'corrected' : 'confirmed';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Review Assessment',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Activity: ${assessment.activityType}',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Text('AI Score: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ScoreBadge(
                    assessment.autismScore,
                    correctedScore: assessment.correctedScore,
                  ),
                  const SizedBox(width: 6),
                  SeverityBadge(assessment.severityLevel),
                ],
              ),
              const SizedBox(height: 16),
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
                  label: Text(
                    action == 'confirmed'
                        ? 'Review again (Confirm)'
                        : 'Review again (Correct)',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: action == 'confirmed'
                        ? AppTheme.accent
                        : AppTheme.warning,
                  ),
                  onPressed: () async {
                    double? correctedScoreValue;
                    if (action == 'corrected') {
                      final parsed = double.tryParse(scoreCtrl.text);
                      if (parsed == null || parsed < 0 || parsed > 10) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Score must be between 0 and 10'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      correctedScoreValue = parsed;
                    }

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          action == 'confirmed'
                              ? 'Updating confirmation...'
                              : 'Updating correction...',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );

                    try {
                      final result = await ApiService.reviewAssessment(
                        assessment.id,
                        status: action,
                        note: noteCtrl.text.isNotEmpty ? noteCtrl.text : null,
                        correctedScore: correctedScoreValue,
                      );

                      if (!context.mounted) return;

                      if (result['id'] != null) {
                        widget.onRefresh();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              action == 'confirmed'
                                  ? 'Review updated (Confirmed).'
                                  : 'Review updated (Corrected).',
                            ),
                            backgroundColor: AppTheme.accent,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Error: ${result['error'] ?? 'Unknown error'}'),
                            backgroundColor: AppTheme.danger,
                          ),
                        );
                      }
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: AppTheme.danger,
                        ),
                      );
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
    final assessment = widget.assessment;

    final score = assessment.correctedScore ?? assessment.autismScore;
    final statusLabel =
        assessment.status == 'corrected' ? 'Corrected' : 'Confirmed';
    final childName = assessment.childName ?? 'Child ${assessment.childId}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.accent.withOpacity(0.15),
                  child: const Icon(Icons.check_circle,
                      color: AppTheme.accent, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$childName — ${assessment.activityType}',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                IconButton(
                  tooltip: 'Review again',
                  icon: const Icon(Icons.rate_review_outlined, size: 18),
                  onPressed: () => _showReviewDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${assessment.severityLevel} • Score: ${double.tryParse(score.toString())?.toStringAsFixed(1) ?? score.toString()}/10',
              style: TextStyle(fontSize: 12, color: assessment.severityColor),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusLabel,
                style: const TextStyle(
                  color: AppTheme.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '📝 Transcription',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              assessment.audioTranscription,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            if (assessment.aiAnalysis != null &&
                assessment.aiAnalysis!.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                '🤖 AI Analysis',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary),
              ),
              const SizedBox(height: 4),
              Text(
                assessment.aiAnalysis!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final Assessment assessment;
  final bool isCompact;
  final VoidCallback? onReviewed;
  final String? parentId;

  const _PendingCard({
    required this.assessment,
    required this.isCompact,
    this.onReviewed,
    this.parentId,
  });

  String get _displayChildName =>
      assessment.childName ?? 'Child ${assessment.childId}';

  String get _displayParentName {
    return assessment.parentName ??
        (assessment.parentId?.isNotEmpty == true
            ? 'Parent ${assessment.parentId}'
            : 'Unknown Parent');
  }

  void _showReviewDialog(BuildContext context) {
    final noteCtrl = TextEditingController();
    final scoreCtrl =
        TextEditingController(text: assessment.autismScore.toString());
    String action = 'confirmed';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx2).viewInsets.bottom + 20,
          ),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
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
              if (assessment.aiAnalysis != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: AppTheme.primary.withOpacity(0.2)),
                  ),
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
              Row(
                children: [
                  const Text('AI Score: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ScoreBadge(assessment.autismScore,
                      correctedScore: assessment.correctedScore),
                  const SizedBox(width: 6),
                  SeverityBadge(assessment.severityLevel),
                ],
              ),
              const SizedBox(height: 16),
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
                    double? correctedScoreValue;
                    if (action == 'corrected') {
                      final parsed = double.tryParse(scoreCtrl.text);
                      if (parsed == null || parsed < 0 || parsed > 10) {
                        ScaffoldMessenger.of(ctx2).showSnackBar(
                          const SnackBar(
                            content: Text('Score must be between 0 and 10'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      correctedScoreValue = parsed;
                    }

                    Navigator.pop(ctx2);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          action == 'confirmed'
                              ? 'Confirming assessment...'
                              : 'Applying correction...',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );

                    try {
                      final result = await ApiService.reviewAssessment(
                        assessment.id,
                        status: action,
                        note: noteCtrl.text.isNotEmpty ? noteCtrl.text : null,
                        correctedScore: correctedScoreValue,
                      );

                      if (!context.mounted) return;

                      if (result['id'] != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              action == 'confirmed'
                                  ? 'Assessment confirmed! Parent has been notified.'
                                  : 'Score corrected! Parent has been notified.',
                            ),
                            backgroundColor: AppTheme.accent,
                          ),
                        );
                        onReviewed?.call();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Error: ${result['error'] ?? 'Unknown error'}'),
                            backgroundColor: AppTheme.danger,
                          ),
                        );
                      }
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: AppTheme.danger,
                        ),
                      );
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
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('MMM dd, HH:mm').format(assessment.createdAt),
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _displayChildName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Parent: $_displayParentName',
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary),
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
                  ScoreBadge(assessment.autismScore,
                      correctedScore: assessment.correctedScore),
                  const SizedBox(width: 8),
                  SeverityBadge(assessment.severityLevel),
                  const Spacer(),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.rate_review, size: 14),
                    label: const Text('Review', style: TextStyle(fontSize: 12)),
                    onPressed: () => _showReviewDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27AE60),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                    ),
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

// ──────────── REPORT TAB ────────────
class _ReportTab extends StatefulWidget {
  final List<Assessment> allAssessments;
  final List<Child> displayChildren;
  final Map<String, String> displayParents;
  final String? selectedParentId;
  final String? selectedChildId;
  final VoidCallback onRefresh;

  const _ReportTab({
    required this.allAssessments,
    required this.displayChildren,
    required this.displayParents,
    required this.selectedParentId,
    required this.selectedChildId,
    required this.onRefresh,
  });

  @override
  State<_ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<_ReportTab> {
  final _reportCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _reportCtrl.dispose();
    super.dispose();
  }

  String get _psychologistName {
    final name =
        context.read<AuthService>().currentUser?.name ?? 'Psychologist';
    return 'Dr. $name';
  }

  String? get _selectedParentId => widget.selectedParentId;
  String? get _selectedChildId => widget.selectedChildId;

  String get _selectedParentName {
    final id = _selectedParentId;
    if (id == null) return 'Parent';
    return widget.displayParents[id] ?? 'Parent';
  }

  Child? get _selectedChild {
    final id = _selectedChildId;
    if (id == null) return null;
    try {
      return widget.displayChildren.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  String get _selectedChildName {
    final child = _selectedChild;
    if (child != null) return child.name;

    final id = _selectedChildId;
    if (id != null) {
      for (final a in widget.allAssessments) {
        if (a.childId == id && a.childName != null) return a.childName!;
      }
    }
    return 'Child';
  }

  String? get _reportHeader {
    if (_selectedParentId == null || _selectedChildId == null) return null;
    return '$_psychologistName to $_selectedParentName  ➤ $_selectedChildName\'s report:';
  }

  Future<void> _sendReport() async {
    if (_selectedParentId == null ||
        _selectedChildId == null ||
        _reportCtrl.text.trim().isEmpty) {
      return;
    }

    setState(() => _sending = true);

    try {
      final result = await ApiService.sendChildReport(
        recipientId: _selectedParentId!,
        childId: _selectedChildId!,
        childName: _selectedChildName,
        reportContent: _reportCtrl.text.trim(),
        psychologistName: _psychologistName,
        parentName: _selectedParentName,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _reportCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report sent to parent successfully!'),
            backgroundColor: AppTheme.accent,
          ),
        );
        widget.onRefresh();
      } else {
        final msg = result['message'] ?? 'Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send report: $msg'),
            backgroundColor: AppTheme.danger,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSend = _selectedParentId != null &&
        _selectedChildId != null &&
        _reportCtrl.text.trim().isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_reportHeader != null) ...[
            const SectionTitle('Parent Report'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: AppTheme.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _reportHeader!,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                    child: const Text(
                      'Tips for the psychologist:\n'
                      '• Describe the observation in simple language ).\n'
                      '• Explain the recommendation without medical jargon.\n'
                      '• Highlight strengths + 1–3 clear next steps for the parent.\n'
                      '• If you adjusted scores, briefly mention the clinical reasoning.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _reportCtrl,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Write clinical report',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: Text(_sending ? 'Sending...' : 'Send Report to Parent'),
              onPressed: (canSend && !_sending) ? _sendReport : null,
            ),
          ),
        ],
      ),
    );
  }
}
