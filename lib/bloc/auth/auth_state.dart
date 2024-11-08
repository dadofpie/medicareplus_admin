part of 'auth_bloc.dart';

@immutable
sealed class AuthState {}

final class AuthInitial extends AuthState {}

final class AuthSuccess extends AuthState {
  final int uid;
  final String adminType;
  final int departmentId;
  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String department;
  final String status;

  AuthSuccess(
      {required this.uid,
      required this.adminType,
      required this.departmentId,
      required this.firstName,
      required this.middleName,
      required this.lastName,
      required this.email,
      required this.department,
      required this.status});
}

final class AuthFailure extends AuthState {
  final String error;

  AuthFailure(this.error);
}

final class AuthLoading extends AuthState {}
