// lib/screens/parent/solutions_screen.dart
import 'package:flutter/material.dart';
import '../../main.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';

class SolutionsTab extends StatelessWidget {
  final Child child;
  const SolutionsTab({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (child.assessments.isEmpty) {
      return const EmptyState(
        icon: Icons.lightbulb_outline,
        message: 'No assessments yet.\nComplete an assessment to receive personalised solutions.',
      );
    }
    final latest = child.assessments.last;
    final score = latest.correctedScore ?? latest.autismScore;
    return SolutionsPage(child: child, score: score, assessment: latest);
  }
}

class SolutionsPage extends StatefulWidget {
  final Child child;
  final double score;
  final Assessment assessment;
  const SolutionsPage({super.key, required this.child, required this.score, required this.assessment});

  @override
  State<SolutionsPage> createState() => _SolutionsPageState();
}

class _SolutionsPageState extends State<SolutionsPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  SolutionProfile get _profile => SolutionProfile.fromScore(widget.score);

  @override
  Widget build(BuildContext context) {
    final p = _profile;
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(child: _ScoreHeader(child: widget.child, score: widget.score, profile: p)),
          SliverToBoxAdapter(
            child: TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              labelColor: p.color,
              indicatorColor: p.color,
              unselectedLabelColor: AppTheme.textSecondary,
              tabs: const [
                Tab(text: '🏠 Daily Life'),
                Tab(text: '🧠 Therapy'),
                Tab(text: '🎮 Activities'),
                Tab(text: '📚 Resources'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _DailyLifeTab(profile: p, dimensions: widget.assessment.dimensionScores),
            _TherapyTab(profile: p),
            _ActivitiesTab(profile: p, activityType: widget.assessment.activityType),
            _ResourcesTab(profile: p),
          ],
        ),
      ),
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  final Child child;
  final double score;
  final SolutionProfile profile;
  const _ScoreHeader({required this.child, required this.score, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [profile.color, profile.color.withOpacity(0.7)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: profile.color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white.withOpacity(0.25),
              child: Text(child.name[0], style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Solutions for ${child.name}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                Text('${child.age} years old • Personalised plan', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Autism Score', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(score.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                const Text('out of 10.0', style: TextStyle(color: Colors.white60, fontSize: 11)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.4)),
              ),
              child: Column(children: [
                Text(profile.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 4),
                Text(profile.levelName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                const Text('Level', style: TextStyle(color: Colors.white70, fontSize: 11)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Text(profile.summary, style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _DailyLifeTab extends StatelessWidget {
  final SolutionProfile profile;
  final Map<String, double> dimensions;
  const _DailyLifeTab({required this.profile, required this.dimensions});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(icon: '🌅', title: 'Morning Routine', color: profile.color, tips: profile.morningRoutine),
        _SectionCard(icon: '🍽️', title: 'Mealtime Strategies', color: profile.color, tips: profile.mealtimeTips),
        _SectionCard(icon: '😴', title: 'Sleep & Bedtime', color: profile.color, tips: profile.sleepTips),
        _SectionCard(icon: '🏠', title: 'Home Environment', color: profile.color, tips: profile.homeTips),
        if (dimensions.isNotEmpty) ...[
          const SizedBox(height: 8),
          _DimensionRecommendations(dimensions: dimensions, color: profile.color),
        ],
      ],
    );
  }
}

class _TherapyTab extends StatelessWidget {
  final SolutionProfile profile;
  const _TherapyTab({required this.profile});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _PriorityBanner(profile: profile),
        const SizedBox(height: 12),
        ...profile.therapies.map((t) => _TherapyCard(therapy: t, color: profile.color)),
        _SectionCard(icon: '👨‍👩‍👧', title: 'Parent Involvement', color: profile.color, tips: profile.parentInvolvement),
      ],
    );
  }
}

class _ActivitiesTab extends StatelessWidget {
  final SolutionProfile profile;
  final String activityType;
  const _ActivitiesTab({required this.profile, required this.activityType});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: profile.color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: profile.color.withOpacity(0.2)),
          ),
          child: Row(children: [
            Icon(Icons.star, color: profile.color),
            const SizedBox(width: 8),
            Expanded(child: Text('Specific tips for: $activityType', style: TextStyle(color: profile.color, fontWeight: FontWeight.bold))),
          ]),
        ),
        const SizedBox(height: 12),
        ..._getActivityTips(activityType, profile).map((tip) => _TipTile(tip: tip, color: profile.color)),
        const SizedBox(height: 8),
        _SectionCard(icon: '🎯', title: 'Recommended Daily Activities', color: profile.color, tips: profile.recommendedActivities),
        _SectionCard(icon: '🚫', title: 'Activities to Approach Carefully', color: AppTheme.warning, tips: profile.cautionActivities),
      ],
    );
  }

  List<String> _getActivityTips(String activity, SolutionProfile p) {
    final base = <String, List<String>>{
      'Eating': ['Use visual menus or picture cards for food choices.', 'Maintain consistent meal times and seating positions.', 'Introduce new foods gradually beside familiar ones.', 'Reduce distractions (TV, noise) during meals.', 'Allow the child to use preferred utensils or cups.'],
      'Drinking': ['Offer drinks in a consistent cup or bottle.', 'Use visual schedules to signal drink times.', 'Try flavoured water if plain water is refused.', 'Model drinking behaviour during the same time.'],
      'Writing': ['Use pencil grips for better hand control.', 'Start with large-line writing paper.', 'Try sand trays or finger painting before pencil work.', 'Break writing tasks into small, timed segments.', 'Celebrate every small achievement verbally.'],
      'Playing': ['Follow the child\'s lead during play sessions.', 'Set up structured play environments with clear boundaries.', 'Use social stories to explain play rules.', 'Introduce turn-taking with a timer.', 'Play alongside the child before expecting interaction.'],
      'Communicating': ['Use simple, clear sentences and pause for a response.', 'Supplement speech with picture cards (AAC).', 'Acknowledge every communication attempt.', 'Avoid questions with too many options at once.', 'Use the child\'s name before giving instructions.'],
    };
    return base[activity] ?? p.recommendedActivities.take(5).toList();
  }
}

class _ResourcesTab extends StatelessWidget {
  final SolutionProfile profile;
  const _ResourcesTab({required this.profile});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(icon: '📖', title: 'Books for Parents', color: profile.color, tips: _books),
        _SectionCard(icon: '🌐', title: 'Helpful Websites', color: AppTheme.secondary, tips: _websites),
        _SectionCard(icon: '📞', title: 'Support Networks', color: AppTheme.accent, tips: _support),
        _SectionCard(icon: '📝', title: 'Track Progress', color: profile.color, tips: profile.trackingTips),
      ],
    );
  }

  static const _books = [
    '"The Explosive Child" – Ross W. Greene: Managing emotional meltdowns.',
    '"Ten Things Every Child with Autism Wishes You Knew" – Ellen Notbohm.',
    '"Autism Spectrum Disorder: What Every Parent Needs to Know" – AAP.',
    '"The Reason I Jump" – Naoki Higashida: Inside perspective from an autistic child.',
  ];

  static const _websites = [
    'autismspeaks.org – resources, toolkits, research updates.',
    'autism-society.org – community support and local chapters.',
    'cdc.gov/autism – evidence-based information and screening tools.',
    'exceptionalindividuals.com – employment and education resources.',
  ];

  static const _support = [
    'Connect with local autism parent support groups.',
    'Ask your psychologist about regional early intervention services.',
    'Explore government disability benefit programmes in your country.',
    'Join online communities (Facebook groups, Reddit r/autism).',
  ];
}

class _SectionCard extends StatelessWidget {
  final String icon, title;
  final Color color;
  final List<String> tips;
  const _SectionCard({required this.icon, required this.title, required this.color, required this.tips});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15)),
          ]),
          const Divider(height: 16),
          ...tips.map((t) => _TipTile(tip: t, color: color)),
        ]),
      ),
    );
  }
}

class _TipTile extends StatelessWidget {
  final String tip;
  final Color color;
  const _TipTile({required this.tip, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(margin: const EdgeInsets.only(top: 5), width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(child: Text(tip, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.4))),
      ]),
    );
  }
}

class _PriorityBanner extends StatelessWidget {
  final SolutionProfile profile;
  const _PriorityBanner({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: profile.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: profile.color.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('⚡ Priority Recommendation', style: TextStyle(fontWeight: FontWeight.bold, color: profile.color)),
        const SizedBox(height: 6),
        Text(profile.priorityMessage, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.4)),
      ]),
    );
  }
}

class _TherapyCard extends StatelessWidget {
  final TherapyInfo therapy;
  final Color color;
  const _TherapyCard({required this.therapy, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Text(therapy.emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(therapy.name, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15)),
              Text(therapy.frequency, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: therapy.urgencyColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(therapy.urgency, style: TextStyle(color: therapy.urgencyColor, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 10),
          Text(therapy.description, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.4)),
          const SizedBox(height: 6),
          Text('💡 ${therapy.parentTip}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontStyle: FontStyle.italic)),
        ]),
      ),
    );
  }
}

class _DimensionRecommendations extends StatelessWidget {
  final Map<String, double> dimensions;
  final Color color;
  const _DimensionRecommendations({required this.dimensions, required this.color});

  @override
  Widget build(BuildContext context) {
    final sorted = dimensions.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(3).toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('🎯', style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text('Focus Areas', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15)),
          ]),
          const SizedBox(height: 4),
          const Text('Based on your child\'s highest-scored dimensions:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const Divider(height: 14),
          ...top.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ScoreBadge(score: e.value),
              ]),
              const SizedBox(height: 4),
              Text(_dimensionAdvice(e.key, e.value), style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.3)),
            ]),
          )),
        ]),
      ),
    );
  }

  String _dimensionAdvice(String dim, double val) {
    final tips = <String, String>{
      'Social Interaction': val > 6 ? 'Start with 1-on-1 play, limit group sizes, use social stories daily.' : val > 3 ? 'Encourage parallel play, praise every social attempt.' : 'Keep up structured peer interactions to maintain progress.',
      'Communication': val > 6 ? 'Introduce AAC tools (picture boards or apps). Work with SLP weekly.' : val > 3 ? 'Use simple sentences. Wait 5–10 seconds for a response after asking.' : 'Expand vocabulary through reading aloud and conversations.',
      'Repetitive Behaviors': val > 6 ? 'Identify triggers. Offer sensory alternatives (fidget tools, weighted blankets).' : val > 3 ? 'Allow a safe stim space. Gradually redirect to functional alternatives.' : 'Allow stim breaks during the day while teaching self-regulation.',
      'Sensory Response': val > 6 ? 'Create a sensory diet with an occupational therapist. Reduce sensory overload at home.' : val > 3 ? 'Use noise-cancelling headphones in loud environments.' : 'Monitor sensory triggers and keep a log for the therapist.',
    };
    return tips[dim] ?? 'Work with your specialist to develop a targeted plan for $dim.';
  }
}

class TherapyInfo {
  final String emoji, name, frequency, description, parentTip, urgency;
  const TherapyInfo({
    required this.emoji,
    required this.name,
    required this.frequency,
    required this.description,
    required this.parentTip,
    required this.urgency,
  });

  Color get urgencyColor {
    switch (urgency) {
      case 'ESSENTIAL': return AppTheme.danger;
      case 'RECOMMENDED': return AppTheme.warning;
      default: return AppTheme.accent;
    }
  }
}

class SolutionProfile {
  final String levelName, emoji, summary, priorityMessage;
  final Color color;
  final List<String> morningRoutine, mealtimeTips, sleepTips, homeTips,
      recommendedActivities, cautionActivities, parentInvolvement, trackingTips;
  final List<TherapyInfo> therapies;

  const SolutionProfile({
    required this.levelName,
    required this.emoji,
    required this.summary,
    required this.priorityMessage,
    required this.color,
    required this.morningRoutine,
    required this.mealtimeTips,
    required this.sleepTips,
    required this.homeTips,
    required this.recommendedActivities,
    required this.cautionActivities,
    required this.parentInvolvement,
    required this.trackingTips,
    required this.therapies,
  });

  factory SolutionProfile.fromScore(double score) {
    if (score < 3.0) return _mild;
    if (score < 6.0) return _moderate;
    return _severe;
  }

  static const _mild = SolutionProfile(
    levelName: 'Mild',
    emoji: '🟢',
    color: AppTheme.accent,
    summary: 'Your child shows mild indicators. With consistent support and early intervention strategies, significant progress is very achievable. Focus on social skills and communication enrichment.',
    priorityMessage: 'Early intervention at this stage yields the best long-term outcomes. Continue regular assessment every 3 months and maintain a structured, predictable routine.',
    morningRoutine: ['Use a visual picture schedule posted at child\'s eye level.', 'Give 5-minute and 2-minute warnings before transitions.', 'Keep wake-up, breakfast and school prep at the same time daily.', 'Allow the child to choose between 2 outfit options.', 'Use positive reinforcement ("great job getting dressed!") immediately.'],
    mealtimeTips: ['Eat at the same table and time each day.', 'Introduce one new food per week beside a preferred food.', 'Use divided plates to prevent foods from touching.', 'Offer choices: "Would you like apple or banana?"', 'Make meal prep a shared activity to increase food acceptance.'],
    sleepTips: ['Follow a calming 20-min bedtime routine (bath → book → bed).', 'Dim lights 30 minutes before bed.', 'Use a white noise machine to block environmental sounds.', 'Allow a comfort object (stuffed animal, blanket).', 'Maintain the same bedtime even on weekends.'],
    homeTips: ['Create a quiet corner with soft lighting for self-regulation.', 'Label storage bins with pictures so the child can tidy up.', 'Reduce clutter to avoid visual overstimulation.', 'Keep sensory-friendly items (fidget toys, playdough) accessible.', 'Establish clear, consistent house rules with visual reminders.'],
    recommendedActivities: ['Group play with 1–2 peers in structured settings.', 'Board games to practice turn-taking.', 'Arts and crafts for fine motor development.', 'Swimming or cycling for gross motor skills.', 'Music therapy to support communication.', 'Reading picture books together daily.'],
    cautionActivities: ['Large unstructured group activities without adult facilitation.', 'Very loud or chaotic environments without preparation.', 'Abrupt changes to planned activities without warning.'],
    parentInvolvement: ['Attend parent training sessions (e.g., ESDM or PRT workshops).', 'Read about ABA (Applied Behaviour Analysis) basics online.', 'Practise 15 minutes of focused play interaction daily.', 'Journal your child\'s progress weekly to spot patterns.'],
    trackingTips: ['Record new words or communication skills weekly.', 'Note meltdown triggers and duration in a diary.', 'Take short video clips of positive behaviours to share with therapist.', 'Review progress at each specialist appointment.'],
    therapies: [
      TherapyInfo(emoji: '🗣️', name: 'Speech & Language Therapy', frequency: '1–2 sessions / week', urgency: 'RECOMMENDED', description: 'Focuses on expanding vocabulary, sentence structure, and pragmatic (social) communication skills. At mild level, goals include conversational reciprocity and narrative skills.', parentTip: 'Practise 10-min language activities at home using the therapist\'s suggestions.'),
      TherapyInfo(emoji: '🤝', name: 'Social Skills Groups', frequency: 'Weekly group sessions', urgency: 'RECOMMENDED', description: 'Small-group settings where children practise turn-taking, reading facial expressions, and building friendships in a structured, safe environment.', parentTip: 'Arrange a regular play date with one group member to generalise skills.'),
      TherapyInfo(emoji: '🎨', name: 'Occupational Therapy', frequency: 'Bi-weekly (as needed)', urgency: 'OPTIONAL', description: 'Supports sensory regulation and fine motor skills such as writing, cutting, and self-care tasks.', parentTip: 'Ask the OT for a sensory diet schedule you can follow at home.'),
    ],
  );

  static const _moderate = SolutionProfile(
    levelName: 'Moderate',
    emoji: '🟡',
    color: AppTheme.warning,
    summary: 'Your child shows moderate autism indicators. A multi-disciplinary approach combining behavioural therapy, speech therapy, and consistent home strategies will make a meaningful difference.',
    priorityMessage: 'Coordinate with a team: a psychologist, speech therapist, and occupational therapist together provide the best outcomes. Aim for assessment every 2 months.',
    morningRoutine: ['Use a detailed visual schedule with photos for each step.', 'Set phone timers for each routine step (get dressed: 10 min).', 'Prepare clothes, bags and breakfast the evening before.', 'Offer the same breakfast options each day to reduce decision stress.', 'Praise every completed step of the routine immediately.'],
    mealtimeTips: ['Keep exact same seating, plates and utensils daily.', 'Use a visual timer showing how long mealtime lasts.', 'Pair new foods with a preferred food already on the plate.', 'Reduce strong smells during cooking where possible.', 'Allow the child to help with simple safe preparation tasks.'],
    sleepTips: ['Begin wind-down routine 45–60 minutes before bed.', 'Use blackout curtains and maintain room temperature around 18–20°C.', 'Try a weighted blanket (consult OT for correct weight).', 'Social stories about "going to sleep" can help manage anxiety.', 'Avoid screens (TV, tablet) at least 1 hour before bed.'],
    homeTips: ['Create a dedicated sensory room or corner with crash mat, swings if possible.', 'Use visual boundaries (coloured tape on floor) to define spaces.', 'Provide noise-cancelling headphones for loud situations.', 'Establish a meltdown de-escalation kit: favourite toy, headphones, stress ball.', 'Post the daily schedule where the child can check it throughout the day.'],
    recommendedActivities: ['ABA-structured play sessions with a trained therapist.', 'Swimming (excellent for sensory regulation).', 'Horse riding / equine therapy where available.', 'Structured art or music therapy sessions.', 'Building blocks, puzzles, and LEGO for problem-solving.', 'Sensory play: sand, water, kinetic sand.'],
    cautionActivities: ['Crowded public spaces without a plan and de-escalation tool.', 'Activities with unpredictable loud noises (fireworks, concerts).', 'Competitive games that require flexible rule-following.', 'Unstructured free play without a peer mentor present.'],
    parentInvolvement: ['Undergo formal parent training in ABA or ESDM methodology.', 'Attend all therapy sessions initially to learn carry-over strategies.', 'Establish a communication book between school, therapist and home.', 'Reach out to local autism family support networks.', 'Practise generalisation: apply therapy skills at the supermarket, park, etc.'],
    trackingTips: ['Use an app to track meltdown frequency, triggers and resolution strategies.', 'Photograph or video therapy exercises for home reference.', 'Share weekly behaviour data with the psychologist.', 'Track sleep, appetite and mood daily — they affect behaviour significantly.'],
    therapies: [
      TherapyInfo(emoji: '🧩', name: 'Applied Behaviour Analysis (ABA)', frequency: '20–25 hours / week', urgency: 'ESSENTIAL', description: 'Evidence-based therapy that breaks skills into small steps, teaches them through positive reinforcement. Focuses on communication, social, and daily living skills. Highly effective at moderate level.', parentTip: 'Consistency is key — implement ABA strategies at home between sessions.'),
      TherapyInfo(emoji: '🗣️', name: 'Speech & Language Therapy', frequency: '2–3 sessions / week', urgency: 'ESSENTIAL', description: 'At this level, may include AAC (Augmentative and Alternative Communication) devices or PECS (Picture Exchange Communication System) if verbal communication is limited.', parentTip: 'Use the PECS board or AAC device consistently throughout the day at home.'),
      TherapyInfo(emoji: '🤸', name: 'Occupational Therapy', frequency: '1–2 sessions / week', urgency: 'RECOMMENDED', description: 'Addresses sensory processing difficulties, fine and gross motor skills, and self-care independence. Creates a personalised sensory diet for the child.', parentTip: 'Follow the OT\'s sensory diet schedule — even 10-min sensory breaks help.'),
      TherapyInfo(emoji: '🎵', name: 'Music Therapy', frequency: 'Weekly', urgency: 'OPTIONAL', description: 'Uses musical interaction to develop communication, emotional regulation, and social skills. Highly engaging for children who respond well to rhythm and melody.', parentTip: 'Create a family playlist of calming songs to use during stressful moments.'),
    ],
  );

  static const _severe = SolutionProfile(
    levelName: 'Severe',
    emoji: '🔴',
    color: AppTheme.danger,
    summary: 'Your child shows significant autism indicators. Intensive, coordinated professional support is strongly advised. With the right team and strategies in place, children at this level can make meaningful progress.',
    priorityMessage: 'URGENT: Enrol in an intensive early intervention programme immediately. A full multidisciplinary team (psychologist, SLP, OT, behavioural therapist) should assess your child within 30 days.',
    morningRoutine: ['Use a first-then visual board: "First: shoes, Then: breakfast."', 'Reduce verbal instructions — use physical prompts and modelling.', 'Allow extra transition time (15–20 minutes per step).', 'Use the same caregiver for morning routine whenever possible.', 'Celebrate every completed step with a preferred reward immediately.'],
    mealtimeTips: ['Food selectivity may be extreme — work with an OT/SLP feeding specialist.', 'Introduce food through non-eating exploration first (touch, smell).', 'Use a structured mealtime visual schedule.', 'Consult a nutritionist if diet is very restrictive.', 'Never force eating — it can increase food aversion.'],
    sleepTips: ['Sleep difficulties are very common — consult a paediatrician about melatonin.', 'Use a weighted blanket and white noise machine every night.', 'Maintain an absolutely consistent bedtime routine (same steps, same order).', 'Blackout all light sources including standby lights.', 'Consider a bed tent or canopy for a safe enclosed sleep environment.'],
    homeTips: ['Childproof the home for safety — locks on doors, windows, cabinets.', 'Minimise visual clutter to reduce sensory overload.', 'Create a designated safe sensory space with soft walls if possible.', 'Use visual boundaries throughout the home.', 'Have an emergency plan if the child elopes (runs away).'],
    recommendedActivities: ['Intensive 1-on-1 ABA therapy sessions.', 'Sensory integration therapy with OT.', 'Water play and swimming with a trained support person.', 'Cause-and-effect toys (light-up, sound-making).', 'Body movement activities: trampolining, swings, rolling.', 'AAC device / communication board training daily.'],
    cautionActivities: ['Any unstructured activity without 1-on-1 supervision.', 'Crowded or loud public environments without headphones and a plan.', 'Activities requiring complex social understanding.', 'Long car journeys without sensory tools and visual schedules.'],
    parentInvolvement: ['Prioritise your own wellbeing — caregiver burnout is real. Seek respite care.', 'Join an intensive parent training programme (e.g., Hanen, ESDM).', 'Build a support network: family, friends, community.', 'Document everything — videos, journals — for the medical team.', 'Explore government disability support programmes and funding.'],
    trackingTips: ['Track all behaviours (intensity, frequency, duration) daily.', 'Use an ABC chart (Antecedent – Behaviour – Consequence) for each incident.', 'Share data with the entire therapy team weekly.', 'Review and update the intervention plan every 6–8 weeks.'],
    therapies: [
      TherapyInfo(emoji: '🧩', name: 'Intensive ABA Therapy', frequency: '30–40 hours / week', urgency: 'ESSENTIAL', description: 'Highly structured, intensive 1-on-1 intervention. Targets foundational skills: attending, imitation, communication, and reduction of problematic behaviours through evidence-based techniques.', parentTip: 'Implement ABA strategies all waking hours with guidance from the behaviour analyst.'),
      TherapyInfo(emoji: '🗣️', name: 'AAC & Speech Therapy', frequency: '3–5 sessions / week', urgency: 'ESSENTIAL', description: 'May use high-tech AAC devices (e.g., Proloquo2Go) or PECS. Focus is on functional communication: requesting, refusing, commenting. Verbal speech training runs in parallel.', parentTip: 'The AAC device must be available 24/7. Treat it as the child\'s voice.'),
      TherapyInfo(emoji: '🤸', name: 'Occupational Therapy (Intensive)', frequency: '3 sessions / week', urgency: 'ESSENTIAL', description: 'Intensive sensory integration therapy plus daily living skills training. Addresses self-care, feeding, and sensory defensive behaviours systematically.', parentTip: 'Follow the sensory diet every 90 minutes throughout the day.'),
      TherapyInfo(emoji: '🐴', name: 'Equine-Assisted Therapy', frequency: 'Weekly (if accessible)', urgency: 'RECOMMENDED', description: 'Therapeutic horseback riding improves balance, sensory processing, communication, and emotional regulation. Highly effective for non-verbal children.', parentTip: 'Find a certified PATH International centre near you.'),
      TherapyInfo(emoji: '💊', name: 'Medical / Psychiatric Review', frequency: 'Every 3 months', urgency: 'ESSENTIAL', description: 'At severe levels, co-occurring conditions (anxiety, ADHD, epilepsy, GI issues) are common. A paediatric neurologist or psychiatrist should assess and manage these.', parentTip: 'Keep a medical log of all symptoms, medications and any side effects.'),
    ],
  );
}
