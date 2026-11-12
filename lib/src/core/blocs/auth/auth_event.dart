part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthSignInRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  final String? username;
  final String? phoneNumber;
  final String? academicLevel;
  final String? academicPath;
  final String? grade;
  final String? stream;
  final String? department;
  final String? year;
  final String? semester;
  final Map<String, dynamic>? onboardingSelections;

  const AuthSignUpRequested({
    required this.email,
    required this.password,
    required this.fullName,
    this.username,
    this.phoneNumber,
    this.academicLevel,
    this.academicPath,
    this.grade,
    this.stream,
    this.department,
    this.year,
    this.semester,
    this.onboardingSelections,
  });

  @override
  List<Object?> get props => [
        email,
        password,
        fullName,
        username,
        phoneNumber,
        academicLevel,
        academicPath,
        grade,
        stream,
        department,
        year,
        semester,
        onboardingSelections,
      ];
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

class AuthPasswordResetRequested extends AuthEvent {
  final String email;

  const AuthPasswordResetRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class AuthEmailVerified extends AuthEvent {
  const AuthEmailVerified();
}

class AuthResendEmailVerification extends AuthEvent {
  final String email;

  const AuthResendEmailVerification({required this.email});

  @override
  List<Object?> get props => [email];
}
