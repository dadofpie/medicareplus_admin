import 'package:dartz/dartz.dart';
import 'package:medicare_admin_remaster/screen/subpages/admin_interface/core/errors/failure.dart';
import 'package:medicare_admin_remaster/screen/subpages/admin_interface/core/usecases.dart';
import 'package:medicare_admin_remaster/screen/subpages/admin_interface/domain/entities/admin_entries_entity.dart';
import 'package:medicare_admin_remaster/screen/subpages/admin_interface/domain/repositories/admin_repository.dart';

class FetchAllAdmin extends UseCase<AdminEntriesEntity, AdminEntriesParams> {
  final AdminRepository _adminEntriesRepository;

  FetchAllAdmin({required AdminRepository adminEntriesRepository})
      : _adminEntriesRepository = adminEntriesRepository;

  @override
  Future<Either<Failure, AdminEntriesEntity>> call(
      AdminEntriesParams params) async {
    return await _adminEntriesRepository.fetchAllAdmins(
      params.supabaseUrl,
      params.supabaseKey,
    );
  }
}

class AdminEntriesParams {
  final String supabaseKey;
  final String supabaseUrl;

  AdminEntriesParams({required this.supabaseKey, required this.supabaseUrl});
}
