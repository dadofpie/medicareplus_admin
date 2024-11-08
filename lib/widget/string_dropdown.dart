import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:medicare_admin_remaster/class/status_item.dart';

class CustomStringDropdownFormField extends StatelessWidget {
  final String label; // Label text
  final TextStyle labelStyle; // Label text style
  final List<StringType> items; // List of StatusItem
  final TextEditingController controller; // Controller to manage text
  final ValueChanged<StringType?> onChanged; // Callback when item changes

  const CustomStringDropdownFormField({
    Key? key,
    required this.label,
    required this.labelStyle,
    required this.items,
    required this.controller,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownSearch<StringType>(
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
            color: const Color(0xff13322b).withOpacity(0.5),
          ),
          suffixIconColor: const Color(0xff13322b),
        ),
      ),
      onChanged: (StringType? newItem) {
        // Update the controller's text when the item changes
        controller.text = newItem?.id ?? '';
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
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(
                color: Color(0xff13322b),
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
  StringType? _getSelectedItem() {
    // Try to find the StatusItem that matches the controller's value (id).
    if (controller.text.isEmpty) {
      return null; // Return null if no value is entered
    }
    final selectedId = controller.text;
    if (selectedId != null) {
      return items.firstWhere(
        (item) => item.id == selectedId,
        orElse: () => items.first, // Default to the first item if none is found
      );
    }
    return null;
  }
}

