import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:medicare_admin_remaster/shared/api.dart';
import 'package:medicare_admin_remaster/screen/subpages/admin_interface/core/errors/failure.dart';
import 'package:medicare_admin_remaster/screen/subpages/admin_interface/data/model/admin.dart';
import 'package:medicare_admin_remaster/screen/subpages/admin_interface/domain/entities/admin_entries_entity.dart';

class AdminRepository {
  Future<Either<Failure, AdminEntriesEntity>> fetchAllAdmins(
      String supabaseUrl, String supabaseKey) async {
    try {
      var res = await http.get(
        Uri.parse(adminEndpoint('get_admin')),
        headers: buildApiHeaders(),
      );

      List adminList = json.decode(res.body)['admin_list'];

      return Right(AdminEntriesEntity(entries: adminList));
    } catch (err) {
      return Left(ServerFailure(err.toString()));
    }
  }

  Future<Either<Failure, Admin>> addAdminAccount(
      {adminType,
      departmentId,
      fName,
      mName,
      lName,
      email,
      password,
      contactNo}) async {
    try {
      var res = await http.post(
        Uri.parse(adminEndpoint('add_admin')),
        headers: buildApiHeaders(),
        body: json.encode({
          "admin_type": adminType,
          "department_id": departmentId,
          "fname": fName,
          "mname": mName,
          "lname": lName,
          "email": email,
          "password": password,
          "contact_no": contactNo
        }),
      );

      return Right(Admin(
          adminType: adminType,
          departmentId: departmentId,
          fName: fName,
          mName: mName,
          lName: lName,
          email: email,
          password: password,
          contactNo: contactNo));
    } catch (err) {
      return Left(ServerFailure(err.toString()));
    }
  }
}
