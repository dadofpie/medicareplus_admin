// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:medicare_admin_remaster/screen/subpages/admin_interface/core/errors/failure.dart';
import 'package:medicare_admin_remaster/screen/subpages/admin_interface/domain/entities/admin_entries_entity.dart';
import 'package:medicare_admin_remaster/screen/subpages/admin_interface/domain/usecases/fetch_all_admin.dart';

part 'admin_event.dart';
part 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final FetchAllAdmin fetchAllAdmin;
  AdminBloc({required this.fetchAllAdmin}) : super(AdminState.initial()) {
    on<FetchAdminAccountsEvent>(_fetchAdminAccounts);
    on<SearchAdminAccountsEvent>(_searchAdminAccounts);
  }

  FutureOr<void> _fetchAdminAccounts(
      FetchAdminAccountsEvent event, Emitter<AdminState> emit) async {
    emit(state.copyWith(status: AdminFetchStatus.loading));
    final Either<Failure, AdminEntriesEntity> result = await fetchAllAdmin.call(
        AdminEntriesParams(
            supabaseKey: "https://hsdwccwygehmawjdyzkr.supabase.co/",
            supabaseUrl:
                "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhzZHdjY3d5Z2VobWF3amR5emtyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjcwNTExNTMsImV4cCI6MjA0MjYyNzE1M30.B9pE60Fnv91y2QfMWHeHYqg7ol6YhHmuftz-X5msXwk"));
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AdminFetchStatus.error,
        ),
      ),
      (result) => emit(
        state.copyWith(
          status: AdminFetchStatus.success,
          adminAccounts: result.entries,
          originalAdminAccounts: result.entries,
        ),
      ),
    );
  }


  FutureOr<void> _searchAdminAccounts(
  SearchAdminAccountsEvent event, 
  Emitter<AdminState> emit
) async {
  final query = event.query.toLowerCase();
  final filterCriteria = event.filterCriteria;

  print('Search query: $query'); // Debug log to see what the search query is

  // If the query is empty, return the original admin accounts list
  if (query.isEmpty) {
      print('Resetting to original admin accounts');
      emit(state.copyWith(
        status: AdminFetchStatus.success,
        adminAccounts: state.originalAdminAccounts,  // Reset to original list
      ));
      return;
    }

  // If there is a query, filter the admin accounts
  if(filterCriteria.isNotEmpty){
    final filteredAccounts = state.originalAdminAccounts.where((admin) {
      if (filterCriteria == 'member') {
        final firstName = (admin['first_name'] as String?)?.toLowerCase() ?? '';
        final lastName = (admin['last_name'] as String?)?.toLowerCase() ?? '';
        return firstName.contains(query) || lastName.contains(query);
      } else if (filterCriteria == 'role') {
        final role = admin['mp_admin_type_table']['admin_type'].toString() ;
        return role.contains(query);
      }else if (filterCriteria == 'email') {
        final email = admin['email_address'].toString() ;
        return email.contains(query);
      } else if (filterCriteria == 'contact') {
        final contact = admin['contact_no'].toString();
        return contact.contains(query);
      } else if (filterCriteria == 'status') {
        final userStatus = admin['status'];
        final statusPrefix = userStatus.substring(0, 3).toLowerCase();
        return statusPrefix.contains(query);
      } else {
        // Handle other filters similarly
        return false;
      }
    }).toList();
    
    print('Filtered accounts count: ${filteredAccounts.length}'); // Debug log to check how many items are filtered

    emit(state.copyWith(
      status: AdminFetchStatus.success,
      adminAccounts: filteredAccounts,
    ));
  }

}


}
