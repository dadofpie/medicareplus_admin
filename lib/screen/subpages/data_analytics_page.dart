import 'package:flutter/material.dart';

class DataAnalyticsPage extends StatefulWidget {
  const DataAnalyticsPage({super.key});

  @override
  _DataAnalyticsPageState createState() => _DataAnalyticsPageState();
}

class _DataAnalyticsPageState extends State<DataAnalyticsPage> {
  String? selectedDate;

  Future<void> _selectDate(BuildContext context) async {
    // Show date picker dialog
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    // If a date was picked, update the selectedDate state
    if (picked != null && picked != DateTime.now()) {
      setState(() {
        selectedDate =
            "${picked.toLocal()}".split(' ')[0]; // Format date as 'yyyy-mm-dd'
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        automaticallyImplyLeading: false,
        toolbarHeight: 140,
        flexibleSpace: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 50), // Top spacing
            Row(
              mainAxisAlignment: MainAxisAlignment
                  .spaceBetween, // Space between text and button
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 20), // Add padding to the left
                  child: Text(
                    'Data Analytics',
                    style: TextStyle(
                      color: Color(0xff222222),
                      fontFamily: "Roboto-M",
                      fontSize: 32,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10), // Padding for dropdown
                      child: GestureDetector(
                        onTap: () =>
                            _selectDate(context), // Show date picker on tap
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors
                                .white, // Background color of the dropdown
                            border:
                                Border.all(color: Colors.grey), // Border color
                            borderRadius:
                                BorderRadius.circular(5), // Rounded corners
                          ),
                          child: Text(
                            selectedDate ??
                                'Select Date', // Show selected date or placeholder
                            style: const TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontFamily: 'Poppins-R'), // Text color
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          right: 20), // Add padding to the right of the button
                      child: SizedBox(
                        width: 200,
                        height: 50,
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            backgroundColor:
                                const Color(0xff13322b), // Button color
                            foregroundColor: Colors.white, // Text color
                            padding: const EdgeInsets.symmetric(
                                vertical: 8), // Button padding
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(10), // Button radius
                            ),
                          ),
                          child: const Text(
                            'Export',
                            style: TextStyle(
                                fontSize: 20,
                                fontFamily: "Poppins-R"), // Text size
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20), // Bottom spacing
            const Divider(
              thickness: 2, // Thickness of the divider
              color: Color(0XFFB6B6B6), // Color of the divider
            ),
          ],
        ),
      ),
      body: const Center(
        child: Text('Content goes here'), // Placeholder for body content
      ),
    );
  }
}
