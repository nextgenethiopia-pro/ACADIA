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
  final String? phoneNumber;
  final String? grade;
  final String? stream;
  final String? academicPath;
  final String? generation;
  final String? university;
  final String? universityYear;
  final String? semester;
  final String? track;
  final String? highSchoolName;

  const AuthSignUpRequested({
    required this.email,
    required this.password,
    required this.fullName,
    this.phoneNumber,
    this.grade,
    this.stream,
    this.academicPath,
    this.generation,
    this.university,
    this.universityYear,
    this.semester,
    this.track,
    this.highSchoolName,
  });

  @override
  List<Object?> get props => [
        email,
        password,
        fullName,
        phoneNumber,
        grade,
        stream,
        academicPath,
        generation,
        university,
        universityYear,
        semester,
        track,
        highSchoolName,
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
