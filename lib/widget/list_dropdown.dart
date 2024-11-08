/*import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:medicare_admin_remaster/class/status_item.dart';

class CustomListDropdownFormField extends StatelessWidget {
  final String label; // Label text
  final TextStyle labelStyle; // Label text style
  final List<StatusItem> items; // List of StatusItem
  final TextEditingController controller; // Controller to manage text
  final ValueChanged<StatusItem?> onChanged; // Callback when item changes

  const CustomListDropdownFormField({
    Key? key,
    required this.label,
    required this.labelStyle,
    required this.items,
    required this.controller,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownSearch<StatusItem>(
      items: items,
      itemAsString: (item) => item.status, // Display 'status' as the label
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: const Color(0xff13322b).withOpacity(0.35),
              width: 2.0,
            ),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xff13322b)),
          ),
          hintText: label,
          hintStyle: TextStyle(
            color: label=='Please select role type'?Colors.red.withOpacity(0.5):const Color(0xff13322b).withOpacity(0.5),
          ),
          suffixIconColor: const Color(0xff13322b),
        ),
      ),
      onChanged: (StatusItem? newItem) {
        // Update the controller's text when the item changes
        controller.text = newItem?.id.toString() ?? '';
        // Notify parent widget of the change
        onChanged(newItem);
      },
      selectedItem: _getSelectedItem(),
      popupProps: PopupProps.menu(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
          cursorColor: const Color(0xff13322b),
          decoration: InputDecoration(
            hintText: 'Search...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: const Color(0xff13322b).withOpacity(0.5),
                width: 2.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color:label=='Please select role type'?Colors.red.withOpacity(0.5): const Color(0xff13322b),
              ),
            ),
            hintStyle: TextStyle(
              color: const Color(0xff13322b).withOpacity(0.5),
            ),
          ),
          style: const TextStyle(
            color: Color(0xff13322b),
          ),
        ),
        itemBuilder: (context, item, isSelected) {
          return Container(
            color: Colors.white,
            padding: const EdgeInsets.all(8.0),
            child: Text(
              item.status, // Display 'status' from StatusItem
              style: const TextStyle(
                color: Color(0xff13322b),
              ),
            ),
          );
        },
        menuProps: const MenuProps(
          backgroundColor: Colors.white,
        ),
      ),
      dropdownBuilder: (context, selectedItem) {
        return Container(
          color: Colors.white,
          child: Text(
            selectedItem != null ? selectedItem.status : label, // Show status if selected
            style: const TextStyle(
              color: Color(0xff13322b),
              fontSize: 14
            ),
          ),
        );
      },
    );
  }

  // This method helps to get the selected item based on the controller's value (id).
 /* StatusItem _getSelectedItem() {
    // Try to find the StatusItem that matches the controller's value (id).
    final selectedId = int.tryParse(controller.text);
    return items.firstWhere(
      (item) => item.id == selectedId,
      orElse: () => items.first, // Default to the first item if none is found
    );
  }*/

  StatusItem? _getSelectedItem() {
  // Check if controller.text is empty
    if (controller.text.isEmpty) {
      return null; // Return null if no value is entered
    }

    // Try to parse the selectedId from controller.text
    final selectedId = int.tryParse(controller.text);

    // If selectedId is valid, try to find the matching StatusItem
    if (selectedId != null) {
      // Look for the StatusItem matching the parsed id
      return items.firstWhere(
        (item) => item.id == selectedId, 
        orElse: () => items.first, // Return null if no matching item is found
      );
    }

    // If the parsing failed, return null
    return null;
  }
}
*/


import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:medicare_admin_remaster/class/status_item.dart';

class CustomListDropdownFormField extends StatefulWidget {
  final String label; // Label text
  final TextStyle labelStyle; // Label text style
  final List<StatusItem> items; // List of StatusItem
  final TextEditingController controller; // Controller to manage text
  final ValueChanged<StatusItem?> onChanged; // Callback when item changes

  const CustomListDropdownFormField({
    Key? key,
    required this.label,
    required this.labelStyle,
    required this.items,
    required this.controller,
    required this.onChanged,
  }) : super(key: key);

  @override
  _CustomListDropdownFormFieldState createState() => _CustomListDropdownFormFieldState();
}

class _CustomListDropdownFormFieldState extends State<CustomListDropdownFormField> {
  StatusItem? _selectedItem; // Variable to hold the currently selected item

  @override
  void initState() {
    super.initState();
    _selectedItem = _getSelectedItem(); // Initialize the selected item when the widget is created
  }

  // Method to get the selected item based on the controller's value (id)
  StatusItem? _getSelectedItem() {
    // Check if controller.text is empty
    if (widget.controller.text.isEmpty) {
      return null; // Return null if no value is entered
    }

    // Try to parse the selectedId from controller.text
    final selectedId = int.tryParse(widget.controller.text);

    // If selectedId is valid, try to find the matching StatusItem
    if (selectedId != null) {
      // Look for the StatusItem matching the parsed id
      return widget.items.firstWhere(
        (item) => item.id == selectedId, 
        orElse: () => widget.items.first, // Default to the first item if no match
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownSearch<StatusItem>(
      items: widget.items,
      itemAsString: (item) => item.status, // Display 'status' as the label
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: widget.controller.text.isEmpty?(widget.label == 'Please select role type'
                    ? Colors.red.withOpacity(0.25)
                    :const Color(0xff13322b).withOpacity(0.35)):const Color(0xff13322b).withOpacity(0.35),
              width: 2.0,
            ),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xff13322b)),
          ),
          hintText: widget.label,
          hintStyle: TextStyle(
            color: widget.label == 'Please select role type'
                ? Colors.red.withOpacity(0.5)
                : const Color(0xff13322b).withOpacity(0.5),
          ),
          suffixIconColor: const Color(0xff13322b),
        ),
      ),
      onChanged: (StatusItem? newItem) {
        setState(() {
          _selectedItem = newItem; // Update the selected item in the state
          widget.controller.text = newItem?.id.toString() ?? ''; // Update the controller's text
        });

        // Notify parent widget of the change
        widget.onChanged(newItem);
      },
      selectedItem: _selectedItem,
      popupProps: PopupProps.menu(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
          cursorColor: const Color(0xff13322b),
          decoration: InputDecoration(
            hintText: 'Search...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: const Color(0xff13322b).withOpacity(0.5),
                width: 2.0,
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(
                color:  const Color(0xff13322b),
              ),
            ),
            hintStyle: TextStyle(
              color: const Color(0xff13322b).withOpacity(0.5),
            ),
          ),
          style: const TextStyle(
            color: Color(0xff13322b),
          ),
        ),
        itemBuilder: (context, item, isSelected) {
          return Container(
            color: Colors.white,
            padding: const EdgeInsets.all(8.0),
            child: Text(
              item.status, // Display 'status' from StatusItem
              style: const TextStyle(
                color: Color(0xff13322b),
              ),
            ),
          );
        },
        menuProps: const MenuProps(
          backgroundColor: Colors.white,
        ),
      ),
      dropdownBuilder: (context, selectedItem) {
        return Container(
          color: Colors.white,
          child: Text(
            selectedItem != null ? selectedItem.status : widget.label, // Show status if selected
            style:  TextStyle(
              color: widget.controller.text.isEmpty?(widget.label == 'Please select role type'
                    ? Colors.red.withOpacity(0.5):const Color(0xff13322b)):const Color(0xff13322b),
              fontSize: 14,
            ),
          ),
        );
      },
    );
  }
}
