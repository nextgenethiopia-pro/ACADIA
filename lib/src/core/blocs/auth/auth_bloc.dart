import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/firebase_auth_service.dart';

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

    final academicPath = profile['academic_path']?.toString() ?? '';
    final grade = profile['grade']?.toString() ?? '';
    final stream = profile['stream']?.toString() ?? '';
    final generation = profile['generation']?.toString() ?? '';
    final university = profile['university']?.toString() ?? '';
    final universityYear = profile['university_year']?.toString() ?? '';
    final semester = profile['semester']?.toString() ?? '';
    final track = profile['track']?.toString() ?? '';
    final fullName = profile['full_name']?.toString() ?? '';
    final email = profile['email']?.toString() ?? '';

    await prefs.setString('academic_path', academicPath);
    await prefs.setString('academic_level', academicPath);
    await prefs.setString('selected_grade', grade);
    await prefs.setString('grade', grade);
    await prefs.setString('selected_stream', stream);
    await prefs.setString('stream', stream);
    await prefs.setString('selected_generation', generation);
    await prefs.setString('generation', generation);
    await prefs.setString('selected_university', university);
    await prefs.setString('university', university);
    await prefs.setString('selected_year', universityYear);
    await prefs.setString('semester', semester);
    await prefs.setString('selected_track', track);
    await prefs.setString('user_name', fullName);
    await prefs.setString('user_email', email);
    await prefs.setBool('onboarding_complete', true);
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
        phoneNumber: event.phoneNumber,
        grade: event.grade,
        stream: event.stream,
        academicPath: event.academicPath,
        generation: event.generation,
        university: event.university,
        universityYear: event.universityYear,
        semester: event.semester,
        track: event.track,
        highSchoolName: event.highSchoolName,
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

        emit(AuthEmailVerificationRequired(user: user));
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
      await prefs.remove('academic_path');
      await prefs.remove('academic_level');
      await prefs.remove('selected_grade');
      await prefs.remove('grade');
      await prefs.remove('selected_stream');
      await prefs.remove('stream');
      await prefs.remove('selected_generation');
      await prefs.remove('generation');
      await prefs.remove('selected_university');
      await prefs.remove('university');
      await prefs.remove('selected_year');
      await prefs.remove('semester');
      await prefs.remove('selected_track');
      await prefs.remove('user_name');
      await prefs.remove('user_email');
      await prefs.setBool('onboarding_complete', false);

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
