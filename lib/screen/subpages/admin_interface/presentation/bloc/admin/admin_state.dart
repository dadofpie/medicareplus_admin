// ignore_for_file: public_member_api_docs, sort_constructors_first

part of 'admin_bloc.dart';

enum AdminFetchStatus {
  initial,
  loading,
  success,
  error,
}

/*class AdminState extends Equatable {
  final AdminFetchStatus status;
  final List adminAccounts;

  const AdminState({required this.status, required this.adminAccounts});

  factory AdminState.initial() {
    return const AdminState(
        status: AdminFetchStatus.initial, adminAccounts: []);
  }

  @override
  List<Object> get props => [status, adminAccounts];

  @override
  bool get stringify => true;

  AdminState copyWith({
    AdminFetchStatus? status,
    List? adminAccounts,
  }) {
    return AdminState(
      status: status ?? this.status,
      adminAccounts: adminAccounts ?? this.adminAccounts,
    );
  }
}*/

class AdminState extends Equatable {
  final AdminFetchStatus status;
  final List adminAccounts;
  final List originalAdminAccounts; // Add the originalAdminAccounts list

  const AdminState({
    required this.status,
    required this.adminAccounts,
    required this.originalAdminAccounts, // Include originalAdminAccounts in the constructor
  });

  factory AdminState.initial() {
    return const AdminState(
      status: AdminFetchStatus.initial,
      adminAccounts: [],
      originalAdminAccounts: [], // Initialize originalAdminAccounts as empty
    );
  }

  @override
  List<Object> get props => [status, adminAccounts, originalAdminAccounts]; // Add originalAdminAccounts to props for equality check

  @override
  bool get stringify => true;

  AdminState copyWith({
    AdminFetchStatus? status,
    List? adminAccounts,
    List? originalAdminAccounts, // Add originalAdminAccounts to copyWith
  }) {
    return AdminState(
      status: status ?? this.status,
      adminAccounts: adminAccounts ?? this.adminAccounts,
      originalAdminAccounts: originalAdminAccounts ?? this.originalAdminAccounts, // Ensure originalAdminAccounts is updated
    );
  }
}
