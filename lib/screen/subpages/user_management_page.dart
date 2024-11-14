import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:medicare_admin_remaster/bloc/auth/auth_bloc.dart';
import 'package:medicare_admin_remaster/class/address.dart';
import 'package:medicare_admin_remaster/class/loa_request.dart';
import 'package:medicare_admin_remaster/class/status_item.dart';
import 'package:medicare_admin_remaster/shared/api.dart';
import 'package:medicare_admin_remaster/shared/list.dart';
import 'package:medicare_admin_remaster/widget/address_dropdown.dart';
import 'package:medicare_admin_remaster/widget/birthday_picker.dart';
import 'dart:html' as html;

import 'package:medicare_admin_remaster/widget/custom_textform_field.dart';
import 'package:medicare_admin_remaster/widget/list_dropdown.dart';
import 'package:medicare_admin_remaster/widget/string_dropdown.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  _UserManagementPageState createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  String? selectedDate;
  bool isAscending = true;
  String? _selectedSex;
  String? _eselectedSex;
  DateTime? _birthday;
  int? selectedType;
  bool isLoading = false;
  bool isDateError = false;
  bool noSex=false;
  String cardNumbers = 'N/A';
  String dateLabel='yyyy-mm-dd';
  String? customerId;
  String? limit_id;
  String? prb_id;
  String? card_id;
  String? plan_id;

  String? selectedRegion;
  String? selectedProvince;
  String? selectedCity;
  String? selectedBarangay;

  List<Region> regions = [];
  List<Region> myRegions = [];
  List<Province> provinces = [];
  List<City> cities = [];
  List<Barangay> barangays = [];

  

  late ApiService _apiService;

  
  final TextEditingController fnameController = TextEditingController();
  final TextEditingController mnameController = TextEditingController();
  final TextEditingController lnameController = TextEditingController();
  final TextEditingController contactNoController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController houseAddressController = TextEditingController();
  final TextEditingController barangayController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController provinceController = TextEditingController();
  final TextEditingController postalCodeController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();
  final TextEditingController civilStatusController = TextEditingController();
  final TextEditingController regionController = TextEditingController();
  final TextEditingController userTypeController = TextEditingController();
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController cardTypeController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  final TextEditingController memberTypeController = TextEditingController();
  final TextEditingController enrollmentTypeController =TextEditingController();
  final TextEditingController planTypeController = TextEditingController();
  final TextEditingController benefitLimitController = TextEditingController();
  final TextEditingController benefitLimitTypeController =TextEditingController();
  final TextEditingController roomAndBoardTypeController =TextEditingController();
  final TextEditingController roomAndBoardLimitController = TextEditingController();


  //for edit of customer
  final TextEditingController efnameController = TextEditingController();
  final TextEditingController emnameController = TextEditingController();
  final TextEditingController elnameController = TextEditingController();
  final TextEditingController econtactNoController = TextEditingController();
  final TextEditingController eemailController = TextEditingController();
  final TextEditingController epasswordController = TextEditingController();
  final TextEditingController ehouseAddressController = TextEditingController();
  final TextEditingController ebarangayController = TextEditingController();
  final TextEditingController ecityController = TextEditingController();
  final TextEditingController eprovinceController = TextEditingController();
  final TextEditingController epostalCodeController = TextEditingController();
  final TextEditingController ebirthdayController = TextEditingController();
  final TextEditingController ecivilStatusController = TextEditingController();
  final TextEditingController eregionController = TextEditingController();
  final TextEditingController euserTypeController = TextEditingController();
  final TextEditingController ecardNumberController = TextEditingController();
  final TextEditingController ecardTypeController = TextEditingController();

  final TextEditingController ememberTypeController = TextEditingController();
  final TextEditingController eenrollmentTypeController =TextEditingController();
  final TextEditingController eplanTypeController = TextEditingController();
  final TextEditingController ebenefitLimitController = TextEditingController();
  final TextEditingController ebenefitLimitTypeController =TextEditingController();
  final TextEditingController eroomAndBoardTypeController =TextEditingController();
  final TextEditingController eroomAndBoardLimitController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  String searchQuery = '';
  String filterCriteria = '';
  // Sample data
  late Stream<List<Map<String, dynamic>>> requests;
  List<PlatformFile> _selectedFiles = [];

  bool _isFormValid = true; // State variable to track form validity


  @override
  void initState() {
    super.initState();
    //fetchLoaRequest();
    _apiService = ApiService(
        'https://medicareplus-api.vercel.app');
    requests = _apiService.streamMembers(supabaseUrl, supabaseKey);

   
    
  }

  @override
  void dispose() {
    // Dispose of the controllers to avoid memory leaks
    super.dispose();
  }  

  int calculateAge(String birthday) {
  // Parse the date string to DateTime
    DateTime birthDate = DateTime.parse(birthday);
    DateTime today = DateTime.now(); // Get the current date

    int age = today.year - birthDate.year; // Calculate the age in years

    // Adjust age if the birthday hasn't occurred yet this year
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  /*Future<void> fetchRegions() async {
    final response = await http.get(Uri.parse('https://psgc.gitlab.io/api/regions.json'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        regions = data.map((e) => Region.fromJson(e)).toList();
      });
    }
  }*/
  

  Future<void> fetchRegions() async {
  final response = await http.get(Uri.parse('https://psgc.gitlab.io/api/regions.json'));

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);

    // Sort the regions with custom logic
    data.sort((a, b) {
      // Define the custom order
      const customOrder = [
        'National Capital Region',
        'Region I',
        'Region II',
        'Region III',
        'Region IV-A', // Region IV-A
        'MIMAROPA Region', // Place MIMAROPA after CALABARZON
        'Region V',
        'Region VI',
        'Region VII',
        'Region VIII',
        'Region IX',
        'Region X',
        'Region XI',
        'Region XII',
        'Region XIII',
        'Cordillera Administrative Region',
        'Bangsamoro Autonomous Region in Muslim Mindanao',
      ];

      int indexA = customOrder.indexOf(a['regionName']);
      int indexB = customOrder.indexOf(b['regionName']);

      // If both items are in customOrder, sort by their indices
      if (indexA != -1 && indexB != -1) {
        return indexA.compareTo(indexB);
      }

      // If only one item is in customOrder, it should come first
      if (indexA != -1) return -1;
      if (indexB != -1) return 1;

      // Default sorting (alphabetical) for other regions
      return a['regionName'].compareTo(b['regionName']);
    });

    setState(() {
      regions = data.map((e) => Region.fromJson(e)).toList();
    });
  } else {
    throw Exception('Failed to load regions');
  }
}



  Future<void> fetchProvinces(String regionCode, StateSetter setState) async {
    final response = await http.get(Uri.parse('https://psgc.gitlab.io/api/regions/$regionCode/provinces.json'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        provinces = data.map((e) => Province.fromJson(e)).toList();
        selectedProvince = null; // Reset province selection
        cities.clear(); // Clear cities
        barangays.clear(); // Clear barangays
      });
    }
  }

  Future<void> fetchCities(String provinceCode, StateSetter setState) async {
    if(provinceCode!='130000000'){
      final response = await http.get(Uri.parse('https://psgc.gitlab.io/api/provinces/$provinceCode/cities-municipalities.json'));
      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final List<dynamic> data = json.decode(decodedBody);
        setState(() {
          cities = data.map((e) => City.fromJson(e)).toList();
          selectedCity = null; // Reset city selection
          barangays.clear(); // Clear barangays
        });
      }
    }else{
      final response = await http.get(Uri.parse('https://psgc.gitlab.io/api/regions/$provinceCode/cities-municipalities.json'));
      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final List<dynamic> data = json.decode(decodedBody);
        setState(() {
          cities = data.map((e) => City.fromJson(e)).toList();
          selectedCity = null; // Reset city selection
          barangays.clear(); // Clear barangays
        });
      }
    }
  }

  Future<void> fetchBarangays(String cityCode, StateSetter setState) async {
    final response = await http.get(Uri.parse('https://psgc.gitlab.io/api/cities-municipalities/$cityCode/barangays.json'));
    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      final List<dynamic> data = json.decode(decodedBody);
      setState(() {
        barangays = data.map((e) => Barangay.fromJson(e)).toList();
      });
    }
  }

  Future<void> _pickFiles(StateSetter setState) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['csv', 'xls', 'xlsx'],
        );
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

  /*Future<void> fetchLoaRequest() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://medicareplus-api.vercel.app/api/admin/get_all_members'),
        headers: {
          'Content-Type': 'application/json',
          'supabase-url': supabaseUrl, // Add Supabase URL
          'supabase-key': supabaseKey, // Add Supabase Key
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          requests = List<Map<String, dynamic>>.from(data['members'] ?? []);
        });
      } else {
        throw Exception('Failed to load status count');
      }
    } catch (e) {
      print('Error: $e');
    }
  }*/
  

  Future<void> _uploadFiles(StateSetter setState) async {
    if (_selectedFiles.isEmpty) {
      print("No files selected");
      return;
    }

    final uri =
        Uri.parse('https://medicareplus-api.vercel.app/api/admin/bulk_upload');
    var request = http.MultipartRequest('POST', uri);

    // Add headers
    request.headers.addAll({
      'supabase-url': supabaseUrl,
      'supabase-key': supabaseKey,
    });

    for (var file in _selectedFiles) {
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

    try {
      var response = await request.send().timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = await http.Response.fromStream(response);
        print('Upload successful: ${responseData.body}');
        // Parse the JSON response
        final jsonResponse = json.decode(responseData.body);
        final int successes = jsonResponse['successes'];
        final List<dynamic> failures = jsonResponse['failures'];

        // Prepare the message
        String message;
        if (failures.isNotEmpty) {
          message =
              'Upload completed with $successes successes and ${failures.length} failures: Due to duplicate found of card number';
        } else {
          message =
              'Your bulk data upload was successful! All records have been processed and added to the system. Total successes: $successes';
        }
        Navigator.of(context).popUntil((route) => route.isFirst);
        _showMessage(message,
            failures.isNotEmpty ? 'Upload Failed' : 'Upload Successful');
        setState(() {
          _selectedFiles = []; // Clear selected files after upload
          //fetchLoaRequest();
          isLoading = false;
          print(isLoading);
        });
      } else {
        print('Failed to upload files: ${response.statusCode}');
        _showMessage('${response.statusCode}', 'Upload Error');
        setState(() {
          _selectedFiles = []; // Clear selected files after upload
          //fetchLoaRequest();
          isLoading = false;
        });
      }
    } on TimeoutException catch (_) {
      // Handle timeout (e.g., show a timeout message)
      setState(() {
        _selectedFiles = []; 
        isLoading = false;
        Navigator.of(context).popUntil((route) => route.isFirst);
        _showMessage('The request timed out. Please try again later.',
          'Connection timeout!');  
      });
    }catch (e) {
      print('Error during file upload: $e');
    }
  }

  /*Future<void> _selectDate(BuildContext context, StateSetter setState, String period) async {
    // Get the initial date from the payperiod
    DateTime initialDate = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    setState(() {
      _birthday = picked;
    });
    if (_birthday == null) {
      // Handle the case where the birthday is required
      // You may use a snackbar or another method to inform the user
      _birthday=initialDate;
      return; // Exit if the birthday is not set
    }
  }*/

  Future<void> _selectDate(BuildContext context, StateSetter setState, String period) async {
  // Default to the current date if the period is null or empty
  DateTime initialDate = DateTime.now();

  // If period is not empty or null, parse the period string into a DateTime
  if (period.isNotEmpty) {
    try {
      initialDate = DateTime.parse(period); // period should be in 'yyyy-MM-dd' format
    } catch (e) {
      // If parsing fails, fallback to the current date
      initialDate = DateTime.now();
    }
  }

  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(1900),
    lastDate: DateTime.now(),
  );

  // If a date was picked, update the _birthday
  setState(() {
    _birthday = picked;
  });

  // Handle the case where no date was picked
  if (_birthday == null) {
    // Optionally show a message to inform the user
    _birthday = initialDate;  // Use the initialDate if no date is picked
    return; // Exit if no date is selected
  }
}


// Helper function to convert PlatformFile to Uint8List
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

  Future<void>updateMember()async {
    String url='$apiUrl/update_customer';

    final Map<String, dynamic> data = {
      'customer_id':customerId,
      'fname': efnameController.text,
      'mname': emnameController.text,
      'lname': elnameController.text,
      'sex': _eselectedSex,
      'contact_no': econtactNoController.text,
      'email': eemailController.text,
      'password': epasswordController.text,
      'house_address': ehouseAddressController.text,
      'barangay': ebarangayController.text,
      'city': ecityController.text,
      'province': eprovinceController.text,
      'postal_code': epostalCodeController.text,
      'birthday': DateFormat('yyyy-MM-dd').format(_birthday!),
      'civil_status': ecivilStatusController.text,
      'region': eregionController.text,
      'user_type': int.parse(ememberTypeController.text),
      'card_number': ecardNumberController.text,
      'card_type': eplanTypeController.text,
      'enrollment_type': int.parse(eenrollmentTypeController.text),
      'room_board_type': int.parse(eroomAndBoardTypeController.text),
      'room_board_limit': eroomAndBoardLimitController.text,
      'benefit_limit': ebenefitLimitController.text,
      'benefit_limit_type': int.parse(ebenefitLimitTypeController.text),
      'limit_id':limit_id,
      'prb_id':prb_id,
      'card_id':card_id,
      'plan_id':plan_id
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
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('User created successfully: $responseData');
        setState(() {
          efnameController.text = '';
          elnameController.text = '';
          emnameController.text = '';
          econtactNoController.text = '';
          eemailController.text = '';
          epasswordController.text = '';
          ehouseAddressController.text = '';
          ebarangayController.text = '';
          ecityController.text = '';
          eprovinceController.text = '';
          epostalCodeController.text = '';
          ebirthdayController.text = '';
          ecivilStatusController.text = '';
          eregionController.text = '';
          ecardNumberController.text = '';
          ecardTypeController.text = '';
          _eselectedSex='';
          ebenefitLimitController.text='';
          eroomAndBoardLimitController.text='';
          _isFormValid=true;
          isLoading=false;
          _birthday=null;
          //fetchLoaRequest();
          Navigator.of(context).popUntil((route) => route.isFirst);
          _showMessage(
              'The member has been successfully updated to the system.',
              'Member Updated Successfully');
        });
        // Show success message or navigate to another screen
      } else {
        final errorData = json.decode(response.body);
        setState(() {
          isLoading=false;
        });
        print('Error: ${errorData['error']}');
        _showMessage(errorData['error'], 'Error');
        // Show error message
      }
    } on TimeoutException catch (_) {
      // Handle timeout (e.g., show a timeout message)
      setState(() {
        efnameController.text = '';
          elnameController.text = '';
          emnameController.text = '';
          econtactNoController.text = '';
          eemailController.text = '';
          epasswordController.text = '';
          ehouseAddressController.text = '';
          ebarangayController.text = '';
          ecityController.text = '';
          eprovinceController.text = '';
          epostalCodeController.text = '';
          ebirthdayController.text = '';
          ecivilStatusController.text = '';
          eregionController.text = '';
          ecardNumberController.text = '';
          ecardTypeController.text = '';
          _eselectedSex='';
          ebenefitLimitController.text='';
          eroomAndBoardLimitController.text='';
          _isFormValid=true;
          isLoading=false;
          _birthday=null;
        Navigator.of(context).popUntil((route) => route.isFirst);
        _showMessage('The request timed out. Please try again later.',
          'Connection timeout!');  
      });
      
    } catch (error) {
      setState(() {
          isLoading=false;
        });
      print('Unexpected error: $error');
      // Handle unexpected errors
    }
  }


  Future<void> addMember(StateSetter setState) async {
    String url ='$apiUrl/add_member'; // Replace with your actual API URL
    DateTime initialDate = DateTime.now();
    if(_birthday==null){
      setState(() {
        _birthday=initialDate;
        isLoading=true;
      });
    }
    final Map<String, dynamic> data = {
      'fname': fnameController.text,
      'mname': mnameController.text,
      'lname': lnameController.text,
      'sex': _selectedSex,
      'contact_no': contactNoController.text,
      'email': emailController.text,
      'password': passwordController.text,
      'house_address': houseAddressController.text,
      'barangay': barangayController.text,
      'city': cityController.text,
      'province': provinceController.text,
      'postal_code': postalCodeController.text,
      'birthday': DateFormat('yyyy-MM-dd').format(_birthday!),
      'civil_status': civilStatusController.text,
      'region': regionController.text,
      'user_type': int.parse(memberTypeController.text),
      'card_number': cardNumberController.text,
      'card_type': planTypeController.text,
      'enrollment_type': int.parse(enrollmentTypeController.text),
      'room_board_type': int.parse(roomAndBoardTypeController.text),
      'room_board_limit': roomAndBoardLimitController.text,
      'benefit_limit': benefitLimitController.text,
      'benefit_limit_type': int.parse(benefitLimitTypeController.text),
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
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('User created successfully: $responseData');
        setState(() {
          fnameController.text = '';
          lnameController.text = '';
          mnameController.text = '';
          contactNoController.text = '';
          emailController.text = '';
          passwordController.text = '';
          houseAddressController.text = '';
          barangayController.text = '';
          cityController.text = '';
          provinceController.text = '';
          postalCodeController.text = '';
          birthdayController.text = '';
          civilStatusController.text = '';
          regionController.text = '';
          cardNumberController.text = '';
          cardTypeController.text = '';
          benefitLimitController.text='';
          roomAndBoardLimitController.text='';
          _selectedSex=null;
          _birthday=null;
          isLoading=false;
          //fetchLoaRequest();
          Navigator.of(context).popUntil((route) => route.isFirst);
          _showMessage(
              'The new member has been successfully added to the system.',
              'Member Added Successfully');
        });
        // Show success message or navigate to another screen
      } else {
        setState(() {
          isLoading=false;
        });
        final errorData = json.decode(response.body);
        print('Error: ${errorData['error']}');
        _showMessage(errorData['error'], 'Error');
        // Show error message
      }
    } on TimeoutException catch (_) {
      // Handle timeout (e.g., show a timeout message)
      setState(() {
        fnameController.text = '';
          lnameController.text = '';
          mnameController.text = '';
          contactNoController.text = '';
          emailController.text = '';
          passwordController.text = '';
          houseAddressController.text = '';
          barangayController.text = '';
          cityController.text = '';
          provinceController.text = '';
          postalCodeController.text = '';
          birthdayController.text = '';
          civilStatusController.text = '';
          regionController.text = '';
          cardNumberController.text = '';
          cardTypeController.text = '';
          benefitLimitController.text='';
          roomAndBoardLimitController.text='';
          _selectedSex=null;
          _birthday=null;
          isLoading=false;
          Navigator.of(context).popUntil((route) => route.isFirst);
          _showMessage('The request timed out. Please try again later.',
              'Connection timeout!');
      });
    } catch (error) {
      setState(() {
          isLoading=false;
        });
      print('Unexpected error: $error');
      // Handle unexpected errors
    }
  }

  /*void _sortTable(String column) {
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

  void _deleteRequest(int index) {
    setState(() {
      requests.removeAt(index);
    });
  }*/

  void _onSearchChanged(String value) {
    setState(() {
      searchQuery = value.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: requests,
      builder: (context, snapshot) {
        return Scaffold(
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: const Color.fromARGB(255, 255, 255, 255),
            toolbarHeight: 140, // Set the height of the AppBar
            flexibleSpace: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 50), // Top spacing
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 20),
                      child: Text(
                        'User Management',
                        style: TextStyle(
                          color: Color(0xff222222),
                          fontFamily: "Roboto-M",
                          fontSize: 32,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20), // Bottom spacing
                Divider(
                  thickness: 2,
                  color: Color(0XFFB6B6B6),
                ),
              ],
            ),
          ),
          body: Builder(
            builder: (context){
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                      // Center the spinner when loading
                      child: SpinKitCircle(
                    color: Color(0xff13322B), // Change the color as needed
                    size: 50.0, // Adjust size as needed
                  ));// Loading indicator
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Text('No data available');
              }

              final requestsList = snapshot.data!;
              final List<Map<String, dynamic>> filteredRequests;
              // Filtering 
              if(filterCriteria==''){
                filteredRequests = requestsList;/*.where((request) {
                final customerType = request['mp_customer_type_table']?['customer_type']?.toLowerCase() ?? '';
                final otherField1 = request['last_name']?.toLowerCase() ?? '';
                final otherField2 = request['first_name']?.toLowerCase() ?? '';
                final email = request['email_address']?.toLowerCase() ?? '';
                final cardNumbers = (request['mp_card_table'] as List<dynamic>?)?.map((card) {
                  return card['card_number']?.toString() ?? '';
                }).join(', ') ?? '';

                return customerType.contains(searchQuery) ||
                    otherField1.contains(searchQuery) ||
                    otherField2.contains(searchQuery) ||
                    cardNumbers.contains(searchQuery) ||
                    email.contains(searchQuery);
              }).toList();*/
              }else{
                filteredRequests = requestsList.where((request) {
                // Check which filter is applied and filter accordingly
                if (filterCriteria == 'member') {
                  // Filter by first name or last name
                  final firstName = request['first_name']?.toLowerCase() ?? '';
                  final lastName = request['last_name']?.toLowerCase() ?? '';
                  return firstName.contains(searchQuery) || lastName.contains(searchQuery);
                }else if(filterCriteria == 'card_number'){
                  final cardNumbers = (request['mp_card_table'] as List<dynamic>?)?.map((card) {
                    return card['card_number']?.toString() ?? '';
                  }).join(', ') ?? '';
                  return cardNumbers.contains(searchQuery);
                }else if(filterCriteria == 'is_active'){
                  final isActive = request['is_active'] ?? false; // Default to false if null
                  // Check if the search text matches 'Active' or 'Inactive'
                  bool isActiveMatch = true;
                  
                  // Compare based on the input from the searchController
                  if (searchController.text.toLowerCase() == 'active' || searchController.text.toLowerCase() == 'act') {
                    isActiveMatch = isActive == true; // Check if the 'is_active' field is true
                  } else if (searchController.text.toLowerCase() == 'inactive' || searchController.text.toLowerCase() == 'ina') {
                    isActiveMatch = isActive == false; // Check if the 'is_active' field is false
                  }

                  return isActiveMatch;
                }
                else if (filterCriteria == 'email') {
                  // Filter by email
                  final email = (request['email_address']?.toLowerCase() ?? 'n/a');
                  return email.contains(searchQuery.toLowerCase());
                } else if (filterCriteria == 'membership') {
                  // Filter by customer type
                  final customerType = request['mp_customer_type_table']?['customer_type']?.toLowerCase() ?? '';
                  return customerType.contains(searchQuery);
                }else if (filterCriteria == 'contact') {
                  // Filter by customer type
                  final contact = request['contact_no'];
                  return contact.contains(searchQuery);
                } else {
                  return false;
                }
              }).toList();
              }
              
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey, // Outline color
                    width: 2.0, // Outline width
                  ),
                  borderRadius: BorderRadius.circular(20.0), // Outline radius
                ),
                child: Column(
                  children: [
                    // Row for the four cards
                    
                    const SizedBox(
                        height: 20), // Add space between cards and other content
                    
                    // Row for custom text and search bar
                    Padding(
                      padding: const EdgeInsets.only(left: 10, bottom: 15, right: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0), // Padding around the text
                            child: Text(
                              '', // Replace with your desired text
                              style: TextStyle(
                                  fontSize: 20, // Adjust the font size as needed
                                  fontWeight: FontWeight.bold,
                                  fontFamily: "Poppins-R" // Make the text bold
                                  ),
                            ),
                          ),
                          // Search Bar on the Right End
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Row(
                              children: [
                               /* IconButton(
                                  icon: const Icon(Icons.filter_list),
                                  color:
                                      Colors.black, // Set filter icon color to black
                                  onPressed: () {
                                    // Handle filter action
                                    setState(() {
                                      filterCriteria='';
                                      searchController.text='';
                                    });
                                  },
                                ),*/
                                SizedBox(
                                  width: 220,
                                  height: 30,
                                  child: TextField(
                                    cursorColor: const Color(0xff13322b),
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
                                    controller: searchController,
                                    style: const TextStyle(
                                      fontSize: 12, // Set smaller font size
                                      color: Colors.black, // Set text color to black
                                    ),
                                    onChanged: _onSearchChanged,
                                  ),
                                ),
                                const SizedBox(
                                    width:
                                        10),
                                BlocBuilder<AuthBloc, AuthState>(
                                            builder: (context, state) {
                                              if (state is AuthSuccess) {
                                                if (state.adminType == 'admin' || state.adminType == 'upd') {
                                                  return ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      fetchRegions();
                                    });
                                    _showDialog(context, setState);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          20), // Set button border radius
                                    ),
                                    backgroundColor: const Color(
                                        0xff13322b), // Set button background color
                                  ),
                                  child: const Text(
                                    "Add Member",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                );
                              }}
                              return Container();
                              }),        // Add spacing between filter and button
                                
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Space between the search bar and table headers
                    // Padding(
                    //   padding: const EdgeInsets.only(left: 20, right: 20),
                    //   child: Row(
                    //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //     children: [
                    //       Expanded(
                    //         child: Container(
                    //           height: 70,
                    //           decoration: BoxDecoration(
                    //             border: Border.all(color: Colors.grey),
                    //             borderRadius: BorderRadius.circular(5),
                    //           ),
                    //           child: const Center(child: Text('Card 1')),
                    //         ),
                    //       ),
                    //       const SizedBox(width: 8.0), // Space between cards
                    //       Expanded(
                    //         child: Container(
                    //           height: 70,
                    //           decoration: BoxDecoration(
                    //             border: Border.all(color: Colors.grey),
                    //             borderRadius: BorderRadius.circular(5),
                    //           ),
                    //           child: const Center(child: Text('Card 2')),
                    //         ),
                    //       ),
                    //       const SizedBox(width: 8.0), // Space between cards
                    //       Expanded(
                    //         child: Container(
                    //           height: 70,
                    //           decoration: BoxDecoration(
                    //             border: Border.all(color: Colors.grey),
                    //             borderRadius: BorderRadius.circular(5),
                    //           ),
                    //           child: const Center(child: Text('Card 3')),
                    //         ),
                    //       ),
                    //       const SizedBox(width: 8.0), // Space between cards
                    //       Expanded(
                    //         child: Container(
                    //           height: 70,
                    //           decoration: BoxDecoration(
                    //             border: Border.all(color: Colors.grey),
                    //             borderRadius: BorderRadius.circular(5),
                    //           ),
                    //           child: const Center(child: Text('Card 4')),
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    const SizedBox(height: 10),
                    // Table headers
                    Padding(
                      padding: const EdgeInsets.only(left: 20, right: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                Colors.grey, // Outline color for the outer container
                            width: 2.0, // Outline width for the outer container
                          ),
                          borderRadius: BorderRadius.circular(
                              5.0), // Outline radius for the outer container
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
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
                                    } // Reset the search query
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
                                  child:  Text(
                                    'Member Name',
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
                                    if (filterCriteria == 'membership') {
                                      filterCriteria = ''; // Clear the filterCriteria (or set to null)
                                      searchQuery = ''; // Optionally reset the search query
                                      searchController.text='';
                                    } else {
                                      filterCriteria = 'membership'; // Set to 'member' if it's not already
                                      searchQuery = ''; // Optionally reset the search query
                                      searchController.text='';
                                    }
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: filterCriteria=='membership'?const Color(0xFF13322B):Colors.transparent,
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 1.0,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'Membership Type',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: filterCriteria=='membership'?const Color(0xFFFFFFFF):Colors.black),
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
                                    if (filterCriteria == 'card_number') {
                                      filterCriteria = ''; // Clear the filterCriteria (or set to null)
                                      searchQuery = ''; // Optionally reset the search query
                                      searchController.text='';
                                    } else {
                                      filterCriteria = 'card_number'; // Set to 'member' if it's not already
                                      searchQuery = ''; // Optionally reset the search query
                                      searchController.text='';
                                    }
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: filterCriteria=='card_number'?const Color(0xFF13322B):Colors.transparent,
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 1.0,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'Health Card Info',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: filterCriteria=='card_number'?const Color(0xFFFFFFFF):Colors.black),
                                  ),
                                ),
                              ),
                            ),
                    
                            // PNP Number
                            Expanded(
                              flex: 1, // Same flex for each column
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (filterCriteria == 'contact') {
                                      filterCriteria = ''; // Clear the filterCriteria (or set to null)
                                      searchQuery = ''; // Optionally reset the search query
                                      searchController.text='';
                                    } else {
                                      filterCriteria = 'contact'; // Set to 'member' if it's not already
                                      searchQuery = ''; // Optionally reset the search query
                                      searchController.text='';
                                    }
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: filterCriteria=='contact'?const Color(0xFF13322B):Colors.transparent,
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
                                    'Phone Number',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: filterCriteria=='contact'?const Color(0xFFFFFFFF):Colors.black),
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
                                  child:  Text(
                                    'Email Address',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: filterCriteria=='email'?const Color(0xFFFFFFFF):Colors.black),
                                  ),
                                ),
                              ),
                            ),
                            // Status
                            Expanded(
                              flex: 1, // Same flex for each column
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (filterCriteria == 'is_active') {
                                      filterCriteria = ''; // Clear the filterCriteria (or set to null)
                                      searchQuery = ''; // Optionally reset the search query
                                      searchController.text='';
                                    } else {
                                      filterCriteria = 'is_active'; // Set to 'member' if it's not already
                                      searchQuery = ''; // Optionally reset the search query
                                      searchController.text='';
                                    }
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: filterCriteria=='is_active'?const Color(0xFF13322B):Colors.transparent,
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 1.0,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'Member Account Status',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: filterCriteria=='is_active'?const Color(0xFFFFFFFF):Colors.black),
                                  ),
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
                        itemCount: filteredRequests.length,
                        itemBuilder: (context, index) {
                          final request = filteredRequests[index];
                          final customerType = request['mp_customer_type_table']
                                  ?['customer_type'] ??
                              'N/A';
                          final cardTable = request['mp_card_table'];
                    
                          if (cardTable != null && cardTable.isNotEmpty) {
                            // Join the card numbers into a single string
                            cardNumbers = cardTable
                                .map((card) => card['card_number'])
                                .join(', ');
                    
                            // Function to format card numbers by adding hyphens every 4 characters
                            String formatCardNumber(String number) {
                              // Split the number into chunks of 4 characters
                              List<String> chunks = [];
                              for (int i = 0; i < number.length; i += 4) {
                                chunks.add(number.substring(i,
                                    i + 4 > number.length ? number.length : i + 4));
                              }
                              // Join chunks with hyphens
                              return chunks.join('-');
                            }
                    
                            // Split and format each card number
                            cardNumbers = cardNumbers
                                .split(', ')
                                .map(formatCardNumber)
                                .join(', ');
                          }
                    
                          return Padding(
                            padding: const EdgeInsets.only(left: 20, right: 20),
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
                                padding: const EdgeInsets.only(top: 4, bottom: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                        child: TableCellContent(
                                            content:
                                                '${request['last_name']}, ${request['first_name']}')),
                                    Expanded(
                                        child:
                                            TableCellContent(content: customerType)),
                                    Expanded(
                                        child:
                                            TableCellContent(content: cardNumbers)),
                                    Expanded(
                                        child: TableCellContent(
                                            content: request['contact_no'] ?? 'N/A')),
                                    Expanded(
                                        child: TableCellContent(
                                            content:
                                                request['email_address'] ?? 'N/A')),
                                    Expanded(
                                        child: TableCellContent(
                                            content: request['is_active']
                                                ? 'Active'
                                                : 'Inactive')),
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment
                                            .end, // Align icons to the right
                                        mainAxisSize: MainAxisSize
                                            .min, // Use min size to fit icons
                                        children: [
                                          BlocBuilder<AuthBloc, AuthState>(
                                            builder: (context, state) {
                                              if (state is AuthSuccess) {
                                                if (state.adminType == 'admin') {
                                                  return Row(
                                                    children: [
                                                      /*IconButton(
                                                        icon: const Icon(Icons
                                                            .block), // Circle with vertical line slash icon
                                                        onPressed: () {
                                                          showDialog(
                                                            context: context,
                                                            builder: (BuildContext
                                                                context) {
                                                              return AlertDialog(
                                                                title: const Text(
                                                                    'Disable Account'),
                                                                content: const Text(
                                                                    'Are you sure you want to disable the account?'),
                                                                actions: <Widget>[
                                                                  TextButton(
                                                                    child: const Text(
                                                                        'Cancel'),
                                                                    onPressed: () {
                                                                      Navigator.of(
                                                                              context)
                                                                          .pop(); // Close the modal when Cancel is pressed
                                                                    },
                                                                  ),
                                                                  TextButton(
                                                                    child: const Text(
                                                                        'Yes'),
                                                                    onPressed: () {
                                                                      // Define your action for disabling the account here
                                                                      Navigator.of(
                                                                              context)
                                                                          .pop(); // Close the modal after Yes is pressed
                                                                    },
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          );
                                                        },
                                                        tooltip:
                                                            'Disable', // Optional tooltip
                                                      ),
                                                      const SizedBox(
                                                          width:
                                                              10), */// Space between icons
                                                      IconButton(
                                                        icon: const Icon(
                                                            Icons.edit), // Edit icon
                                                        onPressed: () {
                                                          setState(() {
                                                            fetchRegions();
                                                            if(eregionController.text.isNotEmpty){
                                                              selectedRegion=regions.firstWhere(
                                                                (region) => region.regionName == eregionController.text,
                                                                orElse: () => Region(code: '', regionName: 'Not Found'),
                                                              ).code;
                                                              fetchProvinces(selectedRegion!, setState);
                                                              selectedProvince=provinces.firstWhere(
                                                                (province) => province.name == eprovinceController.text,
                                                                orElse: () => Province(code: '', name: 'Not Found'),
                                                              ).code;
                                                              fetchCities(selectedProvince!, setState);
                                                              selectedCity=cities.firstWhere(
                                                                (city) => city.name == ecityController.text,
                                                                orElse: () => City(code: '', name: 'Not Found'),
                                                              ).code;
                                                              fetchBarangays(selectedCity!, setState);
                                                            }
            
                                                          });
                                                          _showDialogEdit(context, request);
                                                        },
                                                        tooltip:
                                                            'Edit', // Optional tooltip
                                                      ),
                                                    ],
                                                  );
                                                }else if (state.adminType == 'upd') {
                                                  return Row(
                                                    children: [ // Space between icons
                                                      IconButton(
                                                        icon: const Icon(
                                                            Icons.edit), // Edit icon
                                                        onPressed: () {
                                                          setState(() {
                                                            fetchRegions();
                                                            if(eregionController.text.isNotEmpty){
                                                              selectedRegion=regions.firstWhere(
                                                                (region) => region.regionName == eregionController.text,
                                                                orElse: () => Region(code: '', regionName: 'Not Found'),
                                                              ).code;
                                                              fetchProvinces(selectedRegion!, setState);
                                                              selectedProvince=provinces.firstWhere(
                                                                (province) => province.name == eprovinceController.text,
                                                                orElse: () => Province(code: '', name: 'Not Found'),
                                                              ).code;
                                                              fetchCities(selectedProvince!, setState);
                                                              selectedCity=cities.firstWhere(
                                                                (city) => city.name == ecityController.text,
                                                                orElse: () => City(code: '', name: 'Not Found'),
                                                              ).code;
                                                              fetchBarangays(selectedCity!, setState);
                                                            }
            
                                                          });
                                                          _showDialogEdit(context, request);
                                                        },
                                                        tooltip:
                                                            'Edit', // Optional tooltip
                                                      ),
                                                    ],
                                                  );
                                                }
                                              }
                                              return const SizedBox.shrink();
                                            },
                                          ),
                                          const SizedBox(
                                              width: 10), // Space between icons
                                          IconButton(
                                            icon: const Icon(
                                                Icons.more_vert), // Three-dot icon
                                            onPressed: () {
                                              showDetails(context,request);
                                            },
                                            tooltip:
                                                'More Options', // Optional tooltip
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
            }
          )
        );
      }
    );
  }

  void _showDialogEdit(BuildContext context, final request) {
    final customerType = request['mp_customer_type_table']
                            ?['customer_type'] ??
                        'N/A';
    var cardTable = request['mp_card_table'][0];
    var selectedCard = cardTable;
      if (request['sex'] ==null) {
        _eselectedSex = '';
      }else{
        _eselectedSex = request['sex'];
      }
    
    bool hasChange=false;
    String address=request['address'] ?? '';
    String brgy=request['barangay'] ?? '';
    String city=request['city'] ?? '';
    String myProvince=request['province'] ?? '';
    String region=request['region'] ?? '';
    String postal=request['postal_code'] ?? '';
    String rbl =(selectedCard['mp_card_plan_table'] != null &&
                selectedCard['mp_card_plan_table'].isNotEmpty)
            ? selectedCard['mp_card_plan_table'][0]['mp_plan_table']
                    ['mp_plan_room_boards_table']['rb_amount'].toString() ??
                "0.0"
            : '';
    String bl =(selectedCard['mp_card_plan_table'] != null &&
                selectedCard['mp_card_plan_table'].isNotEmpty)
            ? selectedCard['mp_card_plan_table'][0]['mp_plan_table']
                    ['mp_limit_table']['amount'].toString() ??
                "0.0"
            : '';
    String et = (selectedCard['mp_card_plan_table'] != null &&
                selectedCard['mp_card_plan_table'].isNotEmpty)
            ? selectedCard['mp_card_plan_table'][0]['mp_plan_table']['enrollment_type_id'].toString() ??""
            : '';
    String pt = selectedCard['card_type'].toString() ?? '4';
    String rbt = (selectedCard['mp_card_plan_table'] != null &&
                selectedCard['mp_card_plan_table'].isNotEmpty)
            ? selectedCard['mp_card_plan_table'][0]['mp_plan_table']
                    ['mp_plan_room_boards_table']['rb_id'].toString() ??
                ""
            : '';
    String blt =(selectedCard['mp_card_plan_table'] != null &&
                selectedCard['mp_card_plan_table'].isNotEmpty)
            ? selectedCard['mp_card_plan_table'][0]['mp_plan_table']
                    ['mp_limit_table']['lt_id'].toString() ??
                ""
            : '';
    String ld= (selectedCard['mp_card_plan_table'] != null &&
                selectedCard['mp_card_plan_table'].isNotEmpty)
            ? selectedCard['mp_card_plan_table'][0]['mp_plan_table']
                    ['limit_id'].toString() ??
                ""
            : '';
    String pbd= (selectedCard['mp_card_plan_table'] != null &&
                selectedCard['mp_card_plan_table'].isNotEmpty)
            ? selectedCard['mp_card_plan_table'][0]['mp_plan_table']
                    ['prb_id'].toString() ??
                ""
            : '';
    String cid = (selectedCard['mp_card_plan_table'] != null &&
                selectedCard['mp_card_plan_table'].isNotEmpty)
            ? selectedCard['mp_card_plan_table'][0]['card_id'].toString() ??
                ""
            : '';
    String pd= (selectedCard['mp_card_plan_table'] != null &&
                selectedCard['mp_card_plan_table'].isNotEmpty)
            ? selectedCard['mp_card_plan_table'][0]['plan_id'].toString() ??
                ""
            : '';
    String mail=request['email_address'] ?? '';
    setState(() {
      efnameController.text=request['first_name'];
      emnameController.text=request['middle_name'];
      elnameController.text=request['last_name'];
      econtactNoController.text=request['contact_no'] ?? '';
      eemailController.text=mail;
      ememberTypeController.text=request['type_id'].toString();
      _birthday = request['birth_date'] != null ? DateTime.parse(request['birth_date']) : null;
      ecivilStatusController.text = request['civil_status'] ?? '';
      ehouseAddressController.text=address;
      ebarangayController.text=brgy;
      ecityController.text=city;
      eprovinceController.text=myProvince;
      eregionController.text=region;
      epostalCodeController.text=postal;
      eroomAndBoardLimitController.text=rbl;
      ebenefitLimitController.text=bl;
      eenrollmentTypeController.text=et;
      eplanTypeController.text= pt;
      eroomAndBoardTypeController.text= rbt;
      ebenefitLimitTypeController.text=blt;
      customerId = request['id'].toString();
      limit_id = ld;
      prb_id = pbd;
      card_id = cid;
      plan_id  = pd;
      if (eplanTypeController.text == '4') {
        ecardTypeController.text = 'PSMBFI';
      }
      ecardNumberController.text = selectedCard['card_number'];

    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        selectedType = 1; // Default selected value
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20), // Set dialog border radius to 20
          ),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Container(
                width: 900, // Set the fixed width of the form to 120
                height: 650,
                decoration: BoxDecoration(
                  color: Colors.white, // Set form background color to orange
                  borderRadius:
                      BorderRadius.circular(20), // Set form border radius to 20
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment
                                .spaceBetween, // Space between text and icon
                            children: [
                              const Text(
                                "Edit Member",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(
                                      0xff13322b), // Set title text color to black
                                ),
                              )
                            ],
                          ),

                          const SizedBox(height: 20), // Space above the title

                          // Personal Details Title
                          Container(
                            alignment:
                                Alignment.centerLeft, // Align to the left
                            child: const Text(
                              "Name and Contact Information", // Title for the radio buttons
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xff13322b), // Set title color
                              ),
                              textAlign:
                                  TextAlign.left, // Align text to the left
                            ),
                          ),

                          const SizedBox(height: 10), // Space below the title
                          // First Name
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // First Name
                              Expanded(
                                child: CustomTextFormField(
                                  label:const Row(
                                        children: [
                                          Text('First Name', style: TextStyle(color: Colors.black)),
                                          Text(' *', style: TextStyle(color: Colors.red)), // Asterisk in red
                                        ],
                                      ),
                                    labelStyle: const TextStyle(
                                      color: Color(0xff13322b),
                                      fontSize: 14,
                                    ),
                                    controller: efnameController,
                                    isNumeric: false,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'First name is required';
                                      }
                                      return null;
                                    }),
                              ),
                              const SizedBox(width: 10), // Space between fields
                              // Last Name
                              Expanded(
                                  child: CustomTextFormField(
                                    label:const Row(
                                        children: [
                                          Text('Middle Name', style: TextStyle(color: Colors.black)),
                                          Text(' *', style: TextStyle(color: Colors.red)), // Asterisk in red
                                        ],
                                      ),
                                      labelStyle: const TextStyle(
                                        color: Color(0xff13322b),
                                        fontSize: 14,
                                      ),
                                      controller: emnameController,
                                      isNumeric: false,
                                      validator: (value) {
                                        return null;
                                      })),
                              const SizedBox(width: 10), // Space between fields
                              // Middle Name
                              Expanded(
                                  child: CustomTextFormField(
                                    label:const Row(
                                        children: [
                                          Text('Last Name', style: TextStyle(color: Colors.black)),
                                          Text(' *', style: TextStyle(color: Colors.red)), // Asterisk in red
                                        ],
                                      ),
                                      labelStyle: const TextStyle(
                                        color: Color(0xff13322b),
                                        fontSize: 14,
                                      ),
                                      controller: elnameController,
                                      isNumeric: false,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Last name is required';
                                        }
                                        return null;
                                      })),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Contact No
                              Expanded(
                                  child: CustomTextFormField(
                                    label:const Row(
                                        children: [
                                          Text('Contact No', style: TextStyle(color: Colors.black)),
                                          Text(' *', style: TextStyle(color: Colors.red)), // Asterisk in red
                                        ],
                                      ),
                                labelStyle: const TextStyle(
                                  color: Color(0xff13322b),
                                  fontSize: 14,
                                ),
                                controller: econtactNoController,
                                isNumeric: true,
                                validator: (value) {
                                  final regExp = RegExp(r'^\d+$');
                                  if (value != null &&
                                      value.isNotEmpty &&
                                      !regExp.hasMatch(value)) {
                                    return 'Please enter a valid number';
                                  }else if(value!.length<11){
                                    return 'Contact number must be 11 digits';
                                  }
                                  return null;
                                },
                                maxLength: 11,
                              )),
                              const SizedBox(width: 10), // Space between fields
                              // Email Address
                              Expanded(
                                  child: CustomTextFormField(
                                    label:const Row(
                                        children: [
                                          Text('Email Address', style: TextStyle(color: Colors.black)),
                                          Text(' *', style: TextStyle(color: Colors.red)), // Asterisk in red
                                        ],
                                      ),
                                labelStyle: const TextStyle(
                                  color: Color(0xff13322b),
                                  fontSize: 14,
                                ),
                                controller: eemailController,
                                isNumeric: false,
                                isEmail: true,
                                validator: (value) {
                                  /*

                                  if (value == null && value!.isEmpty) {
                                    return 'Email address is required';
                                  } else if (!regExp.hasMatch(value)) {
                                    return 'Please input a valid email';
                                  }
                                  return null;*/
                                  if(value!.isNotEmpty){
                                    final regExp = RegExp(
                                    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                  );
                                    if (value == null || value.isEmpty) {
                                      return 'Email address is required';
                                    } else if (value.length < 6) {
                                      return 'Email address must be at least 6 characters long';
                                    } else if (!regExp.hasMatch(value)) {
                                      return 'Please input a valid email';
                                    }
                                  }
                                  return null;
                                },
                              )),
                              const SizedBox(width: 10), // Space between fields
                              // Password
                            ],
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Column(
                            // Use Column to stack vertically for better organization
                            children: [
                              const SizedBox(
                                  height: 10), // Space above the title

                              // Personal Details Title
                              Container(
                                alignment:
                                    Alignment.centerLeft, // Align to the left
                                child: const Text(
                                  "Personal Details", // Title for the radio buttons
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff13322b), // Set title color
                                  ),
                                  textAlign:
                                      TextAlign.left, // Align text to the left
                                ),
                              ),

                              const SizedBox(
                                  height: 10), // Space below the title

                              // Row for Sex, Birthdate, and Civil Status
                              Row(
                                children: [
                                  const SizedBox(
                                      width:
                                          5), // Optional spacing from the left

                                  // Sex Section
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Text(
                                          "Sex:", // Title for the radio buttons
                                          style: TextStyle(
                                            color: Color(
                                                0xff13322b), // Set title color
                                          ),
                                          textAlign: TextAlign.left,
                                        ),
                                        Expanded(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              SizedBox(
                                                width: 120,
                                                child: RadioListTile<String>(
                                                  title: const Text(
                                                    "Male",
                                                    style: TextStyle(
                                                      color: Color(0xff13322b),
                                                      fontSize:
                                                          12, // Set text color
                                                    ),
                                                  ),
                                                  value: "Male",
                                                  groupValue:_eselectedSex, // Set groupValue to _selectedSex
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _eselectedSex = value ?? ''; // Update the selected value
                                                    });
                                                  },
                                                  activeColor: const Color(
                                                      0xff13322b), // Set active radio button color
                                                ),
                                              ),

                                              // Female Radio Button
                                              Expanded(
                                                child: SizedBox(
                                                  width: 130,
                                                  child: RadioListTile<String>(
                                                    title: const Text(
                                                      "Female",
                                                      style: TextStyle(
                                                        color:
                                                            Color(0xff13322b),
                                                        fontSize:
                                                            12, // Set text color
                                                      ),
                                                    ),
                                                    value: "Female",
                                                    groupValue: _eselectedSex, // Set groupValue to _selectedSex
                                                    onChanged: (value) {
                                                      setState(() {
                                                        _eselectedSex = value ?? ''; // Update the selected value
                                                      });
                                                    },
                                                    activeColor: const Color(
                                                        0xff13322b), // Set active radio button color
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(
                                      width: 10), // Space between sections

                                  // Birthdate Field Section

                                 
                                  Expanded(
                                    child: Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: const Color(
                                                0xff13322b)), // Outline color
                                        borderRadius:
                                            BorderRadius.circular(5), // Radius
                                      ),
                                      child: GestureDetector(
                                        onTap: () {
                                          _selectDate(context, setState, _birthday.toString());
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              15, 11, 0, 0),
                                          child: Text(
                                            _birthday != null
                                                ? "${_birthday?.toLocal()}"
                                                    .split(' ')[0]
                                                : "Birthday (yyyy / mm / dd)",
                                            textAlign: TextAlign.left,
                                            style: const TextStyle(
                                              color: Color(0xff13322b),
                                              fontSize: 15.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                      width: 10), // Space between sections

                                  // Civil Status Field Section
                                  Expanded(
                                    child: CustomStringDropdownFormField(
                                      label: 'Civil Status',
                                      labelStyle: const TextStyle(
                                        color: Color(0xff13322b),
                                      ),
                                      items: civilStatusTypeItems,
                                      controller: ecivilStatusController,
                                      onChanged: (selectedItem) {
                                      },
                                    ),
                                  )
                                ],
                              ),

                              const SizedBox(height: 20), // Space below the row
                            ],
                          ),

                          // Personal Details Title
                          Container(
                            alignment:
                                Alignment.centerLeft, // Align to the left
                            child: const Text(
                              "Address Information", // Title for the radio buttons
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xff13322b), // Set title color
                              ),
                              textAlign:
                                  TextAlign.left, // Align text to the left
                            ),
                          ),
                          const SizedBox(height: 10),
                          // House Address
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // House Address
                              Expanded(
                                  child: CustomTextFormField(
                                    label:const Row(
                                        children: [
                                          Text('House Address', style: TextStyle(color: Colors.black)),
                                          Text(' *', style: TextStyle(color: Colors.red)), // Asterisk in red
                                        ],
                                      ),
                                      labelStyle: const TextStyle(
                                        color: Color(0xff13322b),
                                        fontSize: 14,
                                      ),
                                      controller: ehouseAddressController,
                                      isNumeric: false,
                                      validator: (value) {
                                        return null;

                                        /* if (value == null || value.isEmpty) {
                                          return 'middle name is required';
                                        }
                                        return null;*/
                                      })),
                              const SizedBox(width: 10), // Space between fields
                              Expanded(
                                child: CustomDropdown<Region>(
                                    items: regions,
                                    itemAsString: (region) => region.regionName=='MIMAROPA Region'?'Region IV-B':region.regionName,
                                    hintText: 'Select Region',
                                    selectedItem: regions.firstWhere(
                                      (region) => region.regionName == eregionController.text || 
                                                  (region.code == selectedRegion && region.regionName != eregionController.text),
                                      orElse: () => Region(code: '', regionName: 'Select Region'),
                                    ),
                                    onChanged: (Region? newValue) {
                                      setState(() {
                                        selectedRegion = newValue?.code;
                                        eregionController.text=newValue!.regionName;
                                        if(selectedRegion!='130000000'){
                                          fetchProvinces(selectedRegion!, setState);
                                        }else{
                                          fetchCities('130000000', setState);
                                        }
                                        provinces.clear(); // Clear previous provinces
                                        cities.clear(); // Clear previous cities
                                        barangays.clear(); // Clear previous barangays
                                      });
                                    },
                                  ),
                              ),
                              /*// Barangay
                              Expanded(
                                  child: CustomTextFormField(
                                    label:const Row(
                                        children: [
                                          Text('Barangay', style: TextStyle(color: Colors.black)),
                                          Text(' *', style: TextStyle(color: Colors.red)), // Asterisk in red
                                        ],
                                      ),
                                      labelStyle: const TextStyle(
                                        color: Color(0xff13322b),
                                        fontSize: 14,
                                      ),
                                      controller: ebarangayController,
                                      isNumeric: false,
                                      validator: (value) {
                                        return null;

                                        /* if (value == null || value.isEmpty) {
                                          return 'middle name is required';
                                        }
                                        return null;*/
                                      })),*/
                              const SizedBox(width: 10), // Space between fields
                              // City
                              /*Expanded(
                                  child: CustomTextFormField(
                                    label:const Row(
                                        children: [
                                          Text('City', style: TextStyle(color: Colors.black)),
                                          Text(' *', style: TextStyle(color: Colors.red)), // Asterisk in red
                                        ],
                                      ),
                                      labelStyle: const TextStyle(
                                        color: Color(0xff13322b),
                                        fontSize: 14,
                                      ),
                                      controller: ecityController,
                                      isNumeric: false,
                                      validator: (value) {
                                        return null;
                                        /* if (value == null || value.isEmpty) {
                                          return 'middle name is required';
                                        }
                                        return null;*/
                                      })),*/
                              Expanded(
                                child: CustomDropdown<Province>(
                                  items: provinces,
                                  itemAsString: (province) => province.name,
                                  hintText: 'Select Province',
                                  selectedItem: provinces.firstWhere(
                                      (province) => province.name == eprovinceController.text || 
                                                  (province.code == selectedProvince && province.name != eprovinceController.text),
                                      orElse: () => Province(code: '', name: 'Select Province'),
                                    ),
                                  onChanged: (Province? newValue) {
                                    setState(() {
                                      selectedProvince = newValue?.code;
                                      eprovinceController.text=newValue!.name;
                                      fetchCities(selectedProvince!, setState);
                                      cities.clear(); // Clear previous cities
                                      barangays.clear(); // Clear previous barangays
                                    });
                                  },
                                ),
                              ),

                            ],
                          ),
                          const SizedBox(height: 10),

                          // Province
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: CustomDropdown<City>(
                                  items: cities,
                                  itemAsString: (city) => city.name,
                                  hintText: 'Select City',
                                  selectedItem: cities.firstWhere(
                                      (city) => city.name == ecityController.text || 
                                                  (city.code == selectedCity && city.name != ecityController.text),
                                      orElse: () => City(code: '', name: 'Select City'),
                                    ),
                                  onChanged: (City? newValue) {
                                    setState(() {
                                      selectedCity = newValue?.code;
                                      ecityController.text=newValue!.name;
                                      fetchBarangays(selectedCity!, setState); // Clear previous cities
                                      barangays.clear(); // Clear previous barangays
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: CustomDropdown<Barangay>(
                                  items: barangays,
                                  itemAsString: (brgy) => brgy.name,
                                  hintText: 'Select Barangay',
                                  selectedItem: barangays.firstWhere(
                                      (brgy) => brgy.name == ebarangayController.text || 
                                                  (brgy.code == selectedBarangay && brgy.name != ebarangayController.text),
                                      orElse: () => Barangay(code: '', name: 'Select Barangay'),
                                    ),
                                  onChanged: (Barangay? newValue) {
                                    setState(() {
                                      selectedBarangay = newValue?.code;
                                      ebarangayController.text=newValue!.name;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: CustomTextFormField(
                                  label:const Row(
                                        children: [
                                          Text('Postal Code', style: TextStyle(color: Colors.black)),
                                          Text(' *', style: TextStyle(color: Colors.red)), // Asterisk in red
                                        ],
                                      ),
                                  labelStyle: const TextStyle(
                                    color: Color(0xff13322b),
                                    fontSize: 14,
                                  ),
                                  controller: epostalCodeController,
                                  isNumeric: true,
                                  validator: (value) {
                                    return null;
                                    /* if (value == null || value.isEmpty) {
                                          return 'middle name is required';
                                        }
                                        return null;*/
                                  },
                                  maxLength: 4,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 90),
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment
                                    .center, // Center the buttons horizontally
                                children: [
                                  SizedBox(
                                    width:
                                        200, // Same width for the Select Files button
                                    height:
                                        40, // Same height for the Select Files button
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          efnameController.text = '';
                                          elnameController.text = '';
                                          emnameController.text = '';
                                          econtactNoController.text = '';
                                          eemailController.text = '';
                                          epasswordController.text = '';
                                          ehouseAddressController.text = '';
                                          ebarangayController.text = '';
                                          ecityController.text = '';
                                          eprovinceController.text = '';
                                          epostalCodeController.text = '';
                                          ebirthdayController.text = '';
                                          ecivilStatusController.text = '';
                                          eregionController.text = '';
                                          ecardNumberController.text = '';
                                          ecardTypeController.text = '';
                                          ebenefitLimitController.text='';
                                          eroomAndBoardLimitController.text='';
                                          _isFormValid=true;
                                          selectedRegion=null;
                                          _eselectedSex=null;
                                          _birthday=null;
                                          regions.clear();
                                          provinces.clear();
                                          cities.clear();
                                          barangays.clear();
                                        });
                                        Navigator.pop(
                                            context); // Close the dialog
                                      },
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          side: const BorderSide(
                                              color: Color(
                                                  0xff13322b)), // Set the border color
                                        ),
                                        backgroundColor: Colors
                                            .white, // Set button background color to white
                                      ),
                                      child: const Text(
                                        'Close',
                                        style: TextStyle(
                                            color: Colors
                                                .black), // Set button text color to black for visibility
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                      width:
                                          10), // Add spacing between the buttons
                                  SizedBox(
                                    width:
                                        200, // Set a fixed width for both buttons
                                    height:
                                        40, // Set a fixed height for both buttons
                                    child: ElevatedButton(
                                      onPressed: () {
                                        /*final regExp = RegExp(
                                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                        );*/
                                        final regExp = RegExp(
                                          r'^\s*$|^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                        );

                                        if (!_formKey.currentState!.validate())return;
                                        if(econtactNoController.text.isNotEmpty && econtactNoController.text.length ==11){
                                         if(regExp.hasMatch(eemailController.text) && efnameController.text.isNotEmpty && elnameController.text.isNotEmpty && _birthday != null){
                                          showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (BuildContext context) {
                                            return Dialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        20), // Set radius to 20
                                              ),
                                              backgroundColor: Colors
                                                  .white, // Set modal background color to white
                                              child: StatefulBuilder(builder:
                                                  (BuildContext context,
                                                      setState) {
                                                return isLoading
                                                        ? const SizedBox(
                                                          width:
                                                              900, // Set the fixed width of the form to 120
                                                          height:
                                                              650,
                                                          child: Center(
                                                            child: SpinKitCircle(
                                                                color: Color(0xff13322B),
                                                                size: 50.0,
                                                              ),
                                                          ),
                                                        ) // Show spinner when loading
                                                        :Form(
                                                  key: _formKey2,
                                                  child: SizedBox(
                                                    width:
                                                        900, // Set the fixed width of the form to 120
                                                    height:
                                                        650, // Adjust height as needed to fit additional rows
                                                    child: Padding(
                                                      padding: const EdgeInsets
                                                          .only(
                                                          left: 20,
                                                          right: 20,
                                                          top:
                                                              27), // Add padding inside modal
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start, // Align content to start
                                                        children: [
                                                          const Text(
                                                            "Edit Member",
                                                            style: TextStyle(
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight.bold,
                                                              color: Color(
                                                                  0xff13322b), // Set title text color to black
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 38),
                                                  
                                                          // Personal Details Title
                                                          Container(
                                                            alignment: Alignment
                                                                .centerLeft, // Align to the left
                                                            child: const Text(
                                                              "Plan Details", // Title for the radio buttons
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Color(
                                                                    0xff13322b), // Set title color
                                                              ),
                                                              textAlign: TextAlign
                                                                  .left, // Align text to the left
                                                            ),
                                                          ),
                                                  
                                                          const SizedBox(
                                                              height:
                                                                  10), // Space below the title
                                                  
                                                          // First row with 3 text fields
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child:CustomListDropdownFormField(
                                                                              label: 'Select Member Type',
                                                                              labelStyle: const TextStyle(
                                                                                color: Color(0xff13322b),
                                                                              ),
                                                                              items: memberTypeItems,
                                                                              controller: ememberTypeController,
                                                                              onChanged: (selectedItem) {
                                                                                setState((){
                                                                                  ememberTypeController.text=ememberTypeController.text;
                                                                                });
                                                                              },
                                                                            ),
                                                              ),
                                                  
                                                              const SizedBox(
                                                                  width:
                                                                      8), // Space between text fields
                                                              Expanded(
                                                                  child:CustomListDropdownFormField(
                                                                    label:'Select Enrollment Type',
                                                                    labelStyle:const TextStyle(
                                                                      color: Color(0xff13322b),
                                                                    ),
                                                                    items:enrollmentTypeItems,
                                                                    controller:eenrollmentTypeController,
                                                                    onChanged:(selectedItem) {
                                                                      setState((){
                                                                        eenrollmentTypeController.text=eenrollmentTypeController.text;
                                                                      });
                                                                    },
                                                                  ),
                                                                ),
                                                  
                                                              const SizedBox(
                                                                  width: 8),
                                                              Expanded(
                                                                child:CustomListDropdownFormField(
                                                                    label:'Select Plan Type',
                                                                    labelStyle:const TextStyle(
                                                                      color: Color(0xff13322b),
                                                                    ),
                                                                    items:planTypeItems,
                                                                    controller:eplanTypeController,
                                                                    onChanged:(selectedItem) {
                                                                      setState((){
                                                                        eplanTypeController.text=eplanTypeController.text;
                                                                      });
                                                                    },
                                                                  ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                              height:
                                                                  16), // Add spacing between rows
                                                  
                                                          // Second row with 2 text fields
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child:CustomListDropdownFormField(
                                                                    label:'Select Room and Board Type',
                                                                    labelStyle:const TextStyle(
                                                                      color: Color(0xff13322b),
                                                                    ),
                                                                    items:roomBoardTypeItems,
                                                                    controller:eroomAndBoardTypeController,
                                                                    onChanged:(selectedItem) {
                                                                      setState((){
                                                                        eroomAndBoardTypeController.text=eroomAndBoardTypeController.text;
                                                                      });
                                                                    },
                                                                  ),
                                                              ),
                                                              const SizedBox(
                                                                  width: 8),
                                                              Expanded(
                                                                child: CustomTextFormField(
                                                                  label:const Row(
                                                                    children: [
                                                                      Text('Room and Board Limit', style: TextStyle(color: Colors.black)),
                                                                      Text(' *', style: TextStyle(color: Colors.red)), // Asterisk in red
                                                                    ],
                                                                  ),
                                                                    labelStyle: const TextStyle(
                                                                      color: Color(0xff13322b),
                                                                      fontSize: 14,
                                                                    ),
                                                                    controller: eroomAndBoardLimitController,
                                                                    isNumeric: true,
                                                                    validator: (value) {
                                                                      if (value == null || value.isEmpty) {
                                                                        return 'room and board limit required';
                                                                      }
                                                                      return null;
                                                                    }),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(height: 16), // Add spacing between rows
                                                  
                                                          // Third row with 2 text fields
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child:CustomListDropdownFormField(
                                                                    label:'Select Benefit Limit Type',
                                                                    labelStyle:const TextStyle(
                                                                      color: Color(0xff13322b),
                                                                    ),
                                                                    items:benefitTypeItems,
                                                                    controller:ebenefitLimitTypeController,
                                                                    onChanged:(selectedItem) {
                                                                      setState((){
                                                                        ebenefitLimitTypeController.text=ebenefitLimitTypeController.text;
                                                                      });
                                                                    },
                                                                  ),
                                                              ),
                                                              const SizedBox(
                                                                  width: 8),
                                                              Expanded(
                                                                child: CustomTextFormField(
                                                                  label:const Row(
                                                                    children: [
                                                                      Text('Benefit Limit', style: TextStyle(color: Colors.black)),
                                                                      Text(' *', style: TextStyle(color: Colors.red)), // Asterisk in red
                                                                    ],
                                                                  ),
                                                                    labelStyle: const TextStyle(
                                                                      color: Color(0xff13322b),
                                                                      fontSize: 14,
                                                                    ),
                                                                    controller: ebenefitLimitController,
                                                                    isNumeric: true,
                                                                    validator: (value) {
                                                                      if (value == null || value.isEmpty) {
                                                                        return 'Benefit limit required';
                                                                      }
                                                                      return null;
                                                                    }),
                                                              )
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                              height: 20),
                                                          const SizedBox(
                                                              height:
                                                                  10), // Space above the title
                                                  
                                                          // Personal Details Title
                                                          Container(
                                                            alignment: Alignment
                                                                .centerLeft, // Align to the left
                                                            child: const Text(
                                                              "Card Details", // Title for the radio buttons
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Color(
                                                                    0xff13322b), // Set title color
                                                              ),
                                                              textAlign: TextAlign
                                                                  .left, // Align text to the left
                                                            ),
                                                          ),
                                                  
                                                          const SizedBox(
                                                              height:
                                                                  10), // Space below the title
                                                  
                                                          // Fourth row with 2 text fields: Card Type and Card Number
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child:
                                                                    CustomTextFormField(
                                                                      label:const Row(
                                                                    children: [
                                                                      Text('Card Type', style: TextStyle(color: Colors.black)),
                                                                      Text(' *', style: TextStyle(color: Colors.red)), // Asterisk in red
                                                                    ],
                                                                  ),
                                                                  labelStyle:
                                                                      const TextStyle(
                                                                    color: Color(
                                                                        0xff13322b),
                                                                    fontSize: 14,
                                                                  ),
                                                                  controller:
                                                                      ecardTypeController,
                                                                  isRead: true,
                                                                  isNumeric:
                                                                      false,
                                                                  validator:
                                                                      (value) {
                                                                    //return null;
                                                                  },
                                                                  maxLength: 16,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  width: 8),
                                                              Expanded(
                                                                child:
                                                                    CustomTextFormField(
                                                                      label:const Row(
                                                                      children: [
                                                                        Text('Card Number', style: TextStyle(color: Colors.black)),
                                                                        Text(' *', style: TextStyle(color: Colors.red)), // Asterisk in red
                                                                      ],
                                                                    ),
                                                                  labelStyle:
                                                                      const TextStyle(
                                                                    color: Color(
                                                                        0xff13322b),
                                                                    fontSize: 14,
                                                                  ),
                                                                  controller:
                                                                      ecardNumberController,
                                                                  isNumeric: true,
                                                                  validator:(value) {
                                                                    //return null;
                                                                    if (value == null || value.isEmpty) {
                                                                          return 'Card number is required';
                                                                      }else if(value.length!=16){
                                                                        return 'Card number should be 16 digit';
                                                                      }
                                                                        return null;
                                                                  },
                                                                  maxLength: 16,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                              height:
                                                                  16), // Add spacing between rows
                                                  
                                                          // Fifth row with 2 text fields: Card Validity and Primary Clinic
                                                          // const Row(
                                                          //   children: [
                                                          //     Expanded(
                                                          //       child: TextField(
                                                          //         decoration:
                                                          //             InputDecoration(
                                                          //           labelText:
                                                          //               "Card Validity (YYYY/MM/DD)",
                                                          //           labelStyle: TextStyle(
                                                          //               fontSize:
                                                          //                   14,
                                                          //               color: Color(
                                                          //                   0xffB6B6B6)), // Default color
                                                          //           focusedBorder:
                                                          //               OutlineInputBorder(
                                                          //             borderSide: BorderSide(
                                                          //                 color: Colors
                                                          //                     .black,
                                                          //                 width:
                                                          //                     1.5), // Color when focused
                                                          //           ),
                                                          //           enabledBorder:
                                                          //               OutlineInputBorder(
                                                          //             borderSide: BorderSide(
                                                          //                 color: Color(
                                                          //                     0xffB6B6B6),
                                                          //                 width:
                                                          //                     1.5), // Default outline color
                                                          //           ),
                                                          //         ),
                                                          //       ),
                                                          //     ),
                                                          //     SizedBox(width: 8),
                                                          //     Expanded(
                                                          //       child: TextField(
                                                          //         decoration:
                                                          //             InputDecoration(
                                                          //           labelText:
                                                          //               "Primary Clinic",
                                                          //           labelStyle: TextStyle(
                                                          //               fontSize:
                                                          //                   14,
                                                          //               color: Color(
                                                          //                   0xffB6B6B6)), // Default color
                                                          //           focusedBorder:
                                                          //               OutlineInputBorder(
                                                          //             borderSide: BorderSide(
                                                          //                 color: Colors
                                                          //                     .black,
                                                          //                 width:
                                                          //                     1.5), // Color when focused
                                                          //           ),
                                                          //           enabledBorder:
                                                          //               OutlineInputBorder(
                                                          //             borderSide: BorderSide(
                                                          //                 color: Color(
                                                          //                     0xffB6B6B6),
                                                          //                 width:
                                                          //                     1.5), // Default outline color
                                                          //           ),
                                                          //         ),
                                                          //       ),
                                                          //     ),
                                                          //   ],
                                                          // ),
                                                  
                                                          // Footer with OK button aligned to the right
                                                          SizedBox(height:_isFormValid?160:100), // Spacing before the close button
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center, // Center the buttons horizontally
                                                            children: [
                                                              SizedBox(
                                                                width:
                                                                    200, // Same width for the Select Files button
                                                                height:
                                                                    40, // Same height for the Select Files button
                                                                child:
                                                                    ElevatedButton(
                                                                  onPressed: () {
                                                                    Navigator.pop(
                                                                        context); // Close the dialog
                                                                  },
                                                                  style: ElevatedButton
                                                                      .styleFrom(
                                                                    shape:
                                                                        RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius
                                                                              .circular(5),
                                                                      side: const BorderSide(
                                                                          color: Color(
                                                                              0xff13322b)), // Set the border color
                                                                    ),
                                                                    backgroundColor:
                                                                        Colors
                                                                            .white, // Set button background color to white
                                                                  ),
                                                                  child:
                                                                      const Text(
                                                                    'Back',
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .black), // Set button text color to black for visibility
                                                                  ),
                                                                ),
                                                              ),
                                                  
                                                              const SizedBox(
                                                                  width:
                                                                      10),
                                                              
                                                              if(efnameController.text!=request['first_name']||
                                                              emnameController.text!=request['middle_name']||
                                                              elnameController.text!=request['last_name']||
                                                              econtactNoController.text!=request['contact_no']||
                                                              eemailController.text!=mail||
                                                              _eselectedSex!=request['sex']||
                                                              _birthday!=DateTime.parse(request['birth_date'])||
                                                              ecivilStatusController.text!=request['civil_status']||
                                                              ehouseAddressController.text !=address ||
                                                              eregionController.text!=region ||
                                                              eprovinceController.text!=myProvince ||
                                                              ecityController.text!=city ||
                                                              ebarangayController.text!=brgy ||
                                                              epostalCodeController.text!=postal ||
                                                              ememberTypeController.text != request['type_id'].toString() ||
                                                              eenrollmentTypeController.text != et ||
                                                              eplanTypeController.text != pt ||
                                                              eroomAndBoardTypeController.text != rbt ||
                                                              eroomAndBoardLimitController.text != rbl ||
                                                              ebenefitLimitTypeController.text != blt
                                                              )
                                                              SizedBox(
                                                                width:
                                                                    200, // Set a fixed width for both buttons
                                                                height:
                                                                    40, // Set a fixed height for both buttons
                                                                child:
                                                                    ElevatedButton(
                                                                  onPressed: () {
                                                                    if (!_formKey2.currentState!.validate())return;
                                                                    if(eroomAndBoardLimitController.text.isNotEmpty && ebenefitLimitController.text.isNotEmpty && ecardNumberController.text.isNotEmpty){
                                                                      if(ecardNumberController.text.length==16){  
                                                                        updateMember();
                                                                        setState(() {
                                                                          isLoading=true;
                                                                        });
                                                                      }
                                                                    }
                                                                  },
                                                                  style: ElevatedButton
                                                                      .styleFrom(
                                                                    shape:
                                                                        RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius
                                                                              .circular(5),
                                                                    ),
                                                                    backgroundColor:
                                                                        const Color(
                                                                            0xff13322b), // Set button background color
                                                                  ),
                                                                  child:
                                                                      const Text(
                                                                    "Update",
                                                                    style:
                                                                        TextStyle(
                                                                      color: Colors
                                                                          .white, // Set submit button text color to white
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }),
                                            );
                                          },
                                        );
                                        }
                                      }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                        backgroundColor: const Color(
                                            0xff13322b), // Set button background color
                                      ),
                                      child: const Text(
                                        "Next",
                                        style: TextStyle(
                                          color: Colors
                                              .white, // Set submit button text color to white
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }


  void showDetails(BuildContext context, final request){
    final customerType = request['mp_customer_type_table']
                            ?['customer_type'] ??
                        'N/A';
    var cardTable = request['mp_card_table'][0];
    var selectedCard = cardTable;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor:
              Colors.white, // Set the modal background color to white
          title: const Text(
            "Member Details",
            style: TextStyle(
                color: Colors.black), // Set the title text color to black
          ),
          content: SizedBox(
            width: 600, // Set the width of the modal to accommodate the cards
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card for Personal Details
                  Card(
                    color:
                        Colors.white, // Set the card background color to white
                    elevation: 4, // Optional: Shadow effect
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Personal Details",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 10), // Add spacing
                          Table(
                            border: const TableBorder(
                              horizontalInside: BorderSide(
                                  color: Colors.grey), // Set horizontal lines
                              verticalInside:
                                  BorderSide.none, // Remove vertical lines
                              top: BorderSide(
                                  color: Colors.grey), // Top border line
                              bottom: BorderSide(
                                  color: Colors.grey), // Bottom border line
                            ),
                            children: [
                              TableRow(children: [
                                const Text("First Name",
                                    style: TextStyle(color: Colors.black)),
                                Text(request['first_name'],
                                    style:
                                        const TextStyle(color: Colors.black)),
                              ]),
                              TableRow(children: [
                                const Text("Middle Name",
                                    style: TextStyle(color: Colors.black)),
                                Text(request['middle_name'] ?? 'N/A',
                                    style:
                                        const TextStyle(color: Colors.black)),
                              ]),
                              TableRow(children: [
                                const Text("Last Name",
                                    style: TextStyle(color: Colors.black)),
                                Text(request['last_name'],
                                    style:
                                        const TextStyle(color: Colors.black)),
                              ]),
                              TableRow(children: [
                                const Text("Contact Number",
                                    style: TextStyle(color: Colors.black)),
                                Text(request['contact_no'],
                                    style:
                                        const TextStyle(color: Colors.black)),
                              ]),
                              TableRow(children: [
                                const Text("Email Address",
                                    style: TextStyle(color: Colors.black)),
                                Text(request['email_address'] ?? 'N/A',
                                    style:
                                        const TextStyle(color: Colors.black)),
                              ]),
                              TableRow(children: [
                                const Text("Sex",
                                    style: TextStyle(color: Colors.black)),
                                Text(request['sex'] ?? 'N/A',
                                    style:
                                        const TextStyle(color: Colors.black)),
                              ]),
                              TableRow(children: [
                                const Text("Birthdate",
                                    style: TextStyle(color: Colors.black)),
                                Text(request['birth_date'],
                                    style:
                                        const TextStyle(color: Colors.black)),
                              ]),
                              TableRow(children: [
                                const Text("Civil Status",
                                    style: TextStyle(color: Colors.black)),
                                Text(request['civil_status'] ?? 'N/A',
                                    style:
                                        const TextStyle(color: Colors.black)),
                              ]),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16), // Add spacing between cards

                  // Card for Address
                  Card(
                    color:
                        Colors.white, // Set the card background color to white
                    elevation: 4, // Optional: Shadow effect
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Address",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 10), // Add spacing
                          Table(
                            border: const TableBorder(
                              horizontalInside: BorderSide(
                                  color: Colors.grey), // Set horizontal lines
                              verticalInside:
                                  BorderSide.none, // Remove vertical lines
                              top: BorderSide(
                                  color: Colors.grey), // Top border line
                              bottom: BorderSide(
                                  color: Colors.grey), // Bottom border line
                            ),
                            children: [
                              TableRow(children: [
                                const Text("House Address",
                                    style: TextStyle(color: Colors.black)),
                                Text(request['address'] ?? 'N/A',
                                    style:
                                        const TextStyle(color: Colors.black)),
                              ]),
                              TableRow(children: [
                                const Text("Barangay",
                                    style: TextStyle(color: Colors.black)),
                                Text(request['barangay'] ?? 'N/A',
                                    style:
                                        const TextStyle(color: Colors.black)),
                              ]),
                              TableRow(children: [
                                const Text("City",
                                    style: TextStyle(color: Colors.black)),
                                Text(request['city'] ?? 'N/A',
                                    style:
                                        const TextStyle(color: Colors.black)),
                              ]),
                              TableRow(children: [
                                const Text("Province",
                                    style: TextStyle(color: Colors.black)),
                                Text(request['province'] ?? 'N/A',
                                    style:
                                        const TextStyle(color: Colors.black)),
                              ]),
                              TableRow(children: [
                                const Text("Region",
                                    style: TextStyle(color: Colors.black)),
                                Text(request['region'] ?? 'N/A',
                                    style:
                                        const TextStyle(color: Colors.black)),
                              ]),
                              TableRow(children: [
                                const Text("Postal Code",
                                    style: TextStyle(color: Colors.black)),
                                Text(request['postal_code'] ?? 'N/A',
                                    style:
                                        const TextStyle(color: Colors.black)),
                              ]),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16), // Add spacing between cards

                  // Card for Membership
                  Card(
                    color:
                        Colors.white, // Set the card background color to white
                    elevation: 4, // Optional: Shadow effect
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Membership",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 10), // Add spacing
  
                          Table(
  border: const TableBorder(
    horizontalInside: BorderSide(color: Colors.grey), // Set horizontal lines
    verticalInside: BorderSide.none, // Remove vertical lines
    top: BorderSide(color: Colors.grey), // Top border line
    bottom: BorderSide(color: Colors.grey), // Bottom border line
  ),
  children: [
    TableRow(children: [
      const Text("Member Type", style: TextStyle(color: Colors.black)),
      Text(customerType ?? 'N/A', style: const TextStyle(color: Colors.black)),
    ]),
    TableRow(children: [
      const Text("Enrollment Type", style: TextStyle(color: Colors.black)),
      Text(
        (selectedCard['mp_card_plan_table'] != null &&
                selectedCard['mp_card_plan_table'].isNotEmpty)
            ? selectedCard['mp_card_plan_table'][0]['mp_plan_table']
                    ['mp_enrollment_type_table']['enrollment_type'] ??
                "N/A"
            : 'N/A',
        style: const TextStyle(color: Colors.black),
      ),
    ]),
    TableRow(children: [
      const Text("Plan Type", style: TextStyle(color: Colors.black)),
      Text(
        (selectedCard['mp_card_plan_table'] != null &&
                selectedCard['mp_card_plan_table'].isNotEmpty)
            ? selectedCard['mp_card_plan_table'][0]['mp_plan_table']
                    ['mp_limit_table']['mp_limit_type_table']['limit_type'] ??
                "N/A"
            : "N/A",
        style: const TextStyle(color: Colors.black),
      ),
    ]),
    TableRow(children: [
      const Text("Room and Board Type", style: TextStyle(color: Colors.black)),
      Text(
        (selectedCard['mp_card_plan_table'] != null &&
                selectedCard['mp_card_plan_table'].isNotEmpty)
            ? selectedCard['mp_card_plan_table'][0]['mp_plan_table']
                    ['mp_plan_room_boards_table']['mp_room_boards_table']
                ['room_boards'] ??
                "N/A"
            : 'N/A',
        style: const TextStyle(color: Colors.black),
      ),
    ]),
    TableRow(children: [
      const Text("Room and Board Limit", style: TextStyle(color: Colors.black)),
      Text(
        (selectedCard['mp_card_plan_table'] != null &&
                selectedCard['mp_card_plan_table'].isNotEmpty)
            ? selectedCard['mp_card_plan_table'][0]['mp_plan_table']
                    ['mp_plan_room_boards_table']['rb_amount']?.toString() ??
                "0.0"
            : 'N/A',
        style: const TextStyle(color: Colors.black),
      ),
    ]),
    TableRow(children: [
      const Text("Benefit Limit", style: TextStyle(color: Colors.black)),
      Text(
        (selectedCard['mp_card_plan_table'] != null &&
                selectedCard['mp_card_plan_table'].isNotEmpty)
            ? selectedCard['mp_card_plan_table'][0]['mp_plan_table']
                    ['mp_limit_table']['amount']?.toString() ??
                "0.0"
            : 'N/A',
        style: const TextStyle(color: Colors.black),
      ),
    ]),
    TableRow(children: [
      const Text("Card Type", style: TextStyle(color: Colors.black)),
      Text(
        (selectedCard['mp_card_variants_table'] != null)
            ? selectedCard['mp_card_variants_table']['card_variant'] ?? 'N/A'
            : 'N/A',
        style: const TextStyle(color: Colors.black),
      ),
    ]),
    TableRow(children: [
      const Text("Card Number", style: TextStyle(color: Colors.black)),
      Text(
        selectedCard['card_number'] ?? 'N/A',
        style: const TextStyle(color: Colors.black),
      ),
    ]),
    TableRow(children: [
      const Text("Card Validity", style: TextStyle(color: Colors.black)),
      Text(
        selectedCard['expiration_date'] ?? 'N/A',
        style: const TextStyle(color: Colors.black),
      ),
    ]),
  ],
),
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
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Close", style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  void _showDialog(BuildContext context, StateSetter setState) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        selectedType = 1; // Default selected value
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20), // Set dialog border radius to 20
          ),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Container(
                width: 900, // Set the fixed width of the form to 120
                height: 650,
                decoration: BoxDecoration(
                  color: Colors.white, // Set form background color to orange
                  borderRadius:
                      BorderRadius.circular(20), // Set form border radius to 20
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment
                                .spaceBetween, // Space between text and icon
                            children: [
                              const Text(
                                "Add Member",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(
                                      0xff13322b), // Set title text color to black
                                ),
                              ),
                              SizedBox(
                                width:
                                    200, // Set a fixed width for both buttons
                                height:
                                    40, // Set a fixed height for both buttons
                                child: ElevatedButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (BuildContext context) {
                                        return Dialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(
                                                  20), // Optional: rounded corners
                                            ),
                                            backgroundColor: const Color(
                                                0xffFFFFFF), // Set button background color
                                            child: StatefulBuilder(builder:
                                                (BuildContext context,
                                                    StateSetter setState) {
                                              return SizedBox(
                                                width: 900,
                                                height: 650,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start, // Align to the left
                                                  children: [
                                                    // Add your modal content here
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 20,
                                                              right: 20,
                                                              top: 20),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween, // Space between text and icon
                                                        children: [
                                                          const Text(
                                                            "Add Member",
                                                            style: TextStyle(
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Color(
                                                                  0xff13322b), // Set title text color to black
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width:
                                                                200, // Same width for the Select Files button
                                                            height:
                                                                40, // Same height for the Select Files button
                                                            child:
                                                                ElevatedButton(
                                                              onPressed: () {
                                                                _pickFiles(
                                                                    setState);
                                                              }, // Function to pick files
                                                              style:
                                                                  ElevatedButton
                                                                      .styleFrom(
                                                                shape:
                                                                    RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              5),
                                                                ),
                                                                backgroundColor:
                                                                    const Color(
                                                                        0xff13322b), // Set button background color to black
                                                              ),
                                                              child: const Text(
                                                                'Attach Files',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white), // Set button text color to white
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        height:
                                                            16), // Spacing below the row

                                                    // Add the "Files" text
                                                    const Padding(
                                                      padding: EdgeInsets.only(
                                                          left: 40),
                                                      child: Text(
                                                        "Files",
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontFamily: 'Roboto',
                                                          color: Color(
                                                              0xff13322b), // Set text color to match the design
                                                        ),
                                                      ),
                                                    ),

                                                    // Add the card below the text
                                                    if (_selectedFiles
                                                            .isNotEmpty &&
                                                        !isLoading)
                                                      SizedBox(
                                                        height:
                                                            437, // Adjust height to accommodate both file name and button
                                                        child: ListView.builder(
                                                          itemCount:
                                                              _selectedFiles
                                                                  .length,
                                                          itemBuilder:
                                                              (context, index) {
                                                            return ListTile(
                                                              title: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween, // Space between file name and remove button
                                                                children: [
                                                                  const SizedBox(
                                                                      width:
                                                                          23),
                                                                  Expanded(
                                                                    child: Text(
                                                                      _selectedFiles[
                                                                              index]
                                                                          .name,
                                                                      style: const TextStyle(
                                                                          color:
                                                                              Color(0xff13322b)), // Display file name
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis, // Handle long file names
                                                                    ),
                                                                  ),
                                                                  IconButton(
                                                                    icon: const Icon(
                                                                        Icons
                                                                            .remove_circle,
                                                                        color: Color(
                                                                            0xff13322b)), // Remove icon
                                                                    onPressed:
                                                                        () {
                                                                      setState(
                                                                          () {
                                                                        _selectedFiles
                                                                            .removeAt(index); // Remove the file at the current index
                                                                      });
                                                                    },
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      )
                                                    else if (_selectedFiles
                                                            .isEmpty &&
                                                        !isLoading)
                                                      Center(
                                                        child: Card(
                                                          elevation:
                                                              4, // Add shadow to the card
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                            side:
                                                                const BorderSide(
                                                              color: Colors
                                                                  .black, // Set card outline color to black
                                                              width:
                                                                  1, // Set the width of the outline
                                                            ),
                                                          ),
                                                          color: Colors
                                                              .white, // Set card background color to white
                                                          child: const SizedBox(
                                                            height: 437,
                                                            width: 837,
                                                            child: Center(
                                                              child: Text(
                                                                'Uploaded Files...',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 16,
                                                                  color: Color(
                                                                      0xff13322b), // Text color for the card content
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                    else if (_selectedFiles
                                                            .isNotEmpty &&
                                                        isLoading)
                                                      const SizedBox(
                                                        height: 437,
                                                        width: 837,
                                                        child:  Center(
                                                              child: SpinKitCircle(
                                                                  color: Color(0xff13322B),
                                                                  size: 50.0,
                                                                ),
                                                            ),
                                                      ),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .end, // Align the text to the right
                                                      children: [
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  right: 40),
                                                          child: Text(
                                                            'Total Files Attached: ${_selectedFiles.length}',
                                                            style:
                                                                const TextStyle(
                                                              fontFamily:
                                                                  "Roboto",
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 11,
                                                              color: Colors
                                                                  .black, // Text color
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),

                                                    // Close button
                                                    const SizedBox(
                                                        height:
                                                            22), // Spacing before the close button
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center, // Center the buttons horizontally
                                                      children: [
                                                        SizedBox(
                                                          width:
                                                              200, // Same width for the Select Files button
                                                          height:
                                                              40, // Same height for the Select Files button
                                                          child: ElevatedButton(
                                                            onPressed:
                                                                !isLoading
                                                                    ? () {
                                                                        setState(
                                                                            () {
                                                                          _selectedFiles =
                                                                              [];
                                                                        });
                                                                        Navigator.pop(
                                                                            context); // Close the dialog
                                                                      }
                                                                    : null,
                                                            style:
                                                                ElevatedButton
                                                                    .styleFrom(
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            5),
                                                                side: const BorderSide(
                                                                    color: Color(
                                                                        0xff13322b)), // Set the border color
                                                              ),
                                                              backgroundColor:
                                                                  Colors
                                                                      .white, // Set button background color to white
                                                            ),
                                                            child: const Text(
                                                              'Close',
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .black), // Set button text color to black for visibility
                                                            ),
                                                          ),
                                                        ),

                                                        const SizedBox(
                                                            width:
                                                                10), // Add spacing between the buttons
                                                        SizedBox(
                                                          width:
                                                              200, // Set a fixed width for both buttons
                                                          height:
                                                              40, // Set a fixed height for both buttons
                                                          child: ElevatedButton(
                                                            onPressed:
                                                                !isLoading
                                                                    ? () {
                                                                        if (_selectedFiles
                                                                            .isNotEmpty) {
                                                                          _uploadFiles(
                                                                              setState);
                                                                          setState(
                                                                              () {
                                                                            isLoading =
                                                                                true;
                                                                          });
                                                                        } else {
                                                                          _showMessage(
                                                                              'Please select files to be uploaded',
                                                                              'Alert');
                                                                        }
                                                                      }
                                                                    : null,
                                                            style:
                                                                ElevatedButton
                                                                    .styleFrom(
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            5),
                                                                side: const BorderSide(
                                                                    color: Color(
                                                                        0xff13322b)),
                                                              ),
                                                              backgroundColor:
                                                                  const Color(
                                                                      0xff13322b), // Set button background color
                                                            ),
                                                            child: Text(
                                                              "Submit",
                                                              style: TextStyle(
                                                                color: isLoading
                                                                    ? const Color(
                                                                        0xff13322b)
                                                                    : Colors
                                                                        .white, // Set submit button text color to white
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }));
                                      },
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    backgroundColor: const Color(
                                        0xff13322b), // Set button background color
                                  ),
                                  child: const Text(
                                    "Bulk Upload",
                                    style: TextStyle(
                                      color: Colors
                                          .white, // Set submit button text color to white
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),
                          const SizedBox(height: 10), // Space above the title

                          // Personal Details Title
                          Container(
                            alignment:
                                Alignment.centerLeft, // Align to the left
                            child: const Text(
                              "Name and Contact Information", // Title for the radio buttons
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xff13322b), // Set title color
                              ),
                              textAlign:
                                  TextAlign.left, // Align text to the left
                            ),
                          ),

                          const SizedBox(height: 10), // Space below the title
                          // First Name
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // First Name
                              Expanded(
                                child: CustomTextFormField(
                                    label:const Row(
                                      children: [
                                        Text('First Name', style: TextStyle(color: Colors.black)),
                                        Text(' *', style: TextStyle(color: Colors.red)), // Asterisk in red
                                      ],
                                    ),
                                    labelStyle: const TextStyle(
                                      color: Color(0xff13322b),
                                      fontSize: 14,
                                    ),
                                    controller: fnameController,
                                    isNumeric: false,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'First name is required';
                                      }
                                      return null;
                                    }),
                              ),
                              const SizedBox(width: 10), // Space between fields
                              // Last Name
                              Expanded(
                                  child: CustomTextFormField(
                                    label:const Row(
                                        children: [
                                          Text('Middle Name', style: TextStyle(color: Colors.black)),
                                          Text(' *', style: TextStyle(color: Colors.red)), // Asterisk in red
                                        ],
                                      ),
                                      labelStyle: const TextStyle(
                                        color: Color(0xff13322b),
                                        fontSize: 14,
                                      ),
                                      controller: mnameController,
                                      isNumeric: false,
                                      validator: (value) {
                                        return null;
                                      })),
                              const SizedBox(width: 10), // Space between fields
                              // Middle Name
                              Expanded(
                                  child: CustomTextFormField(
                                      label:const Row(
                                        children: [
                                          Text('Last Name', style: TextStyle(color: Colors.black)),
                                          Text(' *', style: TextStyle(color: Colors.red)), // Asterisk in red
                                        ],
                                      ),
                                      labelStyle: const TextStyle(
                                        color: Color(0xff13322b),
                                        fontSize: 14,
                                      ),
                                      controller: lnameController,
                                      isNumeric: false,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Last name is required';
                                        }
                                        return null;
                                      })),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Contact No
                              Expanded(
                                  child: CustomTextFormField(
                                  label:const Row(
                                        children: [
                                          Text('Contact No', style: TextStyle(color: Colors.black)),
                                          Text(' *', style: TextStyle(color: Colors.red)), // Asterisk in red
                                        ],
                                      ),
                                labelStyle: const TextStyle(
                                  color: Color(0xff13322b),
                                  fontSize: 14,
                                ),
                                controller: contactNoController,
                                isNumeric: true,
                                validator: (value) {
                                  final regExp = RegExp(r'^\d+$');
                                  if (value != null &&
                                      value.isNotEmpty &&
                                      !regExp.hasMatch(value)) {
                                    return 'Please enter a valid number';
                                  }
                                  return null;
                                },
                                maxLength: 11,
                              )),
                              const SizedBox(width: 10), // Space between fields
                              // Email Address
                              Expanded(
                                  child: CustomTextFormField(
                                  label:const Row(
                                        children: [
                                          Text('Email Address', style: TextStyle(color: Colors.black)),
                                          Text(' *', style: TextStyle(color: Colors.red)), // Asterisk in red
                                        ],
                                      ),
                                labelStyle: const TextStyle(
                                  color: Color(0xff13322b),
                                  fontSize: 14,
                                ),
                                controller: emailController,
                                isNumeric: false,
                                isEmail: true,
                                validator: (value) {
                                  /*final regExp = RegExp(
                                    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                  );

                                  if (value == null && value!.isEmpty) {
                                    return 'Email address is required';
                                  } else if (!regExp.hasMatch(value)) {
                                    return 'Please input a valid email';
                                  }
                                  return null;*/
                                  if(value!.isNotEmpty){
                                    final regExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',);
                                    if (value == null || value.isEmpty) {
                                      return 'Email address is required';
                                    } else if (value.length < 6) {
                                      return 'Email address must be at least 6 characters long';
                                    } else if (!regExp.hasMatch(value)) {
                                      return 'Please input a valid email';
                                    }
                                  }
                                  return null;
                                },
                              )),
                              const SizedBox(width: 10), // Space between fields
                              // Password
                            ],
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Column(
                            // Use Column to stack vertically for better organization
                            children: [
                              const SizedBox(
                                  height: 10), // Space above the title

                              // Personal Details Title
                              Container(
                                alignment:
                                    Alignment.centerLeft, // Align to the left
                                child: const Text(
                                  "Personal Details", // Title for the radio buttons
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff13322b), // Set title color
                                  ),
                                  textAlign:
                                      TextAlign.left, // Align text to the left
                                ),
                              ),

                              const SizedBox(
                                  height: 10), // Space below the title

                              // Row for Sex, Birthdate, and Civil Status
                              Row(
                                children: [
                                  const SizedBox(
                                      width:
                                          5), // Optional spacing from the left

                                  // Sex Section
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                       /*if(noSex) 
                                       Text(
                                          "Sex is required", // Title for the radio buttons
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xffff0000).withOpacity(0.35),
                                            fontSize: 11 // Set title color
                                          ),
                                          textAlign:
                                              TextAlign.left, // Align text to the left
                                        ),*/
                                        Row(
                                          children: [
                                            const Text(
                                              "Sex:", // Title for the radio buttons
                                              style: TextStyle(
                                                color: Color(
                                                    0xff13322b), // Set title color
                                              ),
                                              textAlign: TextAlign.left,
                                            ),
                                            Expanded(
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  SizedBox(
                                                    width: 120,
                                                    child: RadioListTile<String>(
                                                      title: const Text(
                                                        "Male",
                                                        style: TextStyle(
                                                          color: Color(0xff13322b),
                                                          fontSize:
                                                              12, // Set text color
                                                        ),
                                                      ),
                                                      value: "Male",
                                                      groupValue:
                                                          _selectedSex, // Set groupValue to _selectedSex
                                                      onChanged: (value) {
                                                        setState(() {
                                                          _selectedSex =
                                                              value; // Update the selected value
                                                        });
                                                      },
                                                      activeColor: const Color(
                                                          0xff13322b), // Set active radio button color
                                                    ),
                                                  ),
                                        
                                                  // Female Radio Button
                                                  Expanded(
                                                    child: SizedBox(
                                                      width: 130,
                                                      child: RadioListTile<String>(
                                                        title: const Text(
                                                          "Female",
                                                          style: TextStyle(
                                                            color:
                                                                Color(0xff13322b),
                                                            fontSize:
                                                                12, // Set text color
                                                          ),
                                                        ),
                                                        value: "Female",
                                                        groupValue:
                                                            _selectedSex, // Set groupValue to _selectedSex
                                                        onChanged: (value) {
                                                          setState(() {
                                                            _selectedSex =
                                                                value; // Update the selected value
                                                          });
                                                        },
                                                        activeColor: const Color(
                                                            0xff13322b), // Set active radio button color
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(
                                      width: 10), // Space between sections

                                  // Birthdate Field Section
                                  Expanded(
                                    child: Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Color(!isDateError?0xff13322b:0xffff0000).withOpacity(!isDateError?0.5:0.25)), // Outline color
                                        borderRadius:
                                            BorderRadius.circular(5), // Radius
                                      ),
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            isDateError=false;
                                          });
                                          _selectDate(context, setState, _birthday.toString());
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              15, 11, 0, 0),
                                          child: Text(
                                          _birthday != null
                                              ? "${_birthday?.toLocal()}".split(' ')[0]
                                              : dateLabel, // Updated text when _birthday is null
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                            color: Color(!isDateError?0xff13322b:0xffff0000).withOpacity(!isDateError?1:0.35),
                                            fontSize: 15.0,
                                          ),
                                        ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                      width: 10), // Space between sections

                                  // Civil Status Field Section
                                  Expanded(
                                    child: CustomStringDropdownFormField(
                                      label: 'Civil Status',
                                      labelStyle: const TextStyle(
                                        color: Color(0xff13322b),
                                      ),
                                      items: civilStatusTypeItems,
                                      controller: civilStatusController,
                                      onChanged: (selectedItem) {
                                      },
                                    ),
                                  )

                                ],
                              ),

                              const SizedBox(height: 20), // Space below the row
                            ],
                          ),

                          // Personal Details Title
                          Container(
                            alignment:
                                Alignment.centerLeft, // Align to the left
                            child: const Text(
                              "Address Information", // Title for the radio buttons
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xff13322b), // Set title color
                              ),
                              textAlign:
                                  TextAlign.left, // Align text to the left
                            ),
                          ),
                          const SizedBox(height: 10),
                          // House Address
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // House Address
                              Expanded(
                                  child: CustomTextFormField(
                                    label:const Row(
                                        children: [
                                          Text('House Address', style: TextStyle(color: Colors.black)),
                                          Text(' *', style: TextStyle(color: Colors.red)), // Asterisk in red
                                        ],
                                      ),
                                      labelStyle: const TextStyle(
                                        color: Color(0xff13322b),
                                        fontSize: 14,
                                      ),
                                      controller: houseAddressController,
                                      isNumeric: false,
                                      validator: (value) {
                                        return null;

                                        /* if (value == null || value.isEmpty) {
                                          return 'middle name is required';
                                        }
                                        return null;*/
                                      })),
                              const SizedBox(width: 10), // Space between fields
                              // Barangay
                              Expanded(
                                child: CustomDropdown<Region>(
                                    items: regions,
                                    itemAsString: (region) => region.regionName=='MIMAROPA Region'?'Region IV-B':region.regionName,
                                    hintText: 'Select Region',
                                    selectedItem: regions.firstWhere(
                                      (region) => region.code == selectedRegion,
                                      orElse: () => Region(code: '', regionName: 'Select Region'),
                                    ),
                                    onChanged: (Region? newValue) {
                                      setState(() {
                                        selectedRegion = newValue?.code;
                                        eregionController.text=newValue!.regionName;
                                        if(selectedRegion!='130000000'){
                                          fetchProvinces(selectedRegion!, setState);
                                        }else{
                                          fetchCities('130000000', setState);
                                        }
                                        provinces.clear(); // Clear previous provinces
                                        cities.clear(); // Clear previous cities
                                        barangays.clear(); // Clear previous barangays
                                      });
                                    },
                                  ),
                              ),  
                              
                              const SizedBox(width: 10), // Space between fields
                              // Province
                              Expanded(
                                child: CustomDropdown<Province>(
                                  items: provinces,
                                  itemAsString: (province) => province.name,
                                  hintText: 'Select Province',
                                  selectedItem: provinces.firstWhere(
                                    (province) => province.code == selectedProvince,
                                    orElse: () => Province(code: '', name: 'Select Province'),
                                  ),
                                  onChanged: (Province? newValue) {
                                    setState(() {
                                      selectedProvince = newValue?.code;
                                      provinceController.text=newValue!.name;
                                      fetchCities(selectedProvince!, setState);
                                      cities.clear(); // Clear previous cities
                                      barangays.clear(); // Clear previous barangays
                                    });
                                  },
                                ),
                              ),
                              /*Expanded(
                                  child: CustomTextFormField(
                                    label:const Row(
                                        children: [
                                          Text('Province', style: TextStyle(color: Colors.black)),
                                          Text(' *', style: TextStyle(color: Colors.red)), // Asterisk in red
                                        ],
                                      ),
                                      labelStyle: const TextStyle(
                                        color: Color(0xff13322b),
                                        fontSize: 14,
                                      ),
                                      controller: provinceController,
                                      isNumeric: false,
                                      validator: (value) {
                                        return null;

                                        /* if (value == null || value.isEmpty) {
                                          return 'middle name is required';
                                        }
                                        return null;*/
                                      })),*/
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: CustomDropdown<City>(
                                  items: cities,
                                  itemAsString: (city) => city.name,
                                  hintText: 'Select City',
                                  selectedItem: cities.firstWhere(
                                    (city) => city.code == selectedCity,
                                    orElse: () => City(code: '', name: 'Select City'),
                                  ),
                                  onChanged: (City? newValue) {
                                    setState(() {
                                      selectedCity = newValue?.code;
                                      cityController.text=newValue!.name;
                                      fetchBarangays(selectedCity!, setState); // Clear previous cities
                                      barangays.clear(); // Clear previous barangays
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              /*Expanded(
                                  child: CustomTextFormField(
                                    label:const Row(
                                        children: [
                                          Text('Region', style: TextStyle(color: Colors.black)),
                                          Text(' *', style: TextStyle(color: Colors.red)), // Asterisk in red
                                        ],
                                      ),
                                      labelStyle: const TextStyle(
                                        color: Color(0xff13322b),
                                        fontSize: 14,
                                      ),
                                      controller: regionController,
                                      isNumeric: false,
                                      validator: (value) {
                                        return null;

                                        /* if (value == null || value.isEmpty) {
                                          return 'middle name is required';
                                        }
                                        return null;*/
                                      })),*/
                              Expanded(
                                child: CustomDropdown<Barangay>(
                                  items: barangays,
                                  itemAsString: (brgy) => brgy.name,
                                  hintText: 'Select Barangay',
                                  selectedItem: barangays.firstWhere(
                                    (brgy) => brgy.code == selectedBarangay,
                                    orElse: () => Barangay(code: '', name: 'Select Barangay'),
                                  ),
                                  onChanged: (Barangay? newValue) {
                                    setState(() {
                                      selectedBarangay = newValue?.code;
                                      barangayController.text=newValue!.name;
                                      print(barangayController.text);
                                    });
                                  },
                                ),
                              ),
                                    
                              const SizedBox(width: 10),
                              Expanded(
                                child: CustomTextFormField(
                                  label:const Row(
                                        children: [
                                          Text('Postal Code', style: TextStyle(color: Colors.black)),
                                          Text(' *', style: TextStyle(color: Colors.red)), // Asterisk in red
                                        ],
                                      ),
                                  labelStyle: const TextStyle(
                                    color: Color(0xff13322b),
                                    fontSize: 14,
                                  ),
                                  controller: postalCodeController,
                                  isNumeric: true,
                                  validator: (value) {
                                    return null;

                                    /* if (value == null || value.isEmpty) {
                                          return 'middle name is required';
                                        }
                                        return null;*/
                                  },
                                  maxLength: 4,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 90),
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment
                                    .center, // Center the buttons horizontally
                                children: [
                                  SizedBox(
                                    width:
                                        200, // Same width for the Select Files button
                                    height:
                                        40, // Same height for the Select Files button
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          fnameController.text = '';
                                          lnameController.text = '';
                                          mnameController.text = '';
                                          contactNoController.text = '';
                                          emailController.text = '';
                                          passwordController.text = '';
                                          houseAddressController.text = '';
                                          barangayController.text = '';
                                          cityController.text = '';
                                          provinceController.text = '';
                                          postalCodeController.text = '';
                                          birthdayController.text = '';
                                          civilStatusController.text = '';
                                          regionController.text = '';
                                          cardNumberController.text = '';
                                          cardTypeController.text = '';
                                          benefitLimitController.text='';
                                          roomAndBoardLimitController.text='';
                                          _selectedFiles = [];
                                          _birthday=null;
                                          _isFormValid=true;
                                          //regions.clear();
                                          provinces.clear();
                                          cities.clear();
                                          barangays.clear();
                                          selectedRegion=null;
                                          _selectedSex=null;
                                          noSex=false;
                                          isDateError=false;
                                          dateLabel='yyyy-mm-dd';
                                        });
                                        Navigator.pop(
                                            context); // Close the dialog
                                      },
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          side: const BorderSide(
                                              color: Color(
                                                  0xff13322b)), // Set the border color
                                        ),
                                        backgroundColor: Colors
                                            .white, // Set button background color to white
                                      ),
                                      child: const Text(
                                        'Close',
                                        style: TextStyle(
                                            color: Colors
                                                .black), // Set button text color to black for visibility sanzui
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                      width:
                                          10), // Add spacing between the buttons
                                  SizedBox(
                                    width:
                                        200, // Set a fixed width for both buttons
                                    height:
                                        40, // Set a fixed height for both buttons
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (!_formKey.currentState!.validate())return;
                                        if(_birthday==null){
                                          setState(() {
                                            isDateError=true;
                                            dateLabel='Birthday is required';
                                          });
                                        }else{
                                          int age = calculateAge(_birthday.toString());
                                          if(age<16){
                                            setState(() {
                                              isDateError=true;
                                              noSex=false;
                                              _birthday=null;
                                              dateLabel='Invalid date; age must be 16 or older.';
                                            });
                                          }else{
                                            if(fnameController.text.isNotEmpty && lnameController.text.isNotEmpty&&_birthday!=null){
                                                setState(() {
                                                  isDateError=false;
                                                  noSex=false;
                                                  memberTypeController.text = '1';
                                                  enrollmentTypeController.text = '1';
                                                  planTypeController.text = '4';
                                                  roomAndBoardTypeController.text = '2';
                                                  benefitLimitTypeController.text = '1';
                                                  if (planTypeController.text == '4') {
                                                    cardTypeController.text = 'PSMBFI';
                                                  }
                                                });

                                                showDialog(
                                                context: context,
                                                barrierDismissible: false,
                                                builder: (BuildContext context) {
                                                  return Dialog(
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20), // Set radius to 20
                                                    ),
                                                    backgroundColor: Colors
                                                        .white, // Set modal background color to white
                                                    child: StatefulBuilder(builder:
                                                        (BuildContext innerContext,
                                                            setState) {
                                                      return isLoading
                                                        ? const SizedBox(
                                                          width:
                                                              900, // Set the fixed width of the form to 120
                                                          height:
                                                              650,
                                                          child: Center(
                                                            child: SpinKitCircle(
                                                                color: Color(0xff13322B),
                                                                size: 50.0,
                                                              ),
                                                          ),
                                                        ) // Show spinner when loading
                                                        :Form(
                                                        key: _formKey2,
                                                        child: SizedBox(
                                                          width:
                                                              900, // Set the fixed width of the form to 120
                                                          height:
                                                              650, // Adjust height as needed to fit additional rows
                                                          child: Padding(
                                                            padding: const EdgeInsets
                                                                .only(
                                                                left: 20,
                                                                right: 20,
                                                                top:
                                                                    27), // Add padding inside modal
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start, // Align content to start
                                                              children: [
                                                                const Text(
                                                                  "Add Member",
                                                                  style: TextStyle(
                                                                    fontSize: 18,
                                                                    fontWeight:
                                                                        FontWeight.bold,
                                                                    color: Color(
                                                                        0xff13322b), // Set title text color to black
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    height: 38),
                                                        
                                                                // Personal Details Title
                                                                Container(
                                                                  alignment: Alignment
                                                                      .centerLeft, // Align to the left
                                                                  child: const Text(
                                                                    "Plan Details", // Title for the radio buttons
                                                                    style: TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: Color(
                                                                          0xff13322b), // Set title color
                                                                    ),
                                                                    textAlign: TextAlign
                                                                        .left, // Align text to the left
                                                                  ),
                                                                ),
                                                        
                                                                const SizedBox(
                                                                    height:
                                                                        10), // Space below the title
                                                        
                                                                // First row with 3 text fields
                                                                Row(
                                                                  children: [
                                                                    Expanded(
                                                                      child:CustomListDropdownFormField(
                                                                              label: 'Select Member Type',
                                                                              labelStyle: const TextStyle(
                                                                                color: Color(0xff13322b),
                                                                              ),
                                                                              items: memberTypeItems,
                                                                              controller: memberTypeController,
                                                                              onChanged: (selectedItem) {
                                                                                // You can use the selected item here for further actions
                                                                                print('Selected item: ${selectedItem?.status}');
                                                                              },
                                                                            ),
                                                                    ),
                                                        
                                                                    const SizedBox(
                                                                        width:
                                                                            8), // Space between text fields
                                                                    Expanded(
                                                                      child:CustomListDropdownFormField(
                                                                              label: 'Select Enrollment Type',
                                                                              labelStyle: const TextStyle(
                                                                                color: Color(0xff13322b),
                                                                              ),
                                                                              items: enrollmentTypeItems,
                                                                              controller: enrollmentTypeController,
                                                                              onChanged: (selectedItem) {
                                                                              },
                                                                            )
                                                                    ),
                                                        
                                                                    const SizedBox(
                                                                        width: 8),
                                                                    Expanded(
                                                                      child:CustomListDropdownFormField(
                                                                              label: 'Select Plan Type',
                                                                              labelStyle: const TextStyle(
                                                                                color: Color(0xff13322b),
                                                                              ),
                                                                              items: planTypeItems,
                                                                              controller: planTypeController,
                                                                              onChanged: (selectedItem) {
                                                                              },
                                                                            ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                const SizedBox(
                                                                    height:
                                                                        16), // Add spacing between rows
                                                        
                                                                // Second row with 2 text fields
                                                                Row(
                                                                  children: [
                                                                    Expanded(
                                                                      child:CustomListDropdownFormField(
                                                                              label: 'Select Room and Board Type',
                                                                              labelStyle: const TextStyle(
                                                                                color: Color(0xff13322b),
                                                                              ),
                                                                              items: roomBoardTypeItems,
                                                                              controller: roomAndBoardTypeController,
                                                                              onChanged: (selectedItem) {
                                                                              },
                                                                            ),
                                                                    ),
                                                                    const SizedBox(
                                                                        width: 8),
                                                                    Expanded(
                                                                      child: CustomTextFormField(
                                                                        label:const Row(
                                                                            children: [
                                                                              Text('Room and Board Limit', style: TextStyle(color: Colors.black)),
                                                                              Text(' *', style: TextStyle(color: Colors.red)), // Asterisk in red
                                                                            ],
                                                                          ),
                                                                          labelStyle: const TextStyle(
                                                                            color: Color(0xff13322b),
                                                                            fontSize: 14,
                                                                          ),
                                                                          controller: roomAndBoardLimitController,
                                                                          isNumeric: true,
                                                                          maxLength: 5,
                                                                          validator: (value) {
                                                                            if (value == null || value.isEmpty) {
                                                                              return 'Room and board limit required';
                                                                            }
                                                                            return null;
                                                                          }),
                                                                    )
                                                                  ],
                                                                ),
                                                                const SizedBox(
                                                                    height:
                                                                        16), // Add spacing between rows
                                                        
                                                                // Third row with 2 text fields
                                                                Row(
                                                                  children: [
                                                                    Expanded(
                                                                      child:CustomListDropdownFormField(
                                                                              label: 'Select Room and Board Type',
                                                                              labelStyle: const TextStyle(
                                                                                color: Color(0xff13322b),
                                                                              ),
                                                                              items: benefitTypeItems,
                                                                              controller: benefitLimitTypeController,
                                                                              onChanged: (selectedItem) {
                                                                              },
                                                                            ),
                                                                    ),
                                                                    const SizedBox(
                                                                        width: 8),
                                                                    Expanded(
                                                                      child: CustomTextFormField(
                                                                        label:const Row(
                                                                          children: [
                                                                            Text('Benefit Limit', style: TextStyle(color: Colors.black)),
                                                                            Text(' *', style: TextStyle(color: Colors.red)), // Asterisk in red
                                                                          ],
                                                                        ),
                                                                          labelStyle: const TextStyle(
                                                                            color: Color(0xff13322b),
                                                                            fontSize: 14,
                                                                          ),
                                                                          controller: benefitLimitController,
                                                                          isNumeric: true,
                                                                          maxLength: 6,
                                                                          validator: (value) {
                                                                            if (value == null || value.isEmpty) {
                                                                              return 'Benefit limit required';
                                                                            }
                                                                            return null;
                                                                          }),
                                                                    )
                                                                  ],
                                                                ),
                                                                const SizedBox(
                                                                    height: 20),
                                                                const SizedBox(
                                                                    height:
                                                                        10), // Space above the title
                                                        
                                                                // Personal Details Title
                                                                Container(
                                                                  alignment: Alignment
                                                                      .centerLeft, // Align to the left
                                                                  child: const Text(
                                                                    "Card Details", // Title for the radio buttons
                                                                    style: TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: Color(
                                                                          0xff13322b), // Set title color
                                                                    ),
                                                                    textAlign: TextAlign
                                                                        .left, // Align text to the left
                                                                  ),
                                                                ),
                                                        
                                                                const SizedBox(
                                                                    height:
                                                                        10), // Space below the title
                                                        
                                                                // Fourth row with 2 text fields: Card Type and Card Number
                                                                Row(
                                                                  children: [
                                                                    Expanded(
                                                                      child:
                                                                      CustomTextFormField(
                                                                      label:const Row(
                                                                        children: [
                                                                          Text('Card Type', style: TextStyle(color: Colors.black)),
                                                                          Text(' *', style: TextStyle(color: Colors.red)), // Asterisk in red
                                                                        ],
                                                                      ),
                                                                        labelStyle:
                                                                            const TextStyle(
                                                                          color: Color(
                                                                              0xff13322b),
                                                                          fontSize: 14,
                                                                        ),
                                                                        controller:
                                                                            cardTypeController,
                                                                        isRead: true,
                                                                        isNumeric:
                                                                            false,
                                                                        validator:
                                                                            (value) {
                                                                          return null;
                                                                        },
                                                                        maxLength: 16,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                        width: 8),
                                                                    Expanded(
                                                                      child:
                                                                          CustomTextFormField(
                                                                          label:const Row(
                                                                            children: [
                                                                              Text('Card Number', style: TextStyle(color: Colors.black)),
                                                                              Text(' *', style: TextStyle(color: Colors.red)), // Asterisk in red
                                                                            ],
                                                                          ),
                                                                        labelStyle:
                                                                            const TextStyle(
                                                                          color: Color(
                                                                              0xff13322b),
                                                                          fontSize: 14,
                                                                        ),
                                                                        controller:
                                                                            cardNumberController,
                                                                        isNumeric: true,
                                                                        validator:
                                                                            (value) {
                                                                          //return null;
                                                                          if (value == null || value.isEmpty) {
                                                                              return 'Card number is required';
                                                                          }else if(value.length!=16){
                                                                            return 'Card number should be 16 digit';
                                                                          }
                                                                            return null;
                                                                        },
                                                                        maxLength: 16,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                const SizedBox(
                                                                    height:
                                                                        16), // Add spacing between rows
                                                        
                                                                // Fifth row with 2 text fields: Card Validity and Primary Clinic
                                                                // const Row(
                                                                //   children: [
                                                                //     Expanded(
                                                                //       child: TextField(
                                                                //         decoration:
                                                                //             InputDecoration(
                                                                //           labelText:
                                                                //               "Card Validity (YYYY/MM/DD)",
                                                                //           labelStyle: TextStyle(
                                                                //               fontSize:
                                                                //                   14,
                                                                //               color: Color(
                                                                //                   0xffB6B6B6)), // Default color
                                                                //           focusedBorder:
                                                                //               OutlineInputBorder(
                                                                //             borderSide: BorderSide(
                                                                //                 color: Colors
                                                                //                     .black,
                                                                //                 width:
                                                                //                     1.5), // Color when focused
                                                                //           ),
                                                                //           enabledBorder:
                                                                //               OutlineInputBorder(
                                                                //             borderSide: BorderSide(
                                                                //                 color: Color(
                                                                //                     0xffB6B6B6),
                                                                //                 width:
                                                                //                     1.5), // Default outline color
                                                                //           ),
                                                                //         ),
                                                                //       ),
                                                                //     ),
                                                                //     SizedBox(width: 8),
                                                                //     Expanded(
                                                                //       child: TextField(
                                                                //         decoration:
                                                                //             InputDecoration(
                                                                //           labelText:
                                                                //               "Primary Clinic",
                                                                //           labelStyle: TextStyle(
                                                                //               fontSize:
                                                                //                   14,
                                                                //               color: Color(
                                                                //                   0xffB6B6B6)), // Default color
                                                                //           focusedBorder:
                                                                //               OutlineInputBorder(
                                                                //             borderSide: BorderSide(
                                                                //                 color: Colors
                                                                //                     .black,
                                                                //                 width:
                                                                //                     1.5), // Color when focused
                                                                //           ),
                                                                //           enabledBorder:
                                                                //               OutlineInputBorder(
                                                                //             borderSide: BorderSide(
                                                                //                 color: Color(
                                                                //                     0xffB6B6B6),
                                                                //                 width:
                                                                //                     1.5), // Default outline color
                                                                //           ),
                                                                //         ),
                                                                //       ),
                                                                //     ),
                                                                //   ],
                                                                // ),
                                                        
                                                                // Footer with OK button aligned to the right
                                                                SizedBox(height:_isFormValid?160:100), // Spacing before the close button
                                                                Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center, // Center the buttons horizontally
                                                                  children: [
                                                                    SizedBox(
                                                                      width:
                                                                          200, // Same width for the Select Files button
                                                                      height:
                                                                          40, // Same height for the Select Files button
                                                                      child:
                                                                          ElevatedButton(
                                                                        onPressed: () {
                                                                          Navigator.pop(
                                                                              context); // Close the dialog
                                                                        },
                                                                        style: ElevatedButton
                                                                            .styleFrom(
                                                                          shape:
                                                                              RoundedRectangleBorder(
                                                                            borderRadius:
                                                                                BorderRadius
                                                                                    .circular(5),
                                                                            side: const BorderSide(
                                                                                color: Color(
                                                                                    0xff13322b)), // Set the border color
                                                                          ),
                                                                          backgroundColor:
                                                                              Colors
                                                                                  .white, // Set button background color to white
                                                                        ),
                                                                        child:
                                                                            const Text(
                                                                          'Back',
                                                                          style: TextStyle(
                                                                              color: Colors
                                                                                  .black), // Set button text color to black for visibility
                                                                        ),
                                                                      ),
                                                                    ),
                                                        
                                                                    const SizedBox(
                                                                        width:
                                                                            10), // Add spacing between the buttons
                                                                    SizedBox(
                                                                      width:
                                                                          200, // Set a fixed width for both buttons
                                                                      height:
                                                                          40, // Set a fixed height for both buttons
                                                                      child:
                                                                          ElevatedButton(
                                                                        onPressed: () {
                                                                          if (!_formKey2.currentState!.validate())return;
                                                                          
                                                                          if(roomAndBoardLimitController.text.isNotEmpty && benefitLimitController.text.isNotEmpty&&cardNumberController.text.isNotEmpty){
                                                                            
                                                                              if(cardNumberController.text.length==16){                                                    
                                                                                
                                                                                addMember(setState);
                                                                                setState(() {
                                                                                  isLoading=true;
                                                                                });
                                                                              }
                                                                          }
                                                                        },
                                                                        style: ElevatedButton
                                                                            .styleFrom(
                                                                          shape:
                                                                              RoundedRectangleBorder(
                                                                            borderRadius:
                                                                                BorderRadius
                                                                                    .circular(5),
                                                                          ),
                                                                          backgroundColor:
                                                                              const Color(
                                                                                  0xff13322b), // Set button background color
                                                                        ),
                                                                        child:
                                                                            const Text(
                                                                          "Submit",
                                                                          style:
                                                                              TextStyle(
                                                                            color: Colors
                                                                                .white, // Set submit button text color to white
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    }),
                                                  );
                                                },
                                              );
                                              }
                                          }

                                        }
                                        
                                      },
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                        backgroundColor: const Color(
                                            0xff13322b), // Set button background color
                                      ),
                                      child: const Text(
                                        "Next",
                                        style: TextStyle(
                                          color: Colors
                                              .white, // Set submit button text color to white
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
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
                setState(() {
                  isLoading=false;
                });
              },
            ),
          ],
        );
      },
    );
  }


  
}

class TableCellContent extends StatelessWidget {
  final String content;

  const TableCellContent({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        content,
        style: const TextStyle(color: Color(0xff13322b)),
        overflow: TextOverflow.ellipsis, // Add this line
        maxLines: 1, // Optional: Limits the text to a single line
      ),
    );
  }
}
