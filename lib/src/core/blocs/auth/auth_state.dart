part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;
  final Map<String, dynamic>? profile;
  final bool isAdmin;

  const Authenticated({
    required this.user,
    this.profile,
    this.isAdmin = false,
  });

  @override
  List<Object?> get props => [user, profile, isAdmin];
}

class Unauthenticated extends AuthState {}

class AuthEmailVerificationRequired extends AuthState {
  final User user;

  const AuthEmailVerificationRequired({required this.user});

  @override
  List<Object?> get props => [user];
}

class AuthPasswordResetEmailSent extends AuthState {}

class AuthVerificationEmailResent extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}
