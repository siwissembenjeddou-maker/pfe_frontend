import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../main.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';

class TimelineTab extends StatefulWidget {
  final List<Child> Function() getChildren;
  final Future<void> Function()? onRefresh;

  const TimelineTab({
    super.key,
    required this.getChildren,
    this.onRefresh,
  });

  @override
  State<TimelineTab> createState() => _TimelineTabState();
}

class _TimelineTabState extends State<TimelineTab> {
  Child? _selectedChild;
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    final children = widget.getChildren();

    if (children.isEmpty) {
      return const EmptyState(
        icon: Icons.show_chart,
        message: 'No children registered. Please add a child on the Home tab.',
      );
    }

    // Default to the first child if none is selected or the selected child is no longer in the list
    if (_selectedChild == null ||
        !children.any((c) => c.id == _selectedChild!.id)) {
      _selectedChild = children.first;
    } else {
      // Keep the selected child data fresh
      _selectedChild = children.firstWhere((c) => c.id == _selectedChild!.id);
    }

    final child = _selectedChild!;
    // Sort assessments chronologically (oldest to newest) for timeline plotting
    final assessments = List<Assessment>.from(child.assessments)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return RefreshIndicator(
      onRefresh: widget.onRefresh ?? () async {},
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Horizontal Scroll Child Selector
          const SectionTitle('Select Child'),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: children.length,
              itemBuilder: (context, index) {
                final c = children[index];
                final isSelected = c.id == child.id;

                final double avgScore = c.finalScore ?? 0.0;
                Color childColor = AppTheme.primary;
                if (avgScore > 0) {
                  if (avgScore < 3)
                    childColor = AppTheme.accent;
                  else if (avgScore < 6)
                    childColor = AppTheme.warning;
                  else
                    childColor = AppTheme.danger;
                }

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedChild = c;
                      _expandedIndex = null;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    width: 150,
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [childColor, childColor.withOpacity(0.8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? childColor : Colors.grey.shade200,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? childColor.withOpacity(0.3)
                              : Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: isSelected
                              ? Colors.white.withOpacity(0.2)
                              : childColor.withOpacity(0.1),
                          child: Text(
                            c.name[0].toUpperCase(),
                            style: TextStyle(
                              color: isSelected ? Colors.white : childColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                c.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${c.age} years old',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white.withOpacity(0.8)
                                      : AppTheme.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // 2. Score Evolution Timeline Chart Card
          _buildDynamicSectionTitle('${child.name}\'s Score Evolution'),
          const SizedBox(height: 8),
          if (assessments.isEmpty)
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                child: Column(
                  children: [
                    Icon(Icons.show_chart,
                        size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    const Text(
                      'No timeline data available yet.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Record audio or write a text assessment in the "Assess" tab to begin tracking progress.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Autism Score Trend',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Based on ${assessments.length} assessment${assessments.length > 1 ? 's' : ''}',
                                style: const TextStyle(
                                    fontSize: 12, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Avg: ${child.finalScore?.toStringAsFixed(1) ?? '—'}/10',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 180,
                      child: _buildTimelineChart(assessments),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 3. Vertical Milestone List
            const SectionTitle('Milestone Timeline'),
            const SizedBox(height: 12),
            ...List.generate(assessments.length, (index) {
              // We reverse index to show newest milestones first in the vertical timeline
              final chronologicalIndex = assessments.length - 1 - index;
              final assessment = assessments[chronologicalIndex];
              final isLast = index == assessments.length - 1;

              return _buildTimelineMilestoneItem(
                assessment: assessment,
                isLast: isLast,
                index: chronologicalIndex,
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineChart(List<Assessment> sortedAssessments) {
    final spots = List.generate(sortedAssessments.length, (i) {
      final a = sortedAssessments[i];
      final score = a.correctedScore ?? a.autismScore;
      return FlSpot(i.toDouble(), score);
    });

    final double maxX = (sortedAssessments.length - 1).toDouble();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade100,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 2,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value > 10) return const SizedBox.shrink();
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final int idx = value.toInt();
                if (idx < 0 || idx >= sortedAssessments.length)
                  return const SizedBox.shrink();

                // Only show labels for first, middle and last to prevent overlap if many
                if (sortedAssessments.length > 5 &&
                    idx != 0 &&
                    idx != sortedAssessments.length - 1 &&
                    idx != (sortedAssessments.length / 2).floor()) {
                  return const SizedBox.shrink();
                }

                final a = sortedAssessments[idx];
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat('MMM d').format(a.createdAt),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: maxX > 0 ? maxX : 1.0,
        minY: 0,
        maxY: 10,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final a = sortedAssessments[spot.x.toInt()];
                final dateStr = DateFormat('MMM dd, yyyy').format(a.createdAt);
                final score = spot.y.toStringAsFixed(1);
                return LineTooltipItem(
                  '${a.activityType}\n$dateStr\nScore: $score/10',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: sortedAssessments.length > 1,
            gradient: const LinearGradient(
              colors: [
                AppTheme.primary,
                AppTheme.accent,
              ],
            ),
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withOpacity(0.2),
                  AppTheme.accent.withOpacity(0.01),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineMilestoneItem({
    required Assessment assessment,
    required bool isLast,
    required int index,
  }) {
    final score = assessment.correctedScore ?? assessment.autismScore;
    final dateStr = DateFormat('MMMM dd, yyyy').format(assessment.createdAt);
    final timeStr = DateFormat('HH:mm').format(assessment.createdAt);
    final isReviewed = assessment.status != 'pending';
    final isExpanded = _expandedIndex == index;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Timeline Connector Bar & Circle
          SizedBox(
            width: 32,
            child: Column(
              children: [
                // Top line segment
                Container(
                  width: 3,
                  height: 16,
                  color: Colors.grey.shade200,
                ),
                // Circle Node
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: assessment.severityColor,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: assessment.severityColor.withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                // Bottom line segment
                Expanded(
                  child: Container(
                    width: 3,
                    color: isLast ? Colors.transparent : Colors.grey.shade200,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Right Card containing Assessment Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                margin: EdgeInsets.zero,
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Date and Activity badge
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dateStr,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  'Recorded at $timeStr',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: assessment.severityColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              assessment.activityType,
                              style: TextStyle(
                                color: assessment.severityColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Scores Row
                      Row(
                        children: [
                          _buildMiniScoreCard(
                            label: 'Autism Score',
                            value: score.toStringAsFixed(1),
                            color: assessment.severityColor,
                          ),
                          const SizedBox(width: 12),
                          _buildMiniScoreCard(
                            label: 'Severity Level',
                            value: assessment.severityLevel.toUpperCase(),
                            color: assessment.severityColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Show/Hide details button
                      InkWell(
                        onTap: () {
                          setState(() {
                            _expandedIndex = isExpanded ? null : index;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isExpanded
                                    ? 'Hide Details'
                                    : 'Show RAG Analysis & Audio',
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(
                                isExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: AppTheme.primary,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (isExpanded) ...[
                        const Divider(height: 20),
                        // 1. Transcription Panel
                        const Text(
                          '📝 Transcription Snippet',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(8),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Text(
                            assessment.audioTranscription,
                            style: const TextStyle(fontSize: 12, height: 1.4),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 2. AI Analysis Panel
                        if (assessment.aiAnalysis != null &&
                            assessment.aiAnalysis!.isNotEmpty) ...[
                          const Text(
                            '🤖 AI Clinical Analysis',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(10),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppTheme.primary.withOpacity(0.1)),
                            ),
                            child: Text(
                              assessment.aiAnalysis!,
                              style: const TextStyle(fontSize: 12, height: 1.4),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // 3. Psychologist Review panel (if reviewed)
                        if (isReviewed) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4FBF7),
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: const Color(0xFFD1F2E1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.verified_user,
                                        color: AppTheme.accent, size: 16),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        assessment.status == 'corrected'
                                            ? 'Verified with Correction'
                                            : 'Verified & Confirmed',
                                        style: const TextStyle(
                                          color: AppTheme.accent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (assessment.psychologistNote != null &&
                                    assessment
                                        .psychologistNote!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Psychologist Clinical Note:',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '"${assessment.psychologistNote}"',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 1.5, color: Colors.grey),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Awaiting clinical validation by Psychologist',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniScoreCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicSectionTitle(String title) {
    // Dynamically adjust font size based on string length to prevent overflow and look extremely elegant
    final double fontSize = title.length > 25 ? 16.0 : (title.length > 18 ? 18.0 : 20.0);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
