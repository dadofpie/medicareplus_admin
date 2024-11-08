import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medicare_admin_remaster/screen/subpages/admin_interface/presentation/bloc/admin/admin_bloc.dart';
import 'package:medicare_admin_remaster/screen/subpages/admin_interface/presentation/dialogs/add_admin_dialog.dart';
import 'package:medicare_admin_remaster/screen/subpages/admin_interface/presentation/widgets/table_entries.dart';
import 'package:medicare_admin_remaster/screen/subpages/admin_interface/presentation/widgets/table_header.dart';

class AdminInterface extends StatefulWidget {
  const AdminInterface({super.key});

  @override
  State<AdminInterface> createState() => _AdminInterfaceState();
}

class _AdminInterfaceState extends State<AdminInterface> {

  final TextEditingController _searchController = TextEditingController();
  String filterCriteria = '';
  String searchQuery = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    context.read<AdminBloc>().add(FetchAdminAccountsEvent());
     
      // Whenever the text changes, we dispatch a search event
      _searchController.addListener(() {
        searchQuery = _searchController.text;
        context.read<AdminBloc>().add(SearchAdminAccountsEvent(query: searchQuery, filterCriteria: filterCriteria));
      });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          width: 2,
          color: Colors.grey,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // IconButton(
                  //     onPressed: () {},
                  //     icon: const Icon(Icons.catching_pokemon)),
                   SizedBox(
                    width: 220,
                    height: 30,
                    child: TextField(
                      cursorColor: const Color(0xff13322b),
                      controller: _searchController,
                      readOnly: filterCriteria.isEmpty,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color:
                                Colors.black, // Set the outline color to black
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color.fromARGB(255, 0, 0,
                                0), // Outline color changes to green when focused
                          ),
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.black, // Set search icon color to black
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 8), // Align text
                      ),
                      style: const TextStyle(
                        fontSize: 12, // Set smaller font size
                        color: Colors.black, // Set text color to black
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  ElevatedButton(
                      onPressed: () {
                        _showAddAdminDialog(context);
                      },
                      style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    backgroundColor: const Color(
                                        0xff13322b), // Set button background color
                                  ),
                      child: const Text(
                        'Add Admin',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      )),
                ],
              ),
            ),
            //const AppHeaderTable(),
            Container(
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
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (filterCriteria == 'member') {
                            filterCriteria = ''; // Clear the filterCriteria (or set to null)
                            searchQuery = ''; // Optionally reset the search query
                            _searchController.text='';
                          } else {
                            filterCriteria = 'member'; // Set to 'member' if it's not already
                            searchQuery = ''; // Optionally reset the search query
                            _searchController.text='';
                          } // Reset the search query
                        });
                      },
                      child: Container(
                        height: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: filterCriteria=='member'?const Color(0xFF13322B):Colors.transparent,
                          border: Border.all(color: Colors.black)),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Admin Name',
                            style: TextStyle(
                              color: filterCriteria=='member'?const Color(0xFFFFFFFF): Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (filterCriteria == 'role') {
                            filterCriteria = ''; // Clear the filterCriteria (or set to null)
                            searchQuery = ''; // Optionally reset the search query
                            _searchController.text='';
                          } else {
                            filterCriteria = 'role'; // Set to 'member' if it's not already
                            searchQuery = ''; // Optionally reset the search query
                            _searchController.text='';
                          } // Reset the search query
                        });
                      },
                      child: Container(
                        height: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: filterCriteria=='role'?const Color(0xFF13322B):Colors.transparent,
                          border: Border.all(color: Colors.black)),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'User Role',
                            style: TextStyle(
                              color: filterCriteria=='role'?const Color(0xFFFFFFFF):Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (filterCriteria == 'email') {
                            filterCriteria = ''; // Clear the filterCriteria (or set to null)
                            searchQuery = ''; // Optionally reset the search query
                            _searchController.text='';
                          } else {
                            filterCriteria = 'email'; // Set to 'member' if it's not already
                            searchQuery = ''; // Optionally reset the search query
                            _searchController.text='';
                          } // Reset the search query
                        });
                      },
                      child: Container(
                        height: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: filterCriteria=='email'?const Color(0xFF13322B):Colors.transparent,
                          border: Border.all(color: Colors.black)),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Email Address',
                            style: TextStyle(
                              color: filterCriteria=='email'?const Color(0xFFFFFFFF):Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (filterCriteria == 'contact') {
                            filterCriteria = ''; // Clear the filterCriteria (or set to null)
                            searchQuery = ''; // Optionally reset the search query
                            _searchController.text='';
                          } else {
                            filterCriteria = 'contact'; // Set to 'member' if it's not already
                            searchQuery = ''; // Optionally reset the search query
                            _searchController.text='';
                          } // Reset the search query
                        });
                      },
                      child: Container(
                        height: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: filterCriteria=='contact'?const Color(0xFF13322B):Colors.transparent,
                          border: Border.all(color: Colors.black)),
                        child:  Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Phone Number',
                            style: TextStyle(
                              color: filterCriteria=='contact'?const Color(0xFFFFFFFF):Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (filterCriteria == 'status') {
                            filterCriteria = ''; // Clear the filterCriteria (or set to null)
                            searchQuery = ''; // Optionally reset the search query
                            _searchController.text='';
                          } else {
                            filterCriteria = 'status'; // Set to 'member' if it's not already
                            searchQuery = ''; // Optionally reset the search query
                            _searchController.text='';
                          } // Reset the search query
                        });
                      },
                      child: Container(
                        height: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: filterCriteria=='status'?const Color(0xFF13322B):Colors.transparent,
                          border: Border.all(color: Colors.black)),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Status',
                            style: TextStyle(
                              color: filterCriteria=='status'?const Color(0xFFFFFFFF): Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
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
            ),
            const TableEntries(),
          ],
        ),
      ),
    );
  }

  void _showAddAdminDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const AddAdminDialog();
      },
    );
  }
}
