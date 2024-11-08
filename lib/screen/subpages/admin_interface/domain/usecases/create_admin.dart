import 'package:dartz/dartz.dart';
import 'package:medicare_admin_remaster/screen/subpages/admin_interface/core/errors/failure.dart';
import 'package:medicare_admin_remaster/screen/subpages/admin_interface/core/usecases.dart';
import 'package:medicare_admin_remaster/screen/subpages/admin_interface/data/model/admin.dart';
import 'package:medicare_admin_remaster/screen/subpages/admin_interface/domain/repositories/admin_repository.dart';

class CreateAdmin extends UseCase<Admin, CreateAdminParams> {
  final AdminRepository adminRepository;

  CreateAdmin({required this.adminRepository});

  @override
  Future<Either<Failure, Admin>> call(CreateAdminParams params) async {
    return await adminRepository.addAdminAccount(
        adminType: params.adminType,
        departmentId: params.departmentId,
        fName: params.fName,
        mName: params.mName,
        lName: params.lName,
        email: params.email,
        contactNo: params.contactNo,
        password: params.password);
  }
}

class CreateAdminParams {
  final String adminType;
  final String departmentId;
  final String fName;
  final String mName;
  final String lName;
  final String email;
  final String password;
  final String contactNo;

  CreateAdminParams(
      {required this.adminType,
      required this.departmentId,
      required this.fName,
      required this.mName,
      required this.lName,
      required this.email,
      required this.password,
      required this.contactNo});
}
