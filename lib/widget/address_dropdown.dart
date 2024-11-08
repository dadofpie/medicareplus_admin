import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';

class CustomDropdown<T> extends StatelessWidget {
  final List<T> items;
  final String Function(T item) itemAsString;
  final String hintText;
  final T? selectedItem;
  final ValueChanged<T?> onChanged;

  const CustomDropdown({
    Key? key,
    required this.items,
    required this.itemAsString,
    required this.hintText,
    this.selectedItem,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownSearch<T>(
      items: items,
      itemAsString: itemAsString,
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          filled: true,
          fillColor: Colors.white, // Background color of the input
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: const Color(0xff13322b).withOpacity(0.35),
              width: 2.0,
            ),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xff13322b)),
          ),
          hintText: hintText,
          hintStyle: TextStyle(
            color: const Color(0xff13322b).withOpacity(0.5), 
          ),
          suffixIconColor: const Color(0xff13322b)
        ),
      ),
      onChanged: onChanged,
      selectedItem: selectedItem,
      popupProps: PopupProps.menu(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
          cursorColor: const Color(0xff13322b),
          decoration: InputDecoration(
            hintText: 'Search...',
            filled: true,
            fillColor: Colors.white, // Set background color to white
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: const Color(0xff13322b).withOpacity(0.5),
                width: 2.0,
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(
                color: Color(0xff13322b), // Red color when focused
              ),
            ),
            hintStyle: TextStyle(
              color: const Color(0xff13322b).withOpacity(0.5), // Change hint text color
            ),
          ),
          style: const TextStyle(
            color: Color(0xff13322b), // Change text color in the search field
          ),
        ),
        // Customize the itemBuilder to change the tile color and text color
        itemBuilder: (context, item, isSelected) {
          return Container(
            color: Colors.white, // Set tile color to white
            padding: const EdgeInsets.all(8.0),
            child: Text(
              itemAsString(item),
              style: const TextStyle(
                color: Color(0xff13322b), // Set text color for dropdown items
              ),
            ),
          );
        },
        menuProps: const MenuProps(
          backgroundColor: Colors.white, // Popup background color
        ),
      ),
      dropdownBuilder: (context, selectedItem) {
        return Container(
          color: Colors.white,
          child: Text(
            selectedItem != null ? itemAsString(selectedItem) : hintText,
            style: const TextStyle(
              color: Color(0xff13322b), // Text color in the dropdown
            ),
          ),
        );
      },
    );
  }
}
