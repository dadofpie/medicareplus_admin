import 'package:flutter/material.dart';

class BirthdayPicker extends StatefulWidget {
  final ValueChanged<DateTime?> onDateSelected; // Callback to pass the selected date

  const BirthdayPicker({Key? key, required this.onDateSelected}) : super(key: key);

  @override
  BirthdayPickerState createState() => BirthdayPickerState(); // Remove underscore
}

class BirthdayPickerState extends State<BirthdayPicker> {
  DateTime? _birthday;
  String? errorMessage; // Variable to hold the error message

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xff13322b)), // Outline color
          borderRadius: BorderRadius.circular(5), // Radius
        ),
        child: GestureDetector(
          onTap: () {
            _selectDate(context);
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 11, 0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  errorMessage ?? (_birthday != null ? "${_birthday?.toLocal()}".split(' ')[0] : "Birthday (yyyy / mm / dd)"),
                  style: TextStyle(
                    color: errorMessage != null ? Colors.red.withOpacity(0.5) : const Color(0xff13322b),
                    fontSize: 15.0,
                  ),
                ),
                const SizedBox(height: 4), // Space between label and date
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _birthday = picked;
        errorMessage = null; // Clear error message when date is selected
      });
      widget.onDateSelected(picked); // Pass the selected date to the parent
    } else {
      setState(() {
        errorMessage = 'Please select a birthday'; // Set error message
        widget.onDateSelected(null); // Pass null to indicate no date selected
      });
    }
  }

  String? validate() {
    if (_birthday == null) {
      setState(() {
        errorMessage = 'Please select a birthday'; // Set error message
      });
      return errorMessage;
    }
    return null; // No error
  }
}
