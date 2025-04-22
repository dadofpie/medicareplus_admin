import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:medicare_admin_remaster/bloc/auth/auth_bloc.dart';
import 'package:medicare_admin_remaster/class/loa_request.dart';
import 'package:medicare_admin_remaster/screen/login_page.dart';
import 'package:medicare_admin_remaster/shared/api.dart';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http_parser/http_parser.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class LoaRequestPage extends StatefulWidget {
  const LoaRequestPage({super.key});

  @override
  _LoaRequestPageState createState() => _LoaRequestPageState();
}

class _LoaRequestPageState extends State<LoaRequestPage> {
  String? selectedDate;
  bool isAscending = true;
  bool isLoading = true;
  bool isReject = false;
  bool isApproved = false;
  int pendingCount = 0;
  int approvedCount = 0;
  int rejectCount = 0;
  int cancelledCount = 0;
  Stream<List<Map<String, dynamic>>>? _members;
  List<Map<String, dynamic>> requests = [];
  List<Map<String, dynamic>> filteredRequest = [];
  List<PlatformFile>? _selectedFiles;
  bool showPendingOnly = false; // State variable to track filter status
  int activeButtonIndex = -1; // Initialize to -1 for no active button1
  late ApiService _apiService;
  String statusFilter = '';
  String message = '';
  String searchQuery = '';
  String filterCriteria='';
  String formattedDate='';
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _apiService = ApiService('https://medicareplus-api.vercel.app'); // Replace with your actual API URL1
    _members = _apiService.streamAllRequest(supabaseUrl, supabaseKey);
    // Initialize the service with your endpoint
  }

  @override
  void dispose() {
    supabase.Supabase.instance.client.removeAllChannels();
    super.dispose();
  }


  void filterByStatus(String status) {
    setState(() {
      statusFilter = status; // Update the filter
    });
  }

  String formatDate(DateTime date) {
    final DateFormat formatter = DateFormat('dd-MM-yyyy HH:mm');
    return formatter.format(date);
  }


  Future<void> logUserAction(
   String userId,
   String tableName,
   String actionType,
   String actionDetails,
  ) async {
    final uri = Uri.parse('https://medicareplus-api.vercel.app/api/admin/record_action');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'supabase-url': supabaseUrl,
          'supabase-key': supabaseKey,
        },
        body: jsonEncode({
          'user_id': userId,
          'table_name': tableName,
          'action_type': actionType,
          'action_details': actionDetails,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Action logged: ${data['message']}');
      } else {
        print('Failed to log action. Status code: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('Error logging action: $e');
    }
  }

  void countStatuses(List<Map<String, dynamic>> members) {
    // Reset counts
    pendingCount = 0;
    approvedCount = 0;
    rejectCount = 0;
    cancelledCount=0;
    // Count statuses
    for (var member in members) {
      switch (member['status']) {
        case 'pending':
          pendingCount++;
          break;
        case 'approved':
          approvedCount++;
          break;
        case 'rejected':
          rejectCount++;
          break;
        case 'cancelled':
          cancelledCount++;
          break;
      }
    }
  }

  /*Future<void> _pickFiles(StateSetter setState) async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          if (result.files.isNotEmpty) {
            _selectedFiles = result.files; // Assign selected files
          } else {
            _selectedFiles = []; // Allow _selectedFiles to be empty (null)
          }
        });
      }
    } catch (e) {
      print('Error picking files: $e');
    }
  }
  Future<void> _pickFiles(StateSetter setState) async {
  try {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf'], // Allow only PDF files
    );
    
    if (result != null && result.files.isNotEmpty) {
      // Check for non-PDF files
      final nonPdfFiles = result.files.where((file) => file.extension != 'pdf').toList();
      if (nonPdfFiles.isNotEmpty) {
        // Show a message if any non-PDF files are selected
        _showMessage("Please select only PDF files.","Non-PDF files detected");
      } else {
        // Assign selected PDF files
        setState(() {
          _selectedFiles = result.files;
        });
      }
    } else {
      setState(() {
        _selectedFiles = []; // Allow _selectedFiles to be empty
      });
    }
  } catch (e) {
    print('Error picking files: $e');
  }
}*/

Future<void> _pickFiles(StateSetter setState) async {
  try {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf'], // Allow only PDF files
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFiles = result.files; // Assign selected files
      });
    } else {
      setState(() {
        _selectedFiles = null; // Allow _selectedFiles to be empty
      });
    }
  } catch (e) {
    print('Error picking files: $e');
  }
}


  Future<String> _lockedRequest(String lockedBy, String requestId) async {
  String url = '$apiUrl/locked_request_form';

  final Map<String, dynamic> data = {
    'locked_by': lockedBy,
    'request_id': requestId,
  };

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'supabase-url': supabaseUrl,
        'supabase-key': supabaseKey,
      },
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      await logUserAction(lockedBy,'mp_form_request_table','Update','Locked application # $requestId');
      final responseData = json.decode(response.body);
      print('Request is locked: ${responseData['message']}');
      
      // Access the locked_by value returned from the server
      String lockedByValue = responseData['locked_by'].toString();
      print('locked_by value: $lockedByValue');
      
      // Return the locked_by value
      return lockedByValue;
    } else {
      await logUserAction(lockedBy,'mp_form_request_table','Update','Error on locking application # $requestId');
      final errorData = json.decode(response.body);
      print('Error: ${errorData['error']}');
      // Return an error message or some default value
      return 'Error: ${errorData['error']}';
    }
  } catch (error) {
    print('Unexpected error: $error');
    // Return a default error message
    return 'Unexpected error occurred';
  }
}



Future<String> _getName(String lockedBy) async {
  String url = '$apiUrl/get_name';

  final Map<String, dynamic> data = {
    'locked_by': lockedBy
  };

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'supabase-url': supabaseUrl,
        'supabase-key': supabaseKey,
      },
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('Request is locked: ${responseData['message']}');
      
      // Access the locked_by value returned from the server
      String lockedByValue = responseData['locked_by'].toString();
      print('locked_by value: $lockedByValue');
      
      // Return the locked_by value
      return lockedByValue;
    } else {
      final errorData = json.decode(response.body);
      print('Error: ${errorData['error']}');
      // Return an error message or some default value
      return 'Error: ${errorData['error']}';
    }
  } catch (error) {
    print('Unexpected error: $error');
    // Return a default error message
    return 'Unexpected error occurred';
  }
}


/*Future<void> _releasedRequest(String lockedBy, String requestId) async {
  String url = '$apiUrl/released_request_form';

  final Map<String, dynamic> data = {
    'locked_by': lockedBy,
    'request_id': requestId,
  };

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'supabase-url': supabaseUrl,
        'supabase-key': supabaseKey,
      },
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('Request is locked: ${responseData['message']}');
      
    } else {
      final errorData = json.decode(response.body);
      print('Error: ${errorData['error']}');
    }
  } catch (error) {
    print('Unexpected error: $error');
  }
}*/

Future<bool> _releasedRequest(String lockedBy, String requestId) async {
  String url = '$apiUrl/released_request_form';

  final Map<String, dynamic> data = {
    'locked_by': lockedBy,
    'request_id': requestId,
  };

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'supabase-url': supabaseUrl,
        'supabase-key': supabaseKey,
      },
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      await logUserAction(lockedBy,'mp_form_request_table','Update','Released application # $requestId');
      final responseData = json.decode(response.body);
      print('Request is locked: ${responseData['message']}');
      return true;  // Request processed successfully
    } else {
      await logUserAction(lockedBy,'mp_form_request_table','Update','Error on releasing application # $requestId');
      final errorData = json.decode(response.body);
      print('Error: ${errorData['error']}');
      return false;  // Error processing the request
    }
  } catch (error) {
    print('Unexpected error: $error');
    return false;  // Error occurred during the request
  }
}




  Future<bool> _updateRequestForm(String requestId, String status, String name,
      String userId, String bucketName, String rejectReason) async {
    var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://medicareplus-api.vercel.app/api/admin/update_request_form'));

    request.headers.addAll({
      'supabase-url': supabaseUrl,
      'supabase-key': supabaseKey,
    });

    request.fields['request_id'] = requestId; // Set your request ID
    request.fields['form_status'] = status; // Set your form status
    request.fields['updated_by'] = userId; // Set who updated it
    request.fields['date_update'] = DateTime.now().toIso8601String(); // Current date
    request.fields['bucket_name'] = bucketName; // Set your bucket name
    request.fields['user_name'] = name; // Set the user name
    request.fields['reject_reason'] = rejectReason;

    // Check if we have selected files and process them
    if (bucketName.isNotEmpty) {
      for (var file in _selectedFiles!) {
        // Check if we're running in the web environment
        // Create a File instance from PlatformFile
        final fileBytes = await _getFileBytes(file);

        // Add the file to the request
        request.files.add(http.MultipartFile.fromBytes(
          'files',
          fileBytes,
          filename: file.name, // Use the name from PlatformFile
        ));
      }
    }

    /*try {
      var response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final data = json.decode(responseData);
        print('Update successful: $data');
        return true;
      } else {
        print('Update failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error occurred while updating: $e');
      return false;
    }*/
    try {
      var response = await request.send().timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final data = json.decode(responseData);
        print('Update successful: $data');
        return true;
      } else {
        // Handle specific error cases based on status code or response
        final responseData = await response.stream.bytesToString();
        final data = json.decode(responseData);

        if (response.statusCode == 403) {
          // Handle locked request
          await logUserAction(userId,'mp_form_request_table','Update','Error $requestId');
          print('Update failed: ${data['error']}');
          // Show a message to the user about the locked request
          setState(() {
            message = data['error'];
          });
        } else {
          await logUserAction(userId,'mp_form_request_table','Update','Error $requestId');
          print('Update failed: ${response.statusCode}');
        }
        return false;
      }
    } on TimeoutException catch (_) {
      // Handle timeout (e.g., show a timeout message)
      setState(() {
        Navigator.of(context).popUntil((route) => route.isFirst);
        _showMessage('The request timed out. Please try again later.',
          'Connection timeout!');  
      });
      return false;
      
    } catch (e) {
      print('Error occurred while updating: $e');
      return false;
    }
  }

  Future<Uint8List> _getFileBytes(PlatformFile file) async {
    final reader = html.FileReader();
    final completer = Completer<Uint8List>();

    // Create a Blob from the file's bytes
    final blob = html.Blob(
        [file.bytes]); // Assuming 'file.bytes' gives you the byte data

    reader.readAsArrayBuffer(blob);
    reader.onLoadEnd.listen((e) {
      completer.complete(reader.result as Uint8List);
    });

    return completer.future;
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != DateTime.now()) {
      setState(() {
        selectedDate =
            "${picked.toLocal()}".split(' ')[0]; // Format date as 'yyyy-mm-dd'
      });
    }
  }

  void _sortTable(String column) {
    setState(() {
      isAscending = !isAscending;
      requests.sort((a, b) {
        if (isAscending) {
          return a[column].compareTo(b[column]);
        } else {
          return b[column].compareTo(a[column]);
        }
      });
    });
  }

  void _changeStatus(int index, String? newStatus) {
    if (newStatus != null) {
      setState(() {
        requests[index]['status'] = newStatus;
      });
    }
  }

  void _deleteRequest(int index) {
    setState(() {
      requests.removeAt(index);
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      searchQuery = value.toLowerCase();
    });
  }

  void _showMessage(String message, String title) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
              side: const BorderSide(color: Color(0xff13322b), width: 2)),
          title: Center(
              child: Text(
            title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xff13322b)),
          )),
          content: Text(message,
              style: const TextStyle(fontSize: 16, color: Color(0xff13322b))),
          actions: <Widget>[
            TextButton(
              child: const Text("OK",
                  style: TextStyle(fontSize: 16, color: Color(0xff13322b))),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        automaticallyImplyLeading: false,
        toolbarHeight: 140,
        flexibleSpace: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 20),
                  child: Text(
                    'LOA Requests',
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
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthInitial) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
              (route) => false,
            );
          }
        },
        builder: (context, authState) {
          if (authState is AuthLoading) {
            return const Center(
              // Center the spinner when loading
              child: SpinKitCircle(
                color: Color(0xff13322B), // Change the color as needed
                size: 50.0, // Adjust size as needed
              ),
            );
          } else if (authState is AuthSuccess) {
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: _members,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
              // Center the spinner when loading
                    child: SpinKitCircle(
                      color: Color(0xff13322B), // Change the color as needed
                      size: 50.0, // Adjust size as needed
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                requests = snapshot.data ?? []; // Use the data from the snapshot
                  
                filteredRequest = requests;

                filteredRequest = statusFilter.isEmpty
                    ? requests
                    : requests
                        .where((request) => request['status'] == statusFilter)
                        .toList();

                  if(filterCriteria==''){
                    filteredRequest = filteredRequest;/*.where((request) {
                    final otherField1 = request['patient_fname']?.toLowerCase() ?? '';
                    final otherField2 = request['patient_lname']?.toLowerCase() ?? '';
                    final otherField3 = request['request_id']?.toString().toLowerCase() ?? '';
                    final email = request['patient_email']?.toLowerCase() ?? '';
                    final otherField4 = request['form_type']?.toLowerCase() ?? '';
                    

                    return otherField3.contains(searchQuery) ||
                        otherField1.contains(searchQuery) ||
                        otherField2.contains(searchQuery) ||
                        otherField4.contains(searchQuery) ||
                        email.contains(searchQuery);
                  }).toList();*/
                  }else{
                    
                    filteredRequest = filteredRequest.where((request) {
                      if (filterCriteria == 'member') {
                        // Filter by first name or last name
                        final firstName = request['patient_fname']?.toLowerCase() ?? '';
                        final lastName = request['patient_lname']?.toLowerCase() ?? '';
                        return firstName.contains(searchQuery) || lastName.contains(searchQuery);
                      }else if(filterCriteria == 'loa_no'){
                        final loa = request['request_id']?.toString().toLowerCase() ?? '';
                        return loa.contains(searchQuery);
                      }else if(filterCriteria == 'email'){
                        final email = request['patient_email']?.toLowerCase() ?? '';
                        return email.contains(searchQuery);
                      }else if(filterCriteria == 'date'){
                        String dateCreatedString = request['date_created'];
                        DateTime dateCreated = DateTime.parse(dateCreatedString);
                        formattedDate = formatDate(dateCreated);
                        final dateRequest = formattedDate.toLowerCase() ?? '';
                        return dateRequest.contains(searchQuery);
                      }else if(filterCriteria == 'request_type'){
                        final requestType = request['form_type']?.toLowerCase() ?? '';
                        return requestType.contains(searchQuery);
                      }else{
                        return false;
                      }
                    }).toList();
                  }
                
                countStatuses(requests);

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey, // Outline color
                        width: 2.0, // Outline width
                      ),
                      borderRadius:
                          BorderRadius.circular(20.0), // Outline radius
                    ),
                    child: Column(
                      children: [
                        // Row for the four cards

                        const SizedBox(
                            height:
                                20), // Add space between cards and other content

                        // Row for custom text and search bar
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 10, bottom: 15, right: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(
                                    8.0), // Padding around the text
                                child: Text(
                                  '', // Replace with your desired text
                                  style: TextStyle(
                                      fontSize:
                                          20, // Adjust the font size as needed
                                      fontWeight: FontWeight.bold,
                                      fontFamily:
                                          "Poppins-R" // Make the text bold
                                      ),
                                ),
                              ),
                              // Search Bar on the Right End
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Row(
                                  children: [
                                    // IconButton(
                                    //   icon: const Icon(Icons.filter_list),
                                    //   onPressed: () {
                                    //     // Handle filter action
                                    //   },
                                    // ),
                                    /*SizedBox(
                                      width: 220,
                                      height: 30,
                                      child: TextField(
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          prefixIcon: const Icon(Icons.search),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  vertical: 8), // Align text
                                        ),
                                        style: const TextStyle(
                                          fontSize: 12, // Set smaller font size
                                        ),
                                        onChanged: (value) {
                                          // Handle search input
                                          setState(() {
                                            filteredRequest = requests;
                                          });
                                        },
                                      ),
                                    ),*/
                                    SizedBox(
                                      width: 220,
                                      height: 30,
                                      child: TextField(
                                        cursorColor: const Color(0xff13322b),
                                        controller: searchController,
                                        readOnly: filterCriteria.isEmpty,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: const BorderSide(
                                              color: Colors
                                                  .black, // Set the outline color to black
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
                                            color: Colors
                                                .black, // Set search icon color to black
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                              vertical: 8), // Align text
                                        ),
                                        style: const TextStyle(
                                          fontSize: 12, // Set smaller font size
                                          color: Colors.black, // Set text color to black
                                        ),
                                        onChanged: _onSearchChanged,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Space between the search bar and table headers
                        Padding(
                          padding: const EdgeInsets.only(left: 20, right: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (activeButtonIndex == 0) {
                                        // If the button is already active, show all requests
                                        activeButtonIndex =
                                            -1; // Reset to inactive state
                                        statusFilter = '';
                                        filteredRequest = statusFilter.isEmpty
                                            ? requests
                                            : requests
                                                .where((request) =>
                                                    request['status'] ==
                                                    statusFilter)
                                                .toList(); // Reset filteredRequest to original requests
                                      } else {
                                        // Set active button index to the first button and filter by approved status
                                        activeButtonIndex = 0;
                                        filterByStatus('approved');
                                      }
                                    });
                                  },
                                  child: Container(
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                          0xff66cce9), // Set background color
                                      border: Border.all(
                                        color: activeButtonIndex == 0
                                            ? Colors.black
                                            : Colors.grey,
                                        width: 2,
                                      ), // Outline based on active state
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment
                                            .center, // Center content vertically
                                        children: [
                                          Text(
                                            '$approvedCount', // Show loading count
                                            style: const TextStyle(
                                              //fontWeight: FontWeight.bold,
                                              fontSize:
                                                  30, // Set font size for count
                                              color: Colors
                                                  .black, // Set count text color to white
                                            ),
                                          ),
                                          const SizedBox(
                                              height:
                                                  4), // Add space between count and text
                                          const Text(
                                            'APPROVED',
                                            style: TextStyle(
                                              fontSize:
                                                  12, // Set font size to 12
                                              fontWeight: FontWeight
                                                  .bold, // Make text bold
                                              color: Colors
                                                  .black, // Set text color to white
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8.0), // Space between cards
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (activeButtonIndex == 1) {
                                        // If the button is already active, show all requests
                                        activeButtonIndex =
                                            -1; // Reset to inactive state
                                        statusFilter = '';
                                        filteredRequest = statusFilter.isEmpty
                                            ? requests
                                            : requests
                                                .where((request) =>
                                                    request['status'] ==
                                                    statusFilter)
                                                .toList();
                                      } else {
                                        // Set active button index to the second button and filter by pending status
                                        activeButtonIndex = 1;
                                        filterByStatus('pending');
                                      }
                                    });
                                  },
                                  child: Container(
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                          0xfffec316), // Set background color
                                      border: Border.all(
                                        color: activeButtonIndex == 1
                                            ? Colors.black
                                            : Colors.grey,
                                        width: 2,
                                      ), // Outline based on active state
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment
                                            .center, // Center content vertically
                                        children: [
                                          Text(
                                            '$pendingCount', // Show loading count
                                            style: const TextStyle(
                                              //fontWeight: FontWeight.bold,
                                              fontSize:
                                                  30, // Set font size for count
                                              color: Colors
                                                  .black, // Set count text color to white
                                            ),
                                          ),
                                          const SizedBox(
                                              height:
                                                  4), // Add space between count and text
                                          const Text(
                                            'PENDING',
                                            style: TextStyle(
                                              fontSize:
                                                  12, // Set font size to 12
                                              fontWeight: FontWeight
                                                  .bold, // Make text bold
                                              color: Colors
                                                  .black, // Set text color to white
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8.0), // Space between cards
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (activeButtonIndex == 2) {
                                        // If the button is already active, show all requests
                                        activeButtonIndex =
                                            -1; // Reset to inactive state
                                        // Call function to show all requests
                                        statusFilter = '';
                                        filteredRequest = statusFilter.isEmpty
                                            ? requests
                                            : requests
                                                .where((request) =>
                                                    request['status'] ==
                                                    statusFilter)
                                                .toList();
                                      } else {
                                        // Set active button index to the third button and filter by rejected status
                                        activeButtonIndex = 2;
                                        filterByStatus('rejected');
                                      }
                                    });
                                  },
                                  child: Container(
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                          0xfff0516e), // Set background color
                                      border: Border.all(
                                        color: activeButtonIndex == 2
                                            ? Colors.black
                                            : Colors.grey,
                                        width: 2,
                                      ), // Outline based on active state
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment
                                            .center, // Center content vertically
                                        children: [
                                          Text(
                                            '$rejectCount', // Show loading count
                                            style: const TextStyle(
                                              //fontWeight: FontWeight.bold,
                                              fontSize:
                                                  30, // Set font size for count
                                              color: Colors
                                                  .black, // Set count text color to white
                                            ),
                                          ),
                                          const SizedBox(
                                              height:
                                                  4), // Add space between count and text
                                          const Text(
                                            'REJECTED',
                                            style: TextStyle(
                                              fontSize:
                                                  12, // Set font size to 12
                                              fontWeight: FontWeight
                                                  .bold, // Make text bold
                                              color: Colors
                                                  .black, // Set text color to white
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8.0),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (activeButtonIndex == 3) {
                                        // If the button is already active, show all requests
                                        activeButtonIndex =
                                            -1; // Reset to inactive state
                                        // Call function to show all requests
                                        statusFilter = '';
                                        filteredRequest = statusFilter.isEmpty
                                            ? requests
                                            : requests
                                                .where((request) =>
                                                    request['status'] ==
                                                    statusFilter)
                                                .toList();
                                      } else {
                                        // Set active button index to the third button and filter by rejected status
                                        activeButtonIndex = 3;
                                        filterByStatus('cancelled');
                                      }
                                    });
                                  },
                                  child: Container(
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: const Color(0xffD8DEE1), // Set background color
                                      border: Border.all(
                                        color: activeButtonIndex == 3
                                            ? Colors.black
                                            : Colors.grey,
                                        width: 2,
                                      ), // Outline based on active state
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment
                                            .center, // Center content vertically
                                        children: [
                                          Text(
                                            '$cancelledCount', // Show loading count
                                            style: const TextStyle(
                                              //fontWeight: FontWeight.bold,
                                              fontSize:
                                                  30, // Set font size for count
                                              color: Colors
                                                  .black, // Set count text color to white
                                            ),
                                          ),
                                          const SizedBox(
                                              height:
                                                  4), // Add space between count and text
                                          const Text(
                                            'CANCELLED',
                                            style: TextStyle(
                                              fontSize:
                                                  12, // Set font size to 12
                                              fontWeight: FontWeight
                                                  .bold, // Make text bold
                                              color: Colors
                                                  .black, // Set text color to white
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ), // Space between cards
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Table headers
                        Padding(
                          padding: const EdgeInsets.only(left: 20, right: 20),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors
                                    .grey, // Outline color for the outer container
                                width:
                                    2.0, // Outline width for the outer container
                              ),
                              borderRadius: BorderRadius.circular(
                                  5.0), // Outline radius for the outer container
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // PNP Number
                                Expanded(
                                  flex: 1, // Same flex for each column
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (filterCriteria == 'loa_no') {
                                          filterCriteria = ''; // Clear the filterCriteria (or set to null)
                                          searchQuery = ''; // Optionally reset the search query
                                          searchController.text='';
                                        } else {
                                          filterCriteria = 'loa_no'; // Set to 'member' if it's not already
                                          searchQuery = ''; // Optionally reset the search query
                                          searchController.text='';
                                        }
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: filterCriteria=='loa_no'?const Color(0xFF13322B):Colors.transparent,
                                        border: Border.all(
                                          color: Colors
                                              .black, // Outline color for the text container
                                          width:
                                              1.0, // Outline width for the text container
                                        ),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(
                                              5.0), // Rounded top left corner
                                          bottomLeft: Radius.circular(
                                              5.0), // Rounded bottom left corner
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(
                                          8.0), // Padding inside the text container
                                      child: Text(
                                        'LOA Number',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: filterCriteria=='loa_no'?const Color(0xFFFFFFFF):Colors.black),
                                      ),
                                    ),
                                  ),
                                ),
                                // PNP Number Section (No Divider)
                                // Requester Name
                                Expanded(
                                  flex: 1, // Same flex for each column
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (filterCriteria == 'member') {
                                          filterCriteria = ''; // Clear the filterCriteria (or set to null)
                                          searchQuery = ''; // Optionally reset the search query
                                          searchController.text='';
                                        } else {
                                          filterCriteria = 'member'; // Set to 'member' if it's not already
                                          searchQuery = ''; // Optionally reset the search query
                                          searchController.text='';
                                        }
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: filterCriteria=='member'?const Color(0xFF13322B):Colors.transparent,
                                        border: Border.all(
                                          color: Colors
                                              .black, // Outline color for the text container
                                          width:
                                              1.0, // Outline width for the text container
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(
                                          8.0), // Padding inside the text container
                                      child: Text(
                                        'Requester Name',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: filterCriteria=='member'?const Color(0xFFFFFFFF):Colors.black),
                                      ),
                                    ),
                                  ),
                                ),
                                // Email
                                Expanded(
                                  flex: 1, // Same flex for each column
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (filterCriteria == 'email') {
                                          filterCriteria = ''; // Clear the filterCriteria (or set to null)
                                          searchQuery = ''; // Optionally reset the search query
                                          searchController.text='';
                                        } else {
                                          filterCriteria = 'email'; // Set to 'member' if it's not already
                                          searchQuery = ''; // Optionally reset the search query
                                          searchController.text='';
                                        }
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: filterCriteria=='email'?const Color(0xFF13322B):Colors.transparent,
                                        border: Border.all(
                                          color: Colors.black,
                                          width: 1.0,
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        'Email',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: filterCriteria=='email'?const Color(0xFFFFFFFF): Colors.black),
                                      ),
                                    ),
                                  ),
                                ),
                                // Date
                                Expanded(
                                  flex: 1, // Same flex for each column
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (filterCriteria == 'date') {
                                          filterCriteria = ''; // Clear the filterCriteria (or set to null)
                                          searchQuery = ''; // Optionally reset the search query
                                          searchController.text='';
                                        } else {
                                          filterCriteria = 'date'; // Set to 'member' if it's not already
                                          searchQuery = ''; // Optionally reset the search query
                                          searchController.text='';
                                        }
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: filterCriteria=='date'?const Color(0xFF13322B):Colors.transparent,
                                        border: Border.all(
                                          color: Colors.black,
                                          width: 1.0,
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        'Date and Time',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: filterCriteria=='date'?const Color(0xFFFFFFFF):Colors.black),
                                      ),
                                    ),
                                  ),
                                ),
                                // Purpose of Request
                                Expanded(
                                  flex: 1, // Same flex for each column
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (filterCriteria == 'request_type') {
                                          filterCriteria = ''; // Clear the filterCriteria (or set to null)
                                          searchQuery = ''; // Optionally reset the search query
                                          searchController.text='';
                                        } else {
                                          filterCriteria = 'request_type'; // Set to 'member' if it's not already
                                          searchQuery = ''; // Optionally reset the search query
                                          searchController.text='';
                                        }
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: filterCriteria=='request_type'?const Color(0xFF13322B):Colors.transparent,
                                        border: Border.all(
                                          color: Colors.black,
                                          width: 1.0,
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        'Service Type',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: filterCriteria=='request_type'?const Color(0xFFFFFFFF):Colors.black),
                                      ),
                                    ),
                                  ),
                                ),
                                // Status
                                Expanded(
                                  flex: 1, // Same flex for each column
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 1.0,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(8.0),
                                    child: const Text(
                                      'Status',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                    ),
                                  ),
                                ),
                                // Action
                                Expanded(
                                  flex: 1, // Same flex for each column
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 1.0,
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(
                                            5.0), // Rounded top right corner
                                        bottomRight: Radius.circular(
                                            5.0), // Rounded bottom right corner
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(8.0),
                                    child: const Text(
                                      'Action',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 8.0),

                        Expanded(
                          child: ListView.builder(
                            itemCount: filteredRequest.length,
                            itemBuilder: (context, index) {
                              final request = filteredRequest[index];
                              String dateCreatedString =
                                  request['date_created'];
                              DateTime dateCreated =
                                  DateTime.parse(dateCreatedString);
                              formattedDate = formatDate(dateCreated);
                              return Padding(
                                padding:
                                    const EdgeInsets.only(left: 20, right: 20),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey,
                                        width: 1.0,
                                      ),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        top: 4, bottom: 4),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // LOA Number
                                        Expanded(
                                          flex: 1, // Same flex for each column
                                          child: TableCellContent(
                                            content: request['request_id']
                                                .toString()
                                                .padLeft(
                                                    5, '0'), // Pass String here
                                          ),
                                        ),
                                        // Requester Name
                                        Expanded(
                                          flex: 1, // Same flex for each column
                                          child: TableCellContent(
                                            content:
                                                '${request['patient_lname']}, ${request['patient_fname']}' ??
                                                    '', // Pass String here
                                          ),
                                        ),
                                        // Email
                                        Expanded(
                                          flex: 1, // Same flex for each column
                                          child: TableCellContent(
                                            content: request['patient_email'] ??
                                                '', // Pass String here
                                          ),
                                        ),
                                        // Date
                                        Expanded(
                                          flex: 1, // Same flex for each column
                                          child: TableCellContent(
                                            content: formattedDate ??
                                                '', // Pass String here
                                          ),
                                        ),
                                        // Purpose of Request
                                        Expanded(
                                          flex: 1, // Same flex for each column
                                          child: TableCellContent(
                                            content: request['form_type'] ??
                                                "", // Pass String here
                                          ),
                                        ),
                                        // Status
                                        Expanded(
                                          flex: 1, // Same flex for each column
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: request['status'] ==
                                                      'pending'
                                                  ? const Color(0xfffec316)
                                                  : request['status'] ==
                                                          'approved'
                                                      ? const Color(0xff66cce9)
                                                      : request['status'] ==
                                                              'rejected'
                                                          ? const Color(
                                                              0xfff0516e)
                                                          : const Color(0xffD8DEE1), // Default color if needed
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            padding: const EdgeInsets.all(8.0),
                                            child: Center(
                                              child: Text(
                                                request['status'].toUpperCase() ?? '',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors
                                                      .black, // Adjust text color accordingly
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
// Action
                                        Expanded(
                                          child: Padding(
                                            padding: EdgeInsets.only(left: request['locked_by'] != null?0:50),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .end,
                                              children: [
                                                BlocBuilder<AuthBloc,
                                                    AuthState>(
                                                  builder: (context, state) {
                                                    if (state is AuthSuccess) {
                                                       
                                                        return Row(
                                                          children: [
                                                          if (state.adminType ==
                                                          'admin' || state.adminType ==
                                                          'concierge')
                                                            IconButton(
                                                              icon: const Icon(
                                                                  Icons.check),
                                                              onPressed: request[
                                                                              'status'] ==
                                                                          'approved' ||
                                                                      request['status'] ==
                                                                          'rejected' || request['status']=='cancelled'
                                                                  ? null // Disable if status is approved or rejected
                                                                  : () async {
                                                                      // Show green modal when check icon is clicked
                                                                      bool isStated =await _releasedRequest(authState.uid.toString() ,request['request_id'].toString());
                                                                      if(isStated){
                                                                        String lockedId = await _lockedRequest(authState.uid.toString(), request['request_id'].toString());
                                                                        String userName = await _getName(lockedId);
                                                                        if(lockedId==authState.uid.toString()){
                                                                          showApprovalDialog(
                                                                            context,
                                                                            request,
                                                                            setState,
                                                                            authState
                                                                                .uid
                                                                                .toString());
                                                                        }else{
                                                                        _showMessage('Request is currently being processed by $userName','Error');
                                                                        }
                                                                      }else{
                                                                        String lockedId = await _lockedRequest(authState.uid.toString(), request['request_id'].toString());
                                                                        String userName = await _getName(lockedId);
                                                                        if(lockedId==authState.uid.toString()){
                                                                          showApprovalDialog(
                                                                            context,
                                                                            request,
                                                                            setState,
                                                                            authState
                                                                                .uid
                                                                                .toString());
                                                                        }else{
                                                                        _showMessage('Request is currently being processed by $userName','Error');
                                                                      }
                                                                      }
                                                                      
                                                                    },
                                                            ),
                                                            if (state.adminType ==
                                                          'admin' || state.adminType ==
                                                          'concierge')
                                                            IconButton(
                                                              icon: const Icon(
                                                                  Icons.close),
                                                              onPressed: request[
                                                                              'status'] ==
                                                                          'approved' ||
                                                                      request['status'] ==
                                                                          'rejected' || request['status']=='cancelled'
                                                                  ? null // Disable if status is approved or rejected
                                                                  : () async{ 
                                                                    print(request['locked_by']);
                                                                      bool isStated =await _releasedRequest(authState.uid.toString() ,request['request_id'].toString());
                                                                      if(isStated){
                                                                        String lockedId = await _lockedRequest(authState.uid.toString(), request['request_id'].toString());
                                                                        String userName = await _getName(lockedId);
                                                                        if(lockedId==authState.uid.toString()){
                                                                          showRejectDialog(context,
                                                                              request,
                                                                              setState,
                                                                              authState
                                                                                  .uid
                                                                                  .toString());
                                                                        
                                                                        }else{
                                                                        _showMessage('Request is currently being processed by $userName','Error');
                                                                        }
                                                                      
                                                                      }else
                                                                      {
                                                                        String lockedId = await _lockedRequest(authState.uid.toString(), request['request_id'].toString());
                                                                        String userName = await _getName(lockedId);
                                                                        if(lockedId==authState.uid.toString()){
                                                                          showRejectDialog(context,
                                                                              request,
                                                                              setState,
                                                                              authState
                                                                                  .uid
                                                                                  .toString());
                                                                        
                                                                        }else{
                                                                        _showMessage('Request is currently being processed by $userName','Error');
                                                                        }
                                                                      }
                                                                      
                                                                    },
                                                            ),
                                                            if (state.adminType ==
                                                          'admin' || state.adminType ==
                                                          'concierge' || state.adminType ==
                                                          'claims')
                                                            IconButton(
                                                              icon: const Icon(Icons
                                                                  .remove_red_eye_outlined),
                                                              onPressed: request[
                                                                          'file_upload']
                                                                      .isEmpty
                                                                  ? null
                                                                  : () {
                                                                      // Implement download action if needed1
                                                                      String
                                                                          name =
                                                                          '${request['patient_lname']}-${request['request_id']}';
                                                                      List<String>
                                                                          imageUrls;
                                                                      if (request[
                                                                              'file_upload']
                                                                          is String) {
                                                                        // If it's a string, parse it
                                                                        imageUrls =
                                                                            List<String>.from(jsonDecode(request['file_upload']));
                                                                      } else {
                                                                        // Otherwise, assume it's already a list
                                                                        imageUrls =
                                                                            List<String>.from(request['file_upload']);
                                                                      }
                                                                      _showImageDialog(
                                                                          context,
                                                                          imageUrls,
                                                                          name);
                                                                    },
                                                            ),

                                                            if(request['locked_by']==authState.uid)
                                                              IconButton(
                                                                icon: const Icon(Icons.lock), // Three-dot icon
                                                                onPressed: ()async {
                                                                 bool isStated= await _releasedRequest(authState.uid.toString() ,request['request_id'].toString());
                                                                 if(isStated){
                                                                  _showMessage('LOA is now unlocked', 'Unlocked Successfully');
                                                                 }
                                                                }
                                                              ),
                                                          ],
                                                        );
                                                      
                                                    }
                                                    return const SizedBox
                                                        .shrink();
                                                  },
                                                ),
                                                
                                                IconButton(
                                                  icon: const Icon(Icons
                                                      .more_vert), // Three-dot icon
                                                  onPressed: () {
                                                    // Show the modal when the three-dot icon is clicked
                                                    String patientName="${request['patient_fname']} ${request['patient_lname']}";
                                                    String cardNo=request['card_number'] ?? 'N/A';
                                                    String serviceType=request['form_type'];
                                                    String doctorName='N/A';
                                                    String notesValue = '';
                                                    if(request['doctor_fname']!=null && request['doctor_lname']!=null){
                                                      doctorName='${request['doctor_fname']} ${request['doctor_lname']}';
                                                      if(request['remarks']!=null){
                                                        String remarks = request['remarks'];
                                                        if (remarks.isNotEmpty) {
                                                            // Split the remarks by commas
                                                            List<String> parts = remarks.split(',');

                                                            // Loop through each part to find the doctor and notes values
                                                            for (String part in parts) {
                                                              if (part.startsWith('doctor:')) {
                                                                // Get the value after 'doctor:'
                                                                //doctorName = part.split(':')[1]; // This will give you the doctor value
                                                              } else if (part.startsWith('notes:')) {
                                                                // Get the value after 'notes:'
                                                                notesValue = part.split(':')[1]; // This will give you the notes value
                                                                if(notesValue.isEmpty){
                                                                  notesValue='N/A';
                                                                }
                                                              }
                                                            }
                                                          }
                                                        }else{
                                                          notesValue='N/A';
                                                        }
                                                    }else{
                                                      if(request['remarks']!=null){
                                                        String remarks = request['remarks'];
                                                        if (remarks.isNotEmpty) {
                                                            // Split the remarks by commas
                                                            List<String> parts = remarks.split(',');

                                                            // Loop through each part to find the doctor and notes values
                                                            for (String part in parts) {
                                                              if (part.startsWith('doctor:')) {
                                                                // Get the value after 'doctor:'
                                                                doctorName = part.split(':')[1]; // This will give you the doctor value
                                                              } else if (part.startsWith('notes:')) {
                                                                // Get the value after 'notes:'
                                                                notesValue = part.split(':')[1]; // This will give you the notes value
                                                                if(notesValue.isEmpty){
                                                                  notesValue='N/A';
                                                                }
                                                              }
                                                            }
                                                          }
                                                        }else{
                                                          notesValue='N/A';
                                                        }
                                                    }
                                                    showDialog(
                                                      context: context,
                                                      barrierDismissible: false,
                                                      builder: (BuildContext
                                                          context) {
                                                        return AlertDialog(
                                                          backgroundColor: Colors
                                                              .white, // Set the modal background color to white
                                                          content: SizedBox(
                                                            width:
                                                                600.0, // Set the width of the modal to 600
                                                            child:
                                                                SingleChildScrollView(
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  // Single card for patient information
                                                                  Card(
                                                                    color: Colors
                                                                        .white, // Set the card background color to white
                                                                    elevation:
                                                                        4, // Optional: Shadow effect
                                                                    child:
                                                                        Padding(
                                                                      padding: const EdgeInsets
                                                                          .all(
                                                                          16.0),
                                                                      child:
                                                                          Column(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        children: [
                                                                          const Text(
                                                                            "Other Details",
                                                                            style:
                                                                                TextStyle(
                                                                              fontWeight: FontWeight.bold,
                                                                              fontSize: 16,
                                                                              color: Colors.black,
                                                                            ),
                                                                          ),
                                                                          const SizedBox(
                                                                              height: 10), // Add spacing
                                                                          Table(
                                                                            border:
                                                                                const TableBorder(
                                                                              horizontalInside: BorderSide(color: Colors.grey, width: 1), // Set horizontal lines
                                                                              verticalInside: BorderSide.none, // Remove vertical lines
                                                                              top: BorderSide(color: Colors.grey), // Top border line
                                                                              bottom: BorderSide(color: Colors.grey), // Bottom border line
                                                                            ),
                                                                            children: [
                                                                              
                                                                              TableRow(children: [
                                                                                const Text("Patient Name", style: TextStyle(color: Colors.black)),
                                                                                Text(patientName ?? 'N/A', style: const TextStyle(color: Colors.black)),
                                                                              ]),

                                                                              TableRow(children: [
                                                                                const Text("Contact No", style: TextStyle(color: Colors.black)),
                                                                                Text(request['patient_contact'] ?? 'N/A', style: const TextStyle(color: Colors.black)),
                                                                              ]),
                                                                              
                                                                              TableRow(children: [
                                                                                const Text("Card Number", style: TextStyle(color: Colors.black)),
                                                                                Text(cardNo?? 'N/A', style: const TextStyle(color: Colors.black)),
                                                                              ]),
                                                                              
                                                                              TableRow(children: [
                                                                                const Text("Service Type", style: TextStyle(color: Colors.black)),
                                                                                Text(serviceType ?? 'N/A', style: const TextStyle(color: Colors.black)),
                                                                              ]),
                                                                              TableRow(children: [
                                                                                const Text("Location", style: TextStyle(color: Colors.black)),
                                                                                Text(request['location'] ?? 'N/A', style: const TextStyle(color: Colors.black)),
                                                                              ]),
                                                                              TableRow(children: [
                                                                                const Text("Hospital", style: TextStyle(color: Colors.black)),
                                                                                Text(request['hospital_name'] ?? 'N/A', style: const TextStyle(color: Colors.black)),
                                                                              ]),
                                                                              TableRow(children: [
                                                                                const Text("Specialization", style: TextStyle(color: Colors.black)),
                                                                                Text(request['specialization'] ?? 'N/A', style: const TextStyle(color: Colors.black)),
                                                                              ]),
                                                                              TableRow(children: [
                                                                                const Text("Doctor Name", style: TextStyle(color: Colors.black)),
                                                                                Text(doctorName, style: const TextStyle(color: Colors.black)),
                                                                              ]),
                                                                              TableRow(children: [
                                                                                const Text("Chief Complain", style: TextStyle(color: Colors.black)),
                                                                                Text(request['chief_complaint'] ?? 'N/A', style: const TextStyle(color: Colors.black)),
                                                                              ]),
                                                                              TableRow(children: [
                                                                                const Text("Diagnosis", style: TextStyle(color: Colors.black)),
                                                                                Text(request['diagnosis'] ?? 'N/A', style: const TextStyle(color: Colors.black)),
                                                                              ]),
                                                                              TableRow(children: [
                                                                                const Text("Notes", style: TextStyle(color: Colors.black)),
                                                                                Text(notesValue, style: const TextStyle(color: Colors.black)),
                                                                              ]),
                                                                            ],
                                                                          ),
                                                                          if(request['cancelled_remarks']!=null)
                                                                             Column(
                                                                              children: [
                                                                                const SizedBox(height: 30),
                                                                                 SizedBox(
                                                                                  width: 600,
                                                                                  child: Column(
                                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                                    children: [
                                                                                      const Text('Reason for Cancellation',
                                                                                      style:
                                                                                          TextStyle(
                                                                                        fontWeight: FontWeight.bold,
                                                                                        fontSize: 16,
                                                                                        color: Colors.black,
                                                                                      )),
                                                                                      const Divider(color: Color(0xFF000000),
                                                                                      thickness: .3,
                                                                                      indent: 0,
                                                                                      endIndent: 0),
                                                                                      const SizedBox(height: 5),
                                                                                      Text(request['cancelled_remarks'],
                                                                                      style:const TextStyle(
                                                                                        fontSize: 14,
                                                                                        color: Colors.black,
                                                                                      ),
                                                                                      softWrap: true, // Ensures that the text will wrap if needed
                                                                                      maxLines: 3,)
                                                                                    ],
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            )
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () {
                                                                Navigator.of(
                                                                        context)
                                                                    .pop(); // Close the dialog
                                                              },
                                                              child: const Text(
                                                                  "Close",
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .black)),
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    );
                                                  },
                                                  tooltip:
                                                      'More Details', // Optional tooltip
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          }
          return Container(); // Fallback if no auth state is found
        },
      ),
    );
  }


  void showRejectDialog(BuildContext context, final request, StateSetter setState, String uid){
    bool isLoading =false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        TextEditingController rejectionController = TextEditingController();
        bool isTextFieldEmpty = true; // Track if text field is empty
        String errorMessage = ''; // Variable to hold the error message

        return StatefulBuilder(
          // Use StatefulBuilder to manage state in dialog
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color.fromARGB(255, 255, 255, 255),
              title: const Text(
                'REJECT',
                style: TextStyle(
                  color: Color(0xff13322b),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: SizedBox(
                width: 300,
                height: 150, // Increased height for the error message
                child: isLoading
                    ? const Center(
                        // Center the spinner when loading
                        child: SpinKitCircle(
                          color:
                              Color(0xff13322B), // Change the color as needed
                          size: 50.0, // Adjust size as needed
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 20),
                          TextField(
                            controller: rejectionController,
                            onChanged: (text) {
                              setState(() {
                                isTextFieldEmpty = text
                                    .isEmpty; // Update the state based on input
                                errorMessage =
                                    ''; // Clear the error message when typing
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Type your rejection reason here...',
                              hintStyle: const TextStyle(
                                  color: Color.fromARGB(137, 52, 52, 52)),
                              filled: true,
                              fillColor:
                                  const Color.fromARGB(255, 145, 145, 145)
                                      .withOpacity(0.1),
                              border: const OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8.0)),
                                borderSide: BorderSide.none,
                              ),
                              errorText: isTextFieldEmpty
                                  ? errorMessage
                                  : null, // Show error message if empty
                              errorStyle: const TextStyle(
                                  color: Colors.red), // Set error text color
                            ),
                            style: const TextStyle(
                                color: Color.fromARGB(255, 0, 0, 0)),
                            maxLines:
                                3, // Allow multiple lines for longer input
                          ),
                        ],
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: !isLoading
                      ? () async {
                          if (isTextFieldEmpty) {
                            setState(() {
                              errorMessage =
                                  'Please state reason for rejection'; // Set error message if text field is empty
                            });
                            return; // Prevent submission
                          }

                          setState(() {
                            isLoading =
                                true; // Set loading state to true when the button is pressed
                          });

                          String rejectionReason = rejectionController.text;
                          bool isStated = await _updateRequestForm(
                            request['request_id'].toString(),
                            'rejected',
                            '',
                            uid,
                            '',
                            rejectionReason,
                          );

                          

                          setState(() {
                            isLoading =
                                false; // Reset loading state after the operation
                          });

                          if (isStated) {
                            await logUserAction(uid,'mp_form_request_table','Update','Reject ${request['request_id'].toString()}');
                            // Close all dialogs and show the success message
                            Navigator.of(context).popUntil(
                                (route) => route.isFirst); // Close all modals
                            _showMessage(
                                'LOA Request ID: ${request['request_id']} has been rejected',
                                'Rejection Completed');
                          } else {
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                            _showMessage(
                                message.isNotEmpty
                                    ? message
                                    : 'Request is currently being processed by another user',
                                'Error');
                          }
                        }
                      : null,
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xff13322b),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                  ),
                ),
                TextButton(
                  onPressed: !isLoading
                      ? () {
                          setState(() {
                            _releasedRequest(uid,
                                request['request_id'].toString());
                          });
                          Navigator.of(context).pop();
                        }
                      : null,
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xff13322b),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Color.fromARGB(255, 254, 254, 254)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showApprovalDialog(
      BuildContext context, final request, StateSetter setState, String uid) {
    bool _isLoading = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, setState) {
            return AlertDialog(
            backgroundColor: const Color(0xffffffff),
            title: const Text(
              'APPROVE',
              style: TextStyle(
                color: Color(0xff13322b),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: SizedBox(
              width: 300, // Set width
              height: 130, // Set height
              child: Center(
                child: _isLoading
                    ? const SpinKitCircle(
                        color: Color(0xff13322b), // Spinner color
                        size: 50.0, // Spinner size
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 200,
                            height: 40,
                            child: ElevatedButton(
                              onPressed: () {
                                _pickFiles(setState);
                              },
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                backgroundColor: const Color(0xff13322b),
                              ),
                              child: const Text(
                                'Select File',
                                style: TextStyle(color: Color(0xffffffff)),
                              ),
                            ),
                          ),
                          if (_selectedFiles != null)
                            const SizedBox(height: 30),
                          if (_selectedFiles != null)
                            ..._selectedFiles!.map((file) => Text(
                                  file.name,
                                  style: const TextStyle(
                                      color: Color(0xff13322b)),
                                )),
                        ],
                      ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: !_isLoading? () async {
                  try{
                    if(_selectedFiles!.isEmpty && _selectedFiles==null){
                      _showMessage('Please select a LOA file to upload', "Error: File upload is required");
                      setState(() {
                        _selectedFiles = null;
                      });
                    }else{
                      setState(() {
                        _isLoading = true; // Start loading
                      });
                      String fullName =
                          '${request['patient_lname']}${request['patient_fname']}';
                      bool isStated = await _updateRequestForm(
                          request['request_id'].toString(),
                          'approved',
                          fullName,
                          uid,
                          'forms',
                          '');
                      setState(() {
                        _selectedFiles = null;
                        _isLoading = false; // Stop loading
                      });
                        
                      if (isStated) {
                        await logUserAction(uid,'mp_form_request_table','Update','Approved ${request['request_id'].toString()}');
                        Navigator.of(context).popUntil((route) => route.isFirst);
                        _showMessage(
                            'LOA Request ID: ${request['request_id']} has been approved',
                            'Approval Completed');
                      } else {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                        _showMessage(
                            message.isNotEmpty
                                ? message
                                : 'Request is currently being processed by another user',
                            'Error');
                      }
                    }
                  }catch(error){
                    _showMessage('Please select a LOA file to upload', "Error: File upload is required");
                  }
                  
                }:null,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xff13322b),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                ),
              ),
              TextButton(
                onPressed: !_isLoading?() {
                  Navigator.of(context).pop();
                  setState((){
                    _selectedFiles = null;
                    _releasedRequest(uid ,request['request_id'].toString());
                  });
                }:null,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xff13322b),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Color(0xffffffff)),
                ),
              ),
            ],
          );
          }
        );
      },
    );
  }

  void _showImageDialog(
      BuildContext context, List<String> imageUrls, String name) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Images'),
          content: SizedBox(
            width: 600,
            height: 800, // Set height as needed
            child: ListView.builder(
              itemCount: imageUrls.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding:
                      const EdgeInsets.only(bottom: 8.0), // Add spacing here
                  child: Row(
                    children: [
                      Expanded(
                        child: CachedNetworkImage(
                          imageUrl: imageUrls[index],
                          placeholder: (context, url) => const SizedBox(
                            width: 5.0, // Set your desired width
                            height: 30.0, // Set your desired height
                            child: Center(child: SpinKitCircle(
                              color: Color(
                                  0xffffffff), // Change the color as needed
                              size: 50.0, // Adjust size as needed
                            )),
                          ),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.download),
                        onPressed: () {
                          _downloadFile(imageUrls[index], name);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _downloadFile(String fileUrl, String username) async {
    try {
      // Use Dio to get the response
      Response response = await Dio().get(
        fileUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      // Create a Blob from the response data
      final blob = html.Blob([response.data]);
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Create a filename that includes the username
      String fileName = '${username}_${fileUrl.split('/').last}';

      // Create an anchor element to trigger the download
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName) // Use the new filename
        ..click();

      // Cleanup
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      print('Download failed: $e');
      // Optionally show an error message
      html.window.alert('Download failed: $e');
    }
  }
}

class TableHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSort;
  final bool isAscending;

  const TableHeader({
    super.key,
    required this.title,
    required this.onSort,
    this.isAscending = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSort,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: Colors.grey),
            right: BorderSide(color: Colors.grey),
          ),
          color: Color(0xfff1f1f1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            // Sort arrows
            Column(
              children: [
                Icon(
                  isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TableCellContent extends StatelessWidget {
  final String content;

  const TableCellContent({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        content,
        style: const TextStyle(color: Colors.black),
        overflow: TextOverflow.ellipsis, // Add this line
        maxLines: 1, // Optional: Limits the text to a single line
      ),
    );
  }
}
