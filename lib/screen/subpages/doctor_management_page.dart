// page1.dart
import 'package:flutter/material.dart';

class DoctorManagementPage extends StatelessWidget {
  const DoctorManagementPage({super.key});

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
                    'Doctor Management',
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
      body: const Center(
        child: Text(
            'This page is currently under development. We appreciate your patience as we work to bring you this new feature.',style: TextStyle(color: Color(0xff13322b))),
      ),
    );
  }
}
