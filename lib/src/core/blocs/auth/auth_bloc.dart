import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/firebase_auth_service.dart';
import '../../services/session_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuthService _authService = FirebaseAuthService();

  AuthBloc() : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignInRequested>(_onAuthSignInRequested);
    on<AuthSignUpRequested>(_onAuthSignUpRequested);
    on<AuthSignOutRequested>(_onAuthSignOutRequested);
    on<AuthPasswordResetRequested>(_onAuthPasswordResetRequested);
    on<AuthEmailVerified>(_onAuthEmailVerified);
    on<AuthResendEmailVerification>(_onAuthResendEmailVerification);
  }

  Future<void> _cacheProfileLocally(Map<String, dynamic>? profile) async {
    if (profile == null) return;

    final prefs = await SharedPreferences.getInstance();

    final onboardingSelections = profile['onboarding_selections'] ?? profile['onboardingSelections'];
    final onboardingMap = onboardingSelections is Map<String, dynamic>
        ? onboardingSelections
        : _parseMap(onboardingSelections);

    final rawAcademicPath = (profile['academic_path'] ??
            profile['academic_level'] ??
            profile['academicLevel'] ??
            onboardingMap?['academicPath'] ??
            onboardingMap?['academicLevel'])
        ?.toString();

    final grade = (profile['grade'] ?? profile['selected_grade'] ?? onboardingMap?['grade'])?.toString();
    final stream = (profile['stream'] ?? profile['selected_stream'] ?? onboardingMap?['stream'])?.toString();
    final department = (profile['department'] ?? profile['selected_department'] ?? onboardingMap?['department'])?.toString();
    final year = (profile['year'] ?? profile['selected_year'] ?? profile['university_year'] ?? onboardingMap?['year'])?.toString();
    final semester = (profile['semester'] ?? onboardingMap?['semester'])?.toString();
    final fullName = profile['full_name']?.toString() ?? profile['fullName']?.toString();
    final email = profile['email']?.toString();

    final generation = (profile['generation'] ?? profile['selected_generation'] ?? onboardingMap?['generation'])?.toString();
    final university = (profile['university'] ?? profile['selected_university'] ?? onboardingMap?['university'])?.toString();
    final universityName = (profile['university_name'] ?? profile['universityName'] ?? onboardingMap?['universityName'] ?? onboardingMap?['university_name'])?.toString();
    final track = (profile['track'] ?? profile['selected_track'] ?? onboardingMap?['track'])?.toString();

    if (rawAcademicPath != null && rawAcademicPath.trim().isNotEmpty) {
      final normalizedPath = rawAcademicPath.trim().toUpperCase();
      await prefs.setString('academic_path', normalizedPath);
      await prefs.setString('academic_level', normalizedPath);
    }

    if (grade != null && grade.trim().isNotEmpty) {
      await prefs.setString('selected_grade', grade.trim());
      await prefs.setString('grade', grade.trim());
    }

    if (stream != null && stream.trim().isNotEmpty) {
      await prefs.setString('selected_stream', stream.trim());
      await prefs.setString('stream', stream.trim());
    }

    if (department != null && department.trim().isNotEmpty) {
      await prefs.setString('selected_department', department.trim());
      await prefs.setString('department', department.trim());
    }

    if (year != null && year.trim().isNotEmpty) {
      await prefs.setString('selected_year', year.trim());
      await prefs.setString('year', year.trim());
      await prefs.setString('university_year', year.trim());
    }

    if (semester != null && semester.trim().isNotEmpty) {
      await prefs.setString('semester', semester.trim());
    }

    if (generation != null && generation.trim().isNotEmpty) {
      await prefs.setString('selected_generation', generation.trim());
      await prefs.setString('generation', generation.trim());
    }

    if (university != null && university.trim().isNotEmpty) {
      await prefs.setString('selected_university', university.trim());
      await prefs.setString('university', university.trim());
    }

    if (universityName != null && universityName.trim().isNotEmpty) {
      await prefs.setString('university_name', universityName.trim());
    }

    if (track != null && track.trim().isNotEmpty) {
      await prefs.setString('selected_track', track.trim());
      await prefs.setString('track', track.trim());
    }

    if (fullName != null && fullName.trim().isNotEmpty) {
      await prefs.setString('user_name', fullName.trim());
    }

    if (email != null && email.trim().isNotEmpty) {
      await prefs.setString('user_email', email.trim());
    }

    await prefs.setBool('onboarding_complete', true);
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

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final user = _authService.currentUser;

      if (user == null) {
        emit(Unauthenticated());
        return;
      }

      await user.reload();
      final updatedUser = _authService.currentUser;

      if (updatedUser == null) {
        emit(Unauthenticated());
        return;
      }

      if (!updatedUser.emailVerified) {
        emit(AuthEmailVerificationRequired(user: updatedUser));
        return;
      }

      final profile = await _authService.getUserProfile();
      await _cacheProfileLocally(profile);
      final isAdmin = await _authService.isAdmin();

      emit(
        Authenticated(
          user: updatedUser,
          profile: profile,
          isAdmin: isAdmin,
        ),
      );
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onAuthSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final response = await _authService.signIn(
        email: event.email,
        password: event.password,
      );

      if (response['success'] == true) {
        final user = response['user'] as User;
        final profile = await _authService.getUserProfile();
        await _cacheProfileLocally(profile);
        final isAdmin = await _authService.isAdmin();

        emit(
          Authenticated(
            user: user,
            profile: profile,
            isAdmin: isAdmin,
          ),
        );
        return;
      }

      final error = response['error'] as String? ?? 'Authentication failed';

      if (response['needsVerification'] == true) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          emit(AuthEmailVerificationRequired(user: user));
        } else {
          emit(AuthError(message: error));
        }
        return;
      }

      emit(AuthError(message: error));
    } catch (e) {
      emit(AuthError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onAuthSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final response = await _authService.signUp(
        email: event.email,
        password: event.password,
        fullName: event.fullName,
        username: event.username,
        phoneNumber: event.phoneNumber,
        academicLevel: event.academicLevel,
        academicPath: event.academicPath,
        grade: event.grade,
        stream: event.stream,
        department: event.department,
        year: event.year,
        semester: event.semester,
        onboardingSelections: event.onboardingSelections,
      );

      if (response['success'] == true) {
        final user = response['user'] as User?;

        if (user == null) {
          emit(
            const AuthError(
              message: 'Account created, but no user session was returned.',
            ),
          );
          return;
        }

        final verificationEmailError =
            response['verificationEmailError'] as String?;
        if (verificationEmailError != null) {
          debugPrint(
            '[AuthBloc] signup succeeded but the verification email failed: '
            '$verificationEmailError',
          );
        }

        emit(
          AuthEmailVerificationRequired(
            user: user,
            warning: verificationEmailError == null
                ? null
                : 'The verification email could not be sent '
                    '($verificationEmailError). Tap "Resend Verification '
                    'Email" once the timer ends, or check that the address is '
                    'correct.',
          ),
        );
        return;
      }

      emit(
        AuthError(
          message: response['error'] as String? ?? 'Failed to create account',
        ),
      );
    } catch (e) {
      emit(AuthError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onAuthSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await _authService.signOut();

      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString(SessionService.prefDeviceIdKey);
      await prefs.clear();

      // The device id must survive sign-out: it identifies this installation
      // for the one-account-one-device check on the next sign-in.
      if (deviceId != null && deviceId.isNotEmpty) {
        await prefs.setString(SessionService.prefDeviceIdKey, deviceId);
      }

      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onAuthPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final response = await _authService.resetPassword(event.email);

      if (response['success'] == true) {
        emit(AuthPasswordResetEmailSent());
      } else {
        emit(
          AuthError(
            message: response['error'] as String? ??
                'Failed to send password reset email',
          ),
        );
      }
    } catch (e) {
      emit(const AuthError(message: 'An unexpected error occurred'));
    }
  }

  Future<void> _onAuthEmailVerified(
    AuthEmailVerified event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final user = _authService.currentUser;

      if (user == null) {
        emit(Unauthenticated());
        return;
      }

      final profile = await _authService.getUserProfile();
      await _cacheProfileLocally(profile);
      final isAdmin = await _authService.isAdmin();

      emit(
        Authenticated(
          user: user,
          profile: profile,
          isAdmin: isAdmin,
        ),
      );
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onAuthResendEmailVerification(
    AuthResendEmailVerification event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final response = await _authService.resendVerificationEmail();

      if (response['success'] == true) {
        final user = _authService.currentUser;
        if (user != null) {
          emit(AuthEmailVerificationRequired(user: user));
        } else {
          emit(AuthVerificationEmailResent());
        }
      } else {
        emit(
          AuthError(
            message: response['error'] as String? ??
                'Failed to resend verification email',
          ),
        );
      }
    } catch (e) {
      emit(const AuthError(message: 'An unexpected error occurred'));
    }
  }
}
