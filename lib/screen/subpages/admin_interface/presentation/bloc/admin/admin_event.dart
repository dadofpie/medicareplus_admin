part of 'admin_bloc.dart';

sealed class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object> get props => [];
}

class FetchAdminAccountsEvent extends AdminEvent {}

class CreateAdminAccountEvent extends AdminEvent {}


// Add this to admin_event.dart
class SearchAdminAccountsEvent extends AdminEvent {
  final String query;
  final String filterCriteria;

  const SearchAdminAccountsEvent({required this.query, required this.filterCriteria});

  @override
  List<Object> get props => [query, filterCriteria];
}
