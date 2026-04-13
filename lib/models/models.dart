// lib/models/models.dart

import 'dart:ui';

class User {
  final String id;
  final String name;
  final String email;
  final String role; // admin, parent, psychologist, educator
  final String? avatarUrl;
  final String token;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    required this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    name: json['name'],
    email: json['email'],
    role: json['role'],
    avatarUrl: json['avatar_url'],
    token: json['token'],
  );
}

class Child {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String parentId;
  final String? profileImage;
  final DateTime dateOfBirth;
  final List<Assessment> assessments;

  Child({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.parentId,
    this.profileImage,
    required this.dateOfBirth,
    this.assessments = const [],
  });

  factory Child.fromJson(Map<String, dynamic> json) => Child(
    id: json['id'],
    name: json['name'],
    age: json['age'],
    gender: json['gender'],
    parentId: json['parent_id'],
    profileImage: json['profile_image'],
    dateOfBirth: DateTime.parse(json['date_of_birth']),
    assessments: (json['assessments'] as List? ?? [])
        .map((a) => Assessment.fromJson(a))
        .toList(),
  );
}

class Assessment {
  final String id;
  final String childId;
  final String activityType;
  final String audioTranscription;
  final double autismScore;
  final String severityLevel; // mild, moderate, severe
  final Map<String, double> dimensionScores;
  final String? aiAnalysis;
  final String status; // pending, reviewed, confirmed, corrected
  final String? psychologistNote;
  final double? correctedScore;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  Assessment({
    required this.id,
    required this.childId,
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
  });

  factory Assessment.fromJson(Map<String, dynamic> json) => Assessment(
    id: json['id'],
    childId: json['child_id'],
    activityType: json['activity_type'],
    audioTranscription: json['audio_transcription'],
    autismScore: (json['autism_score'] as num).toDouble(),
    severityLevel: json['severity_level'],
    dimensionScores: Map<String, double>.from(
        json['dimension_scores']?.map((k, v) => MapEntry(k, (v as num).toDouble())) ?? {}),
    aiAnalysis: json['ai_analysis'],
    status: json['status'],
    psychologistNote: json['psychologist_note'],
    correctedScore: json['corrected_score'] != null
        ? (json['corrected_score'] as num).toDouble()
        : null,
    createdAt: DateTime.parse(json['created_at']),
    reviewedAt: json['reviewed_at'] != null
        ? DateTime.parse(json['reviewed_at'])
        : null,
  );

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
  final String type; // assessment_result, message, reminder
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
    id: json['id'],
    title: json['title'],
    message: json['message'],
    type: json['type'],
    isRead: json['is_read'],
    createdAt: DateTime.parse(json['created_at']),
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
        id: json['id'],
        title: json['title'],
        description: json['description'],
        date: DateTime.parse(json['date']),
        time: json['time'],
        activityType: json['activity_type'],
        participantIds: List<String>.from(json['participant_ids'] ?? []),
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