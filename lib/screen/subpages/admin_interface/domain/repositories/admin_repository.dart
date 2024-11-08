import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:medicare_admin_remaster/screen/subpages/admin_interface/core/errors/failure.dart';
import 'package:medicare_admin_remaster/screen/subpages/admin_interface/data/model/admin.dart';
import 'package:medicare_admin_remaster/screen/subpages/admin_interface/domain/entities/admin_entries_entity.dart';

class AdminRepository {
  Future<Either<Failure, AdminEntriesEntity>> fetchAllAdmins(
      String supabaseUrl, String supabaseKey) async {
    try {
      var res = await http.get(
        Uri.parse("https://medicareplus-api.vercel.app/api/admin/get_admin"),
        headers: {
          "Content-Type": "application/json",
          "supabase-url": supabaseUrl,
          "supabase-key": supabaseKey,
        },
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
        Uri.parse("https://medicareplus-api.vercel.app/api/admin/add_admin"),
        headers: {
          "Content-Type": "application/json",
          "supabase-url": "https://hsdwccwygehmawjdyzkr.supabase.co/",
          "supabase-key":
              "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhzZHdjY3d5Z2VobWF3amR5emtyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjcwNTExNTMsImV4cCI6MjA0MjYyNzE1M30.B9pE60Fnv91y2QfMWHeHYqg7ol6YhHmuftz-X5msXwk",
        },
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
