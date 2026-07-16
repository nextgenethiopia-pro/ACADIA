import 'package:equatable/equatable.dart';

DateTime? _parseTimestamp(dynamic timestamp) {
  if (timestamp == null) return null;
  if (timestamp is DateTime) return timestamp;
  if (timestamp is String) {
    try {
      return DateTime.parse(timestamp);
    } catch (e) {
      return null;
    }
  }
  try {
    return timestamp.toDate();
  } catch (e) {
    return null;
  }
}

class UserModel extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String? avatarUrl;
  final String academicLevel;
  final String? grade;
  final String? stream;
  final String? generation;
  final String? university;
  final String? universityYear;
  final String? semester;
  final String? track;
  final String pathStatus;
  final DateTime createdAt;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    this.avatarUrl,
    required this.academicLevel,
    this.grade,
    this.stream,
    this.generation,
    this.university,
    this.universityYear,
    this.semester,
    this.track,
    this.pathStatus = 'permanently_locked',
    required this.createdAt,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      phoneNumber: json['phone_number'],
      avatarUrl: json['avatar_url'],
      academicLevel: json['academic_level'],
      grade: json['grade'],
      stream: json['stream'],
      generation: json['generation'],
      university: json['university'],
      universityYear: json['university_year'],
      semester: json['semester'],
      track: json['track'],
      pathStatus: json['path_status'] ?? 'permanently_locked',
      createdAt: _parseTimestamp(json['created_at']) ?? DateTime.now(),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
      'academic_level': academicLevel,
      'grade': grade,
      'stream': stream,
      'generation': generation,
      'university': university,
      'university_year': universityYear,
      'semester': semester,
      'track': track,
      'path_status': pathStatus,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  @override
  List<Object?> get props => [id, email, fullName, phoneNumber, academicLevel, grade, stream];
}
