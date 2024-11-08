import 'package:flutter/material.dart';
import 'package:medicare_admin_remaster/screen/subpages/admin_interface/presentation/dialogs/edit_admin_dialog.dart';

class FieldEntry extends StatelessWidget {
  FieldEntry(
      {super.key,
      required this.fullName,
      required this.firstName,
      required this.middleName,
      required this.lastName,
      required this.status,
      required this.emailAddress,
      required this.phoneNumber,
      required this.role,
      required this.roleType,
      required this.adminId});
  final String fullName;
  final String firstName;
  final String middleName;
  final String lastName;
  final String status;
  final String emailAddress;
  final String phoneNumber;
  final String role;
  final String adminId;
  final String roleType;
  final TextEditingController ecivilStatusController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Text(
                          fullName,
                          style: const TextStyle(
                            color: Colors.black,
                          ),
                        ))),
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Text(
                          role,
                          style: const TextStyle(
                            color: Colors.black,
                          ),
                        ))),
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Text(
                          emailAddress,
                          style: const TextStyle(
                            color: Colors.black,
                          ),
                        ))),
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Text(
                          phoneNumber,
                          style: const TextStyle(
                            color: Colors.black,
                          ),
                        ))),
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Text(
                          status,
                          style: const TextStyle(
                            color: Colors.black,
                          ),
                        ))),
                Expanded(child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit), // Edit icon
                      onPressed: () {
                        //setState(() {});
                        _showEditAdminDialog(context);
                      },
                      tooltip: 'Edit', // Optional tooltip
                    )
                  ],
                ))
              ],
            ),
          ),
          const Divider(
            height: 1,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }


  void _showEditAdminDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditAdminDialog(
          fname: firstName,
          mname: middleName,
          lname: lastName,
          email: emailAddress,
          contact: phoneNumber,
          role: roleType,
          status: status,
          id: adminId,
        );
      },
    );
  }
}
