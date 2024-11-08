import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:medicare_admin_remaster/screen/subpages/admin_interface/presentation/bloc/admin/admin_bloc.dart';
import 'package:medicare_admin_remaster/screen/subpages/admin_interface/presentation/widgets/field_entry.dart';

class TableEntries extends StatelessWidget {
  const TableEntries({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: BlocBuilder<AdminBloc, AdminState>(
            builder: (context, state) {
              /*if (state.status == AdminFetchStatus.loading) {
                return Container(
                    padding: const EdgeInsets.only(top: 20),
                    width: double.infinity,
                    child: const Center(
              // Center the spinner when loading
                    child: SpinKitCircle(
                      color: Color(0xff13322B), // Change the color as needed
                      size: 50.0, // Adjust size as needed
                    ),
                  ));
              } else {*/
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...state.adminAccounts.map((el) => FieldEntry(
                          adminId:el['admin_id'].toString(),
                          fullName: "${el['last_name']}, ${el['first_name']}",
                          firstName: el['first_name'],
                          middleName: el['middle_name'],
                          lastName: el['last_name'],
                          status: el['status'].toString(),
                          emailAddress: el['email_address'].toString(),
                          phoneNumber: el['contact_no'] ?? 'N/A',
                          role: el['mp_admin_type_table']['admin_type'].toString(),
                          roleType: el['admin_type'].toString(),
                        ))
                  ],
                );
              //}
            },
          ),
        ),
      ),
    );
  }
}
