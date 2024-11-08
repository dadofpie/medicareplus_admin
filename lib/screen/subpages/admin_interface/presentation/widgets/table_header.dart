import 'package:flutter/material.dart';

class AppHeaderTable extends StatelessWidget {
  const AppHeaderTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 26, bottom: 10, left: 20, right: 20),
      height: 42.5,
      width: double.infinity,
      decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          border: Border.all(
            color: Colors.grey,
            width: 2,
          )),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration:
                  BoxDecoration(border: Border.all(color: Colors.black)),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Admin Name',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration:
                  BoxDecoration(border: Border.all(color: Colors.black)),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'User Role',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration:
                  BoxDecoration(border: Border.all(color: Colors.black)),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Email Address',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration:
                  BoxDecoration(border: Border.all(color: Colors.black)),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Phone Number',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration:
                  BoxDecoration(border: Border.all(color: Colors.black)),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Status',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration:
                  BoxDecoration(border: Border.all(color: Colors.black)),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Action',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
