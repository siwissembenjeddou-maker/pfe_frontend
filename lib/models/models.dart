// lib/models/models.dart

import 'dart:ui';

class User {
  final String id;
  final String? name;
  final String email;
  final String role;
  final String? avatarUrl;
  final String? token;

  User({
    required this.id,
    this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: (json['id'] ?? '').toString(),
        name: json['name']?.toString(),
        email: (json['email'] ?? '').toString(),
        role: (json['role'] ?? 'user').toString(),
        avatarUrl: json['avatar_url']?.toString(),
        token: json['token']?.toString(),
      );
}

class Child {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String parentId;
  final String? parentName;
  final String? profileImage;
  final DateTime dateOfBirth;
  final List<Assessment> assessments;

  Child({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.parentId,
    this.parentName,
    this.profileImage,
    required this.dateOfBirth,
    this.assessments = const [],
  });

  double? get finalScore {
    if (assessments.isEmpty) return null;

    final effectiveScores =
        assessments.map((a) => (a.correctedScore ?? a.autismScore)).toList();
    if (effectiveScores.isEmpty) return null;

    final sum = effectiveScores.reduce((x, y) => x + y);
    return sum / effectiveScores.length;
  }

  factory Child.fromJson(Map<String, dynamic> json) => Child(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? 'Unknown').toString(),
        age: (json['age'] as num?)?.toInt() ?? 0,
        gender: (json['gender'] ?? 'Unknown').toString(),
        parentId: (json['parent_id'] ?? json['parentId'] ?? '').toString(),
        parentName: json['parent_name']?.toString(),
        profileImage: json['profile_image']?.toString(),
        dateOfBirth: json['date_of_birth'] != null
            ? DateTime.parse(json['date_of_birth'].toString())
            : DateTime.now(),
        assessments: (json['assessments'] as List? ?? [])
            .map((a) => Assessment.fromJson(a as Map<String, dynamic>))
            .toList(),
      );
}

class Assessment {
  final String id;
  final String childId;
  final String? childName;
  final String? parentId;
  final String? parentName;
  final String activityType;
  final String audioTranscription;
  final double autismScore;
  final String severityLevel;
  final Map<String, double> dimensionScores;
  final String? aiAnalysis;
  final String status;
  final String? psychologistNote;
  final double? correctedScore;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final List<String> immediateRecommendations;
  final List<String> keyObservations;

  Assessment({
    required this.id,
    required this.childId,
    this.childName,
    this.parentId,
    this.parentName,
    required this.activityType,
    required this.audioTranscription,
    required this.autismScore,
    required this.severityLevel,
    required this.dimensionScores,
    this.aiAnalysis,
    required this.status,
    this.psychologistNote,
    this.correctedScore,
    required this.createdAt,
    this.reviewedAt,
    this.immediateRecommendations = const [],
    this.keyObservations = const [],
  });

  factory Assessment.fromJson(Map<String, dynamic> json) => Assessment(
        id: (json['id'] ?? '').toString(),
        childId: (json['child_id'] ?? json['child'] ?? '').toString(),
        childName: json['child_name']?.toString(),
        parentId: json['parent_id']?.toString(),
        parentName: json['parent_name']?.toString(),
        activityType: (json['activity_type'] ?? 'Unknown').toString(),
        audioTranscription: (json['audio_transcription'] ?? '').toString(),
        autismScore: (json['autism_score'] as num? ?? 0).toDouble(),
        severityLevel: (json['severity_level'] ?? 'unknown').toString(),
        dimensionScores: _parseDimensionScores(json['dimension_scores']),
        aiAnalysis: json['ai_analysis']?.toString(),
        status: (json['status'] ?? 'pending').toString(),
        psychologistNote: json['psychologist_note']?.toString(),
        correctedScore: json['corrected_score'] != null
            ? (json['corrected_score'] as num).toDouble()
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'].toString())
            : DateTime.now(),
        reviewedAt: json['reviewed_at'] != null
            ? DateTime.parse(json['reviewed_at'].toString())
            : null,
        immediateRecommendations:
            _parseStringList(json['immediate_recommendations']),
        keyObservations: _parseStringList(json['key_observations']),
      );

  static Map<String, double> _parseDimensionScores(dynamic raw) {
    if (raw == null || raw is! Map) return {};
    return raw.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
  }

  static List<String> _parseStringList(dynamic raw) {
    if (raw == null || raw is! List) return [];
    return raw.map((e) => e.toString()).toList();
  }

  Color get severityColor {
    switch (severityLevel.toLowerCase()) {
      case 'mild':
        return const Color(0xFF50C878);
      case 'moderate':
        return const Color(0xFFFF8C00);
      case 'severe':
        return const Color(0xFFE74C3C);
      default:
        return const Color(0xFF7F8C8D);
    }
  }
}

class Notification {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) => Notification(
        id: (json['id'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        message: (json['message'] ?? '').toString(),
        type: (json['type'] ?? 'general').toString(),
        isRead: json['is_read'] == true,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'].toString())
            : DateTime.now(),
      );
}

class ActivitySchedule {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String time;
  final String activityType;
  final List<String> participantIds;

  ActivitySchedule({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.activityType,
    required this.participantIds,
  });

  factory ActivitySchedule.fromJson(Map<String, dynamic> json) =>
      ActivitySchedule(
        id: (json['id'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        date: json['date'] != null
            ? DateTime.parse(json['date'].toString())
            : DateTime.now(),
        time: (json['time'] ?? '').toString(),
        activityType: (json['activity_type'] ?? '').toString(),
        participantIds: (json['participant_ids'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}

const List<String> activityTypes = [
  'Eating',
  'Drinking',
  'Writing',
  'Playing',
  'Communicating',
  'Social Interaction',
  'Repetitive Behaviors',
  'Sensory Response',
  'Drawing',
  'Reading',
];

const Map<String, String> activityIcons = {
  'Eating': '🍽️',
  'Drinking': '🥤',
  'Writing': '✏️',
  'Playing': '🎮',
  'Communicating': '💬',
  'Social Interaction': '🤝',
  'Repetitive Behaviors': '🔄',
  'Sensory Response': '👁️',
  'Drawing': '🎨',
  'Reading': '📖',
};
