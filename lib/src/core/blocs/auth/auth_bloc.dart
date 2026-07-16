import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    await prefs.setString('academic_path', profile['academic_path']?.toString() ?? '');
    await prefs.setString('selected_grade', profile['grade']?.toString() ?? '');
    await prefs.setString('selected_stream', profile['stream']?.toString() ?? '');
    await prefs.setString('academic_level', profile['academic_path']?.toString() ?? '');
    await prefs.setString('grade', profile['grade']?.toString() ?? '');
    await prefs.setString('stream', profile['stream']?.toString() ?? '');
    await prefs.setBool('onboarding_complete', true);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = _authService.currentUser;
      if (user != null) {
        // Force reload to get latest emailVerified status
        await user.reload();
        final updatedUser = _authService.currentUser;
        
        if (updatedUser != null && updatedUser.emailVerified) {
          final profile = await _authService.getUserProfile();
          await _cacheProfileLocally(profile);
          final isAdmin = await _authService.isAdmin();
          print('AuthBloc: Authenticated state emitted (Check). isAdmin: $isAdmin');
          emit(Authenticated(user: updatedUser, profile: profile, isAdmin: isAdmin));
        } else if (updatedUser != null) {
          emit(AuthEmailVerificationRequired(user: updatedUser));
        } else {
          emit(Unauthenticated());
        }
      } else {
        emit(Unauthenticated());
      }
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
        print('AuthBloc: Authenticated state emitted (SignIn). isAdmin: $isAdmin');
        emit(Authenticated(user: user, profile: profile, isAdmin: isAdmin));
      } else {
        final error = response['error'] as String;
        if (response['needsVerification'] == true) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            emit(AuthEmailVerificationRequired(user: user));
          } else {
            emit(AuthError(message: error));
          }
        } else {
          emit(AuthError(message: error));
        }
      }
    } catch (e) {
      emit(AuthError(message: 'An unexpected error occurred: $e'));
    }
  }

  Future<void> _onAuthSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('AuthBloc: SignUp requested for ${event.email}');
    print('AuthBloc: Using _authService of type ${_authService.runtimeType}');
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
      );
      
      if (response['success'] == true) {
        final user = response['user'] as User;
        emit(AuthEmailVerificationRequired(user: user));
      } else {
        emit(AuthError(message: response['error'] as String));
      }
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
        emit(AuthError(message: response['error'] as String));
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
      if (user != null) {
        final profile = await _authService.getUserProfile();
        await _cacheProfileLocally(profile);
        final isAdmin = await _authService.isAdmin();
        print('AuthBloc: Authenticated state emitted (Verified). isAdmin: $isAdmin');
        emit(Authenticated(user: user, profile: profile, isAdmin: isAdmin));
      } else {
        emit(Unauthenticated());
      }
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
        emit(AuthVerificationEmailResent());
      } else {
        emit(AuthError(message: response['error'] as String));
      }
    } catch (e) {
      emit(const AuthError(message: 'An unexpected error occurred'));
    }
  }
}
