// page1.dart
/*import 'package:flutter/material.dart';
import 'package:medicare_admin_remaster/screen/subpages/admin_interface/admin_interface.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        toolbarHeight: 140,
        flexibleSpace: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 20),
                  child: Text(
                    'Admin Page',
                    style: TextStyle(
                      color: Color(0xff222222),
                      fontFamily: "Roboto-M",
                      fontSize: 32,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Divider(
              thickness: 2,
              color: Color(0XFFB6B6B6),
            ),
          ],
        ),
      ),
      body: const Center(child: AdminInterface()),
    );
  }
}*/

import 'package:flutter/material.dart';
import 'package:medicare_admin_remaster/screen/subpages/admin_interface/admin_interface.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart'; // Import SpinKit package

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  bool isLoading = true; // Step 1: Initialize loading state

  @override
  void initState() {
    super.initState();
    _loadAdminInterface(); // Step 2: Start loading
  }

  Future<void> _loadAdminInterface() async {
    // Simulate a delay for loading (e.g., fetching data)
    await Future.delayed(Duration(seconds: 2)); // Adjust the duration as needed
    setState(() {
      isLoading = false; // Step 3: Update loading state
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        toolbarHeight: 140,
        flexibleSpace: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 20),
                  child: Text(
                    'Admin Page',
                    style: TextStyle(
                      color: Color(0xff222222),
                      fontFamily: "Roboto-M",
                      fontSize: 32,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Divider(
              thickness: 2,
              color: Color(0XFFB6B6B6),
            ),
          ],
        ),
      ),
      body: Center(
        child: isLoading // Step 4: Conditional loading
            ? const SpinKitCircle(
                color: Color(0xff13322B),
                size: 50.0,
              )
            : const AdminInterface(),
      ),
    );
  }
}
