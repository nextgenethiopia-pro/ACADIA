import 'package:cloud_firestore/cloud_firestore.dart';
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
  if (timestamp is Timestamp) {
    return timestamp.toDate();
  }
  return null;
}

Map<String, dynamic>? _parseMap(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    try {
      return Map<String, dynamic>.from(value);
    } catch (_) {
      return null;
    }
  }
  return null;
}

bool? _parseBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is String) {
    final lower = value.toLowerCase();
    if (lower == 'true') return true;
    if (lower == 'false') return false;
  }
  return null;
}

class UserModel extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String username;
  final String phoneNumber;
  final String? avatarUrl;
  final String academicLevel;
  final String? grade;
  final String? stream;
  final String? department;
  final String? year;
  final String? semester;
  final Map<String, dynamic>? onboardingSelections;
  final String selectedPackage;
  final String paymentStatus;
  final String accountStatus;
  final DateTime? registrationDate;
  final DateTime? lastLogin;
  final bool notificationPreferences;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.username,
    required this.phoneNumber,
    this.avatarUrl,
    required this.academicLevel,
    this.grade,
    this.stream,
    this.department,
    this.year,
    this.semester,
    this.onboardingSelections,
    required this.selectedPackage,
    required this.paymentStatus,
    required this.accountStatus,
    this.registrationDate,
    this.lastLogin,
    required this.notificationPreferences,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['uid'] ?? '';
    final rawEmail = json['email'] ?? json['user_email'] ?? '';
    final rawFullName = json['full_name'] ?? json['fullName'] ?? json['name'] ?? json['user_name'] ?? 'Unknown User';
    final rawUsername = json['username'] ?? json['userName'] ?? (rawEmail.isNotEmpty ? rawEmail.split('@')[0] : 'user${rawId.substring(rawId.length.clamp(0, 4))}');
    final rawPhoneNumber = json['phone_number'] ?? json['phoneNumber'] ?? json['phone'] ?? json['user_phone'] ?? '';
    final onboarding = _parseMap(json['onboarding_selections'] ?? json['onboardingSelections']);

    final rawAcademicLevel = json['academic_level'] ??
        json['academic_path'] ??
        json['academicLevel'] ??
        json['academicPath'] ??
        json['school_level'] ??
        onboarding?['academicLevel'] ??
        onboarding?['academicPath'] ??
        'HIGH SCHOOL';

    final resolvedGrade = json['grade'] ?? json['selected_grade'] ?? onboarding?['grade'];
    final resolvedStream = json['stream'] ?? json['selected_stream'] ?? onboarding?['stream'];
    final resolvedDepartment = json['department'] ?? json['selected_department'] ?? onboarding?['department'];
    final resolvedYear = json['year'] ?? json['selected_year'] ?? json['university_year'] ?? onboarding?['year'];
    final resolvedSemester = json['semester'] ?? onboarding?['semester'];

    final rawSelectedPackage = json['selected_package'] ?? json['selectedPackage'] ?? json['package'] ?? 'free';
    final rawPaymentStatus = json['payment_status'] ?? json['paymentStatus'] ?? (rawSelectedPackage != 'free' ? 'paid' : 'pending');
    final rawAccountStatus = json['account_status'] ?? json['accountStatus'] ?? (json['is_banned'] == true ? 'banned' : 'active');
    final rawNotificationPrefs = _parseBool(json['notification_preferences'] ?? json['notificationPreferences']) ?? true;

    return UserModel(
      id: rawId.toString(),
      email: rawEmail.toString(),
      fullName: rawFullName.toString(),
      username: rawUsername.toString(),
      phoneNumber: rawPhoneNumber.toString(),
      avatarUrl: json['avatar_url'] ?? json['avatarUrl'] ?? json['profile_picture'] ?? json['photo_url'],
      academicLevel: rawAcademicLevel.toString(),
      grade: resolvedGrade?.toString(),
      stream: resolvedStream?.toString(),
      department: resolvedDepartment?.toString(),
      year: resolvedYear?.toString(),
      semester: resolvedSemester?.toString(),
      onboardingSelections: onboarding,
      selectedPackage: rawSelectedPackage.toString(),
      paymentStatus: rawPaymentStatus.toString(),
      accountStatus: rawAccountStatus.toString(),
      registrationDate: _parseTimestamp(json['registration_date'] ?? json['registrationDate'] ?? json['created_at']),
      lastLogin: _parseTimestamp(json['last_login'] ?? json['lastLogin'] ?? json['last_active']),
      notificationPreferences: rawNotificationPrefs,
      createdAt: _parseTimestamp(json['created_at'] ?? json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseTimestamp(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'username': username,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
      'academic_level': academicLevel,
      'academic_path': academicLevel,
      'academicLevel': academicLevel,
      'academicPath': academicLevel,
      'grade': grade,
      'stream': stream,
      'department': department,
      'year': year,
      'semester': semester,
      'onboarding_selections': onboardingSelections,
      'selected_package': selectedPackage,
      'selectedPackage': selectedPackage,
      'payment_status': paymentStatus,
      'paymentStatus': paymentStatus,
      'account_status': accountStatus,
      'accountStatus': accountStatus,
      'registration_date': registrationDate?.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'notification_preferences': notificationPreferences,
      'notificationPreferences': notificationPreferences,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        username,
        phoneNumber,
        avatarUrl,
        academicLevel,
        grade,
        stream,
        department,
        year,
        semester,
        onboardingSelections,
        selectedPackage,
        paymentStatus,
        accountStatus,
        registrationDate,
        lastLogin,
        notificationPreferences,
        createdAt,
        updatedAt,
      ];
}
