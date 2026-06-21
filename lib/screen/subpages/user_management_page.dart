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
import 'package:medicare_admin_remaster/services/cache_service.dart';
import 'package:medicare_admin_remaster/services/ggx_connection.dart';
import 'package:medicare_admin_remaster/services/local_member_config_service.dart';
import 'package:medicare_admin_remaster/shared/api.dart';
import 'package:medicare_admin_remaster/shared/list.dart';
import 'package:medicare_admin_remaster/shared/members.dart';
import 'package:medicare_admin_remaster/widget/address_dropdown.dart';
import 'package:medicare_admin_remaster/widget/birthday_picker.dart';
import 'dart:html' as html;

import 'package:medicare_admin_remaster/widget/custom_dropdown.dart';
import 'package:medicare_admin_remaster/widget/custom_textform_field.dart';
import 'package:medicare_admin_remaster/widget/list_dropdown.dart';
import 'package:medicare_admin_remaster/widget/string_dropdown.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_flutter;

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
  bool noSex = false;
  String cardNumbers = 'N/A';
  String dateLabel = 'yyyy-mm-dd';
  String? customerId;
  String? limit_id;
  String? prb_id;
  String? card_id;
  String? plan_id;

  bool? statusFilter;

  GgxApi ggx = GgxApi();

  String? selectedRegion;
  String? selectedProvince;
  String? selectedCity;
  String? selectedBarangay;

  List<Region> regions = [];
  List<Region> myRegions = [];
  List<Province> provinces = [];
  List<City> cities = [];
  List<Barangay> barangays = [];

  int activeCount = 0;
  int inactiveCount = 0;
  int bothCount = 0;
  int activeButtonIndex = -1;

  final LocalMemberConfigService _localMemberConfigService =
      LocalMemberConfigService();
  List<StatusItem> _localPlanTypeItems = List<StatusItem>.from(planTypeItems);

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
  final TextEditingController cardExpiryController = TextEditingController();
  final TextEditingController cardEffectiveController = TextEditingController();

  final TextEditingController memberTypeController = TextEditingController();
  final TextEditingController enrollmentTypeController =
      TextEditingController();
  final TextEditingController planTypeController = TextEditingController();
  final TextEditingController benefitLimitController = TextEditingController();
  final TextEditingController benefitLimitTypeController =
      TextEditingController();
  final TextEditingController roomAndBoardTypeController =
      TextEditingController();
  final TextEditingController roomAndBoardLimitController =
      TextEditingController();

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
  final TextEditingController ecardExpiryController = TextEditingController();
  final TextEditingController ecardEffectiveController = TextEditingController();

  final TextEditingController ememberTypeController = TextEditingController();
  final TextEditingController eenrollmentTypeController =
      TextEditingController();
  final TextEditingController eplanTypeController = TextEditingController();
  final TextEditingController ebenefitLimitController = TextEditingController();
  final TextEditingController ebenefitLimitTypeController =
      TextEditingController();
  final TextEditingController eroomAndBoardTypeController =
      TextEditingController();
  final TextEditingController eroomAndBoardLimitController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  String searchQuery = '';
  String filterCriteria = '';
  String _sortBy = '';
  bool _sortDescending = false;
  // Sample data
  late Stream<List<Map<String, dynamic>>> requests;
  late Stream<List<Map<String, dynamic>>> memberData;
  List<PlatformFile> _selectedFiles = [];
  List<Map<String, dynamic>> filteredRequests = [];

  bool _isFormValid = true; // State variable to track form validity
  int _addMemberStep = 0;
  List<Map<String, dynamic>> _cardVariants = [];
  int? _selectedCardVariantId;

  // Pagination
  int _currentPage = 1;
  static const int _pageSize = 25;

  @override
  void initState() {
    super.initState();
    fetchRegions(setState);
    _loadLocalPlanTypes();
    _fetchCardVariants();
    requests = CacheService.instance.membersStream;
    // Seed with cached data if available
    final cached = CacheService.instance.currentMembers;
    if (cached.isNotEmpty) {
      filteredRequests = cached;
    }
  }

  @override
  void dispose() {
    // Dispose of the controllers to avoid memory leaks
    super.dispose();
  }

  Future<void> _loadLocalPlanTypes() async {
    final localItems = await _localMemberConfigService.loadPlanTypes();
    if (!mounted) return;

    setState(() {
      _localPlanTypeItems = localItems;
      _syncPlanTypeControllers();
    });
  }

  Future<void> _fetchCardVariants() async {
    try {
      final response = await supabase_flutter.Supabase.instance.client
          .from('mp_card_variants_table')
          .select()
          .order('card_variant_id');
      if (!mounted) return;
      setState(() {
        _cardVariants = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('Error fetching card variants: $e');
    }
  }

  void _syncPlanTypeControllers() {
    _syncPlanTypeController(planTypeController);
    _syncPlanTypeController(eplanTypeController);
  }

  void _syncPlanTypeController(TextEditingController controller) {
    if (_localPlanTypeItems.isEmpty) {
      controller.text = '';
      return;
    }

    final selectedId = int.tryParse(controller.text);
    final exists = selectedId != null &&
        _localPlanTypeItems.any((item) => item.id == selectedId);
    if (!exists) {
      controller.text = _localPlanTypeItems.first.id.toString();
    }
  }

  int _defaultPlanTypeId() {
    if (_localPlanTypeItems.isEmpty) {
      return 4;
    }

    final preferred = _localPlanTypeItems.where((item) => item.id == 4);
    if (preferred.isNotEmpty) {
      return preferred.first.id;
    }

    return _localPlanTypeItems.first.id;
  }

  String _cardLabelForPlanType(int planId) {
    if (planId == 4) {
      return 'PSMBFI';
    }

    final match = _localPlanTypeItems.where((item) => item.id == planId);
    return match.isNotEmpty ? match.first.status : 'N/A';
  }

  Future<bool> _showPlanTypeManagerDialog(BuildContext context) async {
    final working = _localPlanTypeItems
        .map((item) => StatusItem(id: item.id, status: item.status))
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final idController = TextEditingController();
    final labelController = TextEditingController();
    String? errorText;
    bool updated = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: const Text('Manage Plan Types'),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 260),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: working.length,
                          itemBuilder: (context, index) {
                            final item = working[index];
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text('${item.id} - ${item.status}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () {
                                  if (working.length <= 1) {
                                    dialogSetState(() {
                                      errorText =
                                          'At least one plan type is required.';
                                    });
                                    return;
                                  }

                                  dialogSetState(() {
                                    working.removeAt(index);
                                    errorText = null;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: idController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Plan ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: labelController,
                      decoration: const InputDecoration(
                        labelText: 'Plan Label',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {
                          final planId = int.tryParse(idController.text.trim());
                          final planLabel = labelController.text.trim();
                          if (planId == null || planLabel.isEmpty) {
                            dialogSetState(() {
                              errorText =
                                  'Both Plan ID and Plan Label are required.';
                            });
                            return;
                          }

                          final duplicate =
                              working.any((item) => item.id == planId);
                          if (duplicate) {
                            dialogSetState(() {
                              errorText = 'Plan ID already exists.';
                            });
                            return;
                          }

                          dialogSetState(() {
                            working.add(
                              StatusItem(id: planId, status: planLabel),
                            );
                            working.sort((a, b) => a.id.compareTo(b.id));
                            idController.clear();
                            labelController.clear();
                            errorText = null;
                          });
                        },
                        child: const Text('Add Plan Type'),
                      ),
                    ),
                    if (errorText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            errorText!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final defaults = List<StatusItem>.from(planTypeItems);
                    await _localMemberConfigService.savePlanTypes(defaults);
                    if (!mounted) return;
                    setState(() {
                      _localPlanTypeItems = defaults;
                      _syncPlanTypeControllers();
                    });
                    updated = true;
                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Reset'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (working.isEmpty) {
                      dialogSetState(() {
                        errorText = 'At least one plan type is required.';
                      });
                      return;
                    }

                    await _localMemberConfigService.savePlanTypes(working);
                    if (!mounted) return;
                    setState(() {
                      _localPlanTypeItems = working;
                      _syncPlanTypeControllers();
                    });
                    updated = true;
                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    idController.dispose();
    labelController.dispose();
    return updated;
  }

  void filterByStatus(bool? status) {
    setState(() {
      statusFilter = status; // Update the filter
    });
  }

  int calculateAge(String birthday) {
    // Parse the date string to DateTime
    DateTime birthDate = DateTime.parse(birthday);
    DateTime today = DateTime.now(); // Get the current date

    int age = today.year - birthDate.year; // Calculate the age in years

    // Adjust age if the birthday hasn't occurred yet this year
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  void countStatuses(List<Map<String, dynamic>> members) {
    // Reset counts
    activeCount = 0;
    inactiveCount = 0;
    bothCount = 0;
    // Count statuses
    for (var member in members) {
      if (member['is_verified'] == true) {
        activeCount++; // Count true
      } else if (member['is_verified'] == false) {
        inactiveCount++; // Count false
      }
    }
    // Sum both true and false values
    bothCount = activeCount + inactiveCount;
  }

  int countActiveRequests(List<Map<String, dynamic>> mylist) {
    int activeCount = 0;

    // Iterate through the list of requests
    for (var request in mylist) {
      // Check if 'is_active' is true
      if (request['is_verified'] == true) {
        activeCount++;
      }
    }

    return activeCount;
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

  Future<void> fetchRegions(StateSetter setState) async {
    var apiUrl = '$ggxUrl/v2/locations/countries/PH/regions';

    var jwt = ggx.generateJwt();
    final response = await http.get(Uri.parse(apiUrl), headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $jwt',
    });

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> regionsJson = data['data'];

      // Sort the regions with custom logic
      regionsJson.sort((a, b) {
        // Define the custom order
        const customOrder = [
          'NCR',
          'Region I',
          'Region II',
          'Region III',
          'Region IV-A', // Region IV-A
          'Region IV-B', // Place MIMAROPA after CALABARZON
          'Region V',
          'Region VI',
          'Region VII',
          'Region VIII',
          'Region IX',
          'Region X',
          'Region XI',
          'Region XII',
          'Region XIII',
          'CAR',
          'ARMM',
          'NIR',
          'Davao de Oro'
        ];

        int indexA = customOrder.indexOf(a['name']);
        int indexB = customOrder.indexOf(b['name']);

        // If both items are in customOrder, sort by their indices
        if (indexA != -1 && indexB != -1) {
          return indexA.compareTo(indexB);
        }

        // If only one item is in customOrder, it should come first
        if (indexA != -1) return -1;
        if (indexB != -1) return 1;

        // Default sorting (alphabetical) for other regions
        return a['name'].compareTo(b['name']);
      });

      setState(() {
        regions = regionsJson.map((e) => Region.fromJson(e)).toList();
      });
    } else {
      throw Exception('Failed to load regions');
    }
  }

  Future<void> fetchProvinces(String regionCode, StateSetter setState) async {
    var apiUrl = '$ggxUrl/v2/locations/regions/$regionCode/provinces';

    var jwt = ggx.generateJwt();
    final response = await http.get(Uri.parse(apiUrl), headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $jwt',
    });
    //final response = await http.get(Uri.parse('https://psgc.gitlab.io/api/regions/$regionCode/provinces.json'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> regionsJson = data['data'];
      setState(() {
        provinces = regionsJson.map((e) => Province.fromJson(e)).toList();
        selectedProvince = null; // Reset province selection
        cities.clear(); // Clear cities
        barangays.clear(); // Clear barangays
      });
    }
  }

  Future<void> fetchCities(String provinceCode, StateSetter setState) async {
    var apiUrl = '$ggxUrl/v2/locations/provinces/$provinceCode/cities';

    var jwt = ggx.generateJwt();
    final response = await http.get(Uri.parse(apiUrl), headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $jwt',
    });

    //final response = await http.get(Uri.parse('https://psgc.gitlab.io/api/provinces/$provinceCode/cities-municipalities.json'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> regionsJson = data['data'];
      setState(() {
        cities = regionsJson.map((e) => City.fromJson(e)).toList();
        selectedCity = null; // Reset city selection
        barangays.clear(); // Clear barangays
      });
    }
  }

  /*Future<void> fetchBarangays(String cityCode, StateSetter setState) async {
    var apiUrl = '$ggxUrl/v2/locations/cities/$cityCode/districts';

      var jwt = ggx.generateJwt();
      final response = await http.get(Uri.parse(apiUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $jwt',
          });
    //final response = await http.get(Uri.parse('https://psgc.gitlab.io/api/cities-municipalities/$cityCode/barangays.json'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> regionsJson = data['data'];
      setState(() {
        barangays = regionsJson.map((e) => Barangay.fromJson(e)).toList();
      });
    }
  }*/

  Future<void> fetchBarangays(String cityCode, StateSetter setState) async {
    var apiUrl = '$ggxUrl/v2/locations/cities/$cityCode/districts';

    var jwt = ggx.generateJwt();
    List<Barangay> allBarangays = [];

    while (apiUrl != '') {
      // Fetch the data from the API
      final response = await http.get(Uri.parse(apiUrl), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwt',
      });

      // If the response is successful (status code 200), parse the data
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> regionsJson = data['data'];

        // Add the current page of barangays to the allBarangays list
        allBarangays
            .addAll(regionsJson.map((e) => Barangay.fromJson(e)).toList());

        // Check if there is a next page and update the apiUrl
        apiUrl = data['next_page_url'] != null
            ? '$ggxUrl${data['next_page_url']}'
            : '';
      } else {
        // If the response is not successful, break the loop (you can also handle the error accordingly)
        print('Error fetching data: ${response.statusCode}');
        break;
      }
    }

    // Once all pages are fetched, update the state with all the barangays
    setState(() {
      barangays = allBarangays;
    });
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

    final uri = Uri.parse(adminEndpoint('bulk_upload'));
    var request = http.MultipartRequest('POST', uri);

    // Add headers
    request.headers.addAll(buildApiHeaders(includeContentType: false));

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
      var response = await request.send().timeout(const Duration(seconds: 20));

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
    } catch (e) {
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

  Future<void> _selectDate(
      BuildContext context, StateSetter setState, String period) async {
    // Default to the current date if the period is null or empty
    DateTime initialDate = DateTime.now();

    // If period is not empty or null, parse the period string into a DateTime
    if (period.isNotEmpty) {
      try {
        initialDate =
            DateTime.parse(period); // period should be in 'yyyy-MM-dd' format
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
      _birthday = initialDate; // Use the initialDate if no date is picked
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

  Future<void> updateMember() async {
    String url = '$apiUrl/update_customer';

    final Map<String, dynamic> data = {
      'customer_id': customerId,
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
      'card_type': ecardTypeController.text,
      'enrollment_type': int.parse(eenrollmentTypeController.text),
      'room_board_type': int.parse(eroomAndBoardTypeController.text),
      'room_board_limit': eroomAndBoardLimitController.text,
      'benefit_limit': ebenefitLimitController.text,
      'benefit_limit_type': int.parse(ebenefitLimitTypeController.text),
      'limit_id': limit_id,
      'prb_id': prb_id,
      'card_id': card_id,
      'plan_id': plan_id,
      'card_expiration_date': ecardExpiryController.text.isNotEmpty ? ecardExpiryController.text : null,
      'card_effective_date': ecardEffectiveController.text.isNotEmpty ? ecardEffectiveController.text : null,
    };

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: buildApiHeaders(),
            body: json.encode(data),
          )
          .timeout(const Duration(seconds: 10));

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
          _eselectedSex = '';
          ebenefitLimitController.text = '';
          eroomAndBoardLimitController.text = '';
          _isFormValid = true;
          isLoading = false;
          _birthday = null;
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
          isLoading = false;
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
        _eselectedSex = '';
        ebenefitLimitController.text = '';
        eroomAndBoardLimitController.text = '';
        _isFormValid = true;
        isLoading = false;
        _birthday = null;
        Navigator.of(context).popUntil((route) => route.isFirst);
        _showMessage('The request timed out. Please try again later.',
            'Connection timeout!');
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print('Unexpected error: $error');
      // Handle unexpected errors
    }
  }

  Future<void> addMember(StateSetter setState) async {
    String url = '$apiUrl/add_member'; // Replace with your actual API URL
    DateTime initialDate = DateTime.now();
    if (_birthday == null) {
      setState(() {
        _birthday = initialDate;
        isLoading = true;
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
      'card_type': _selectedCardVariantId ?? cardTypeController.text,
      'enrollment_type': int.parse(enrollmentTypeController.text),
      'room_board_type': int.parse(roomAndBoardTypeController.text),
      'room_board_limit': roomAndBoardLimitController.text,
      'benefit_limit': benefitLimitController.text,
      'benefit_limit_type': int.parse(benefitLimitTypeController.text),
      'card_expiration_date': cardExpiryController.text.isNotEmpty ? cardExpiryController.text : null,
      'card_effective_date': cardEffectiveController.text.isNotEmpty ? cardEffectiveController.text : null,
    };

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: buildApiHeaders(),
            body: json.encode(data),
          )
          .timeout(const Duration(seconds: 10));

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
          benefitLimitController.text = '';
          roomAndBoardLimitController.text = '';
          _selectedSex = null;
          _selectedCardVariantId = null;
          _birthday = null;
          isLoading = false;
          //fetchLoaRequest();
          Navigator.of(context).popUntil((route) => route.isFirst);
          _showMessage(
              'The new member has been successfully added to the system.',
              'Member Added Successfully');
        });
        // Show success message or navigate to another screen
      } else {
        setState(() {
          isLoading = false;
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
        benefitLimitController.text = '';
        roomAndBoardLimitController.text = '';
        _selectedSex = null;
        _selectedCardVariantId = null;
        _birthday = null;
        isLoading = false;
        Navigator.of(context).popUntil((route) => route.isFirst);
        _showMessage('The request timed out. Please try again later.',
            'Connection timeout!');
      });
    } catch (error) {
      setState(() {
        isLoading = false;
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
      _currentPage = 1;
    });
  }

  String _buildFilterLabel() {
    final parts = <String>[];
    if (statusFilter == true) parts.add('Verified');
    if (statusFilter == false) parts.add('Unverified');
    if (filterCriteria.isNotEmpty) parts.add('Search: $filterCriteria');
    return parts.join(' + ');
  }

  Widget _buildStatCard({
    required String title,
    required String subtitle,
    required int count,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (title == 'Verified') {
            setState(() {
              if (activeButtonIndex == 0) {
                activeButtonIndex = -1;
                statusFilter = null;
              } else {
                activeButtonIndex = 0;
                filterByStatus(true);
              }
            });
          } else if (title == 'Unverified') {
            setState(() {
              if (activeButtonIndex == 1) {
                activeButtonIndex = -1;
                statusFilter = null;
              } else {
                activeButtonIndex = 1;
                filterByStatus(false);
              }
            });
          } else {
            setState(() {
              if (activeButtonIndex == 2) {
                activeButtonIndex = -1;
                statusFilter = null;
              } else {
                activeButtonIndex = 2;
                filterByStatus(null);
              }
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: activeButtonIndex == (title == 'Verified' ? 0 : title == 'Unverified' ? 1 : 2)
                  ? accentColor
                  : const Color(0xFFE5EEFF),
              width: activeButtonIndex == (title == 'Verified' ? 0 : title == 'Unverified' ? 1 : 2) ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      count.toString(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0B1C30),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xFF40484D).withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                            'App Users Management',
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
              body: Builder(builder: (context) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      // Center the spinner when loading
                      child: SpinKitCircle(
                    color: Color(0xff13322B), // Change the color as needed
                    size: 50.0, // Adjust size as needed
                  )); // Loading indicator
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Text('No data available');
                }

                final requestsList = snapshot.data!;

                // Filtering
                // Always start from the full list (requestsList), not stale filteredRequests
                List<Map<String, dynamic>> baseList = requestsList;

                // Apply status filter first
                if (statusFilter == true) {
                  baseList = baseList
                      .where((r) => r['is_verified'] == true)
                      .toList();
                } else if (statusFilter == false) {
                  baseList = baseList
                      .where((r) => r['is_verified'] == false)
                      .toList();
                }

                // Apply column text filter
                if (filterCriteria.isNotEmpty && searchQuery.isNotEmpty) {
                  baseList = baseList.where((request) {
                    if (filterCriteria == 'member') {
                      final firstName =
                          request['first_name']?.toLowerCase() ?? '';
                      final lastName =
                          request['last_name']?.toLowerCase() ?? '';
                      final fullName = '$lastName, $firstName';
                      return fullName.contains(searchQuery);
                    } else if (filterCriteria == 'card_number') {
                      final cardNumbers =
                          (request['mp_card_table'] as List<dynamic>?)
                                  ?.map((card) =>
                                      card['card_number']?.toString() ?? '')
                                  .join(', ') ??
                              '';
                      return cardNumbers.contains(searchQuery);
                    } else if (filterCriteria == 'is_active') {
                      final isActive = request['is_active'] ?? false;
                      if (searchQuery == 'active' || searchQuery == 'act') {
                        return isActive == true;
                      } else if (searchQuery == 'inactive' ||
                          searchQuery == 'ina') {
                        return isActive == false;
                      }
                      return false;
                    } else if (filterCriteria == 'email') {
                      final email =
                          request['email_address']?.toLowerCase() ?? '';
                      return email.contains(searchQuery);
                    } else if (filterCriteria == 'membership') {
                      final customerType =
                          request['mp_customer_type_table']
                                  ?['customer_type']
                              ?.toLowerCase() ??
                              '';
                      return customerType.contains(searchQuery);
                    } else if (filterCriteria == 'contacts') {
                      final myContact = request['contact_no']?.toString() ?? '';
                      return myContact.contains(searchQuery);
                    } else if (filterCriteria == 'company') {
                      final company =
                          request['mp_companies_table']?['name']
                              ?.toLowerCase() ??
                              '';
                      return company.contains(searchQuery);
                    }
                    return false;
                  }).toList();
                }

                // Apply sorting
                if (_sortBy.isNotEmpty) {
                  baseList.sort((a, b) {
                    int cmp = 0;
                    switch (_sortBy) {
                      case 'name':
                        final aName =
                            '${a['last_name'] ?? ''} ${a['first_name'] ?? ''}'
                                .toLowerCase();
                        final bName =
                            '${b['last_name'] ?? ''} ${b['first_name'] ?? ''}'
                                .toLowerCase();
                        cmp = aName.compareTo(bName);
                        break;
                      case 'id':
                        cmp = (a['id'] ?? 0).compareTo(b['id'] ?? 0);
                        break;
                      case 'email':
                        final aEmail =
                            (a['email_address'] ?? '').toLowerCase();
                        final bEmail =
                            (b['email_address'] ?? '').toLowerCase();
                        cmp = aEmail.compareTo(bEmail);
                        break;
                      case 'status':
                        cmp = (a['is_verified'] ?? false)
                            .toString()
                            .compareTo((b['is_verified'] ?? false).toString());
                        break;
                      case 'membership':
                        final aType = a['mp_customer_type_table']
                                ?['customer_type']
                            ?.toString() ??
                            '';
                        final bType = b['mp_customer_type_table']
                                ?['customer_type']
                            ?.toString() ??
                            '';
                        cmp = aType.compareTo(bType);
                        break;
                      case 'company':
                        final aCompany = a['mp_companies_table']?['name']?.toString() ?? '';
                        final bCompany = b['mp_companies_table']?['name']?.toString() ?? '';
                        cmp = aCompany.compareTo(bCompany);
                        break;
                    }
                    return _sortDescending ? -cmp : cmp;
                  });
                }

                filteredRequests = baseList;

                countStatuses(requestsList);
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5EEFF), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00455D).withOpacity(0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Row for the four cards

                        const SizedBox(
                            height:
                                20), // Add space between cards and other content

                         // Search and filter bar
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                          child: Row(
                            children: [
                              // Search input
                              Expanded(
                                flex: 3,
                                child: SizedBox(
                                  height: 42,
                                  child: TextField(
                                    cursorColor: const Color(0xFF00455D),
                                    controller: searchController,
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF0B1C30)),
                                    onChanged: (value) {
                                      _onSearchChanged(value);
                                      // If no filterCriteria, default to 'member' search
                                      if (filterCriteria.isEmpty && value.isNotEmpty) {
                                        setState(() {
                                          filterCriteria = 'member';
                                        });
                                      }
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'Search members by name, ID, or email...',
                                      hintStyle: TextStyle(fontSize: 13, color: const Color(0xFF0B1C30).withOpacity(0.4)),
                                      prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF70787E)),
                                      suffixIcon: (filterCriteria.isNotEmpty || statusFilter != null || searchQuery.isNotEmpty)
                                          ? IconButton(
                                              icon: const Icon(Icons.close, size: 16, color: Color(0xFF70787E)),
                                              onPressed: () {
                                                setState(() {
                                                  filterCriteria = '';
                                                  searchQuery = '';
                                                  searchController.clear();
                                                  statusFilter = null;
                                                  activeButtonIndex = -1;
                                                  _currentPage = 1;
                                                });
                                              },
                                            )
                                          : null,
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Color(0xFFE5EEFF), width: 1),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Color(0xFFE5EEFF), width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Color(0xFF00455D), width: 1.5),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Status dropdown
                              SizedBox(
                                height: 42,
                                width: 160,
                                child: DropdownButtonFormField<bool?>(
                                  value: statusFilter,
                                  dropdownColor: Colors.white,
                                  iconEnabledColor: const Color(0xFF70787E),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Color(0xFFE5EEFF)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Color(0xFFE5EEFF)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Color(0xFF00455D)),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    hintText: 'All Statuses',
                                    hintStyle: TextStyle(fontSize: 13, color: const Color(0xFF0B1C30).withOpacity(0.4)),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: null, child: Text('All Statuses', style: TextStyle(fontSize: 13, color: Color(0xFF0B1C30)))),
                                    DropdownMenuItem(value: true, child: Text('Verified', style: TextStyle(fontSize: 13, color: Color(0xFF0B1C30)))),
                                    DropdownMenuItem(value: false, child: Text('Unverified', style: TextStyle(fontSize: 13, color: Color(0xFF0B1C30)))),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      statusFilter = value;
                                      activeButtonIndex = value == null ? -1 : (value == true ? 0 : 1);
                                      _currentPage = 1;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Membership Type dropdown
                              SizedBox(
                                height: 42,
                                width: 160,
                                child: DropdownButtonFormField<String>(
                                  value: filterCriteria == 'membership' ? searchQuery : null,
                                  dropdownColor: Colors.white,
                                  iconEnabledColor: const Color(0xFF70787E),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Color(0xFFE5EEFF)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Color(0xFFE5EEFF)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Color(0xFF00455D)),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    hintText: 'All Types',
                                    hintStyle: TextStyle(fontSize: 13, color: const Color(0xFF0B1C30).withOpacity(0.4)),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: null, child: Text('All Types', style: TextStyle(fontSize: 13, color: Color(0xFF0B1C30)))),
                                    DropdownMenuItem(value: 'principal', child: Text('Principal', style: TextStyle(fontSize: 13, color: Color(0xFF0B1C30)))),
                                    DropdownMenuItem(value: 'dependent', child: Text('Dependent', style: TextStyle(fontSize: 13, color: Color(0xFF0B1C30)))),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      if (value != null) {
                                        filterCriteria = 'membership';
                                        searchQuery = value;
                                      } else {
                                        filterCriteria = '';
                                        searchQuery = '';
                                      }
                                      _currentPage = 1;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Add Member button
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  if (state is AuthSuccess) {
                                    if (state.adminType == 'admin' || state.adminType == 'upd') {
                                      return SizedBox(
                                        height: 42,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            setState(() { fetchRegions(setState); });
                                            _showDialog(context, setState);
                                          },
                                          icon: const Icon(Icons.person_add, size: 18),
                                          label: const Text('Add Member', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF00455D),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            padding: const EdgeInsets.symmetric(horizontal: 16),
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                  return const SizedBox.shrink();
                                },
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

                        // Stats cards
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                          child: Row(
                            children: [
                              _buildStatCard(
                                title: 'Verified',
                                subtitle: 'Verified Member Accounts',
                                count: activeCount,
                                icon: Icons.check_circle_outline,
                                accentColor: const Color(0xFF006B5F),
                                bgColor: const Color(0xFFE8F5F0),
                              ),
                              const SizedBox(width: 16),
                              _buildStatCard(
                                title: 'Unverified',
                                subtitle: 'Accounts Awaiting Verification',
                                count: inactiveCount,
                                icon: Icons.pending_outlined,
                                accentColor: const Color(0xFFBA1A1A),
                                bgColor: const Color(0xFFFFF0EE),
                              ),
                              const SizedBox(width: 16),
                              _buildStatCard(
                                title: 'Total',
                                subtitle: 'Aggregate Platform Users',
                                count: bothCount,
                                icon: Icons.people_outline,
                                accentColor: const Color(0xFF00455D),
                                bgColor: const Color(0xFFEFF4FF),
                              ),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Divider(height: 1, color: Color(0xFFE5EEFF)),
                        ),
                        const SizedBox(height: 16),
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
                                // PNP Number Section (No Divider)
                                // Requester Name
                                Expanded(
                                  flex: 1, // Same flex for each column
                                  child: GestureDetector(
                                    onTap: () {},
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        border: Border.all(
                                          color: Colors
                                              .black, // Outline color for the text container
                                          width:
                                              1.0, // Outline width for the text container
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(
                                          8.0), // Padding inside the text container
                                      child: const Text(
                                        'ID',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1, // Same flex for each column
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (filterCriteria == 'member') {
                                          filterCriteria =
                                              ''; // Clear the filterCriteria (or set to null)
                                          searchQuery =
                                              ''; // Optionally reset the search query
                                          searchController.text = '';
                                        } else {
                                          filterCriteria =
                                              'member'; // Set to 'member' if it's not already
                                          searchQuery =
                                              ''; // Optionally reset the search query
                                          searchController.text = '';
                                        } // Reset the search query
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: filterCriteria == 'member'
                                            ? const Color(0xFF13322B)
                                            : Colors.transparent,
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
                                        'Member Name',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: filterCriteria == 'member'
                                                ? const Color(0xFFFFFFFF)
                                                : Colors.black),
                                      ),
                                    ),
                                  ),
                                ),
                                // Company
                                Expanded(
                                  flex: 1,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (filterCriteria == 'company') {
                                          filterCriteria = '';
                                          searchQuery = '';
                                          searchController.text = '';
                                        } else {
                                          filterCriteria = 'company';
                                          searchQuery = '';
                                          searchController.text = '';
                                        }
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: filterCriteria == 'company'
                                            ? const Color(0xFF13322B)
                                            : Colors.transparent,
                                        border: Border.all(color: Colors.black, width: 1.0),
                                      ),
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        'Company',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: filterCriteria == 'company'
                                                ? const Color(0xFFFFFFFF)
                                                : Colors.black),
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
                                          filterCriteria =
                                              ''; // Clear the filterCriteria (or set to null)
                                          searchQuery =
                                              ''; // Optionally reset the search query
                                          searchController.text = '';
                                        } else {
                                          filterCriteria =
                                              'membership'; // Set to 'member' if it's not already
                                          searchQuery =
                                              ''; // Optionally reset the search query
                                          searchController.text = '';
                                        }
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: filterCriteria == 'membership'
                                            ? const Color(0xFF13322B)
                                            : Colors.transparent,
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
                                            color:
                                                filterCriteria == 'membership'
                                                    ? const Color(0xFFFFFFFF)
                                                    : Colors.black),
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
                                          filterCriteria =
                                              ''; // Clear the filterCriteria (or set to null)
                                          searchQuery =
                                              ''; // Optionally reset the search query
                                          searchController.text = '';
                                        } else {
                                          filterCriteria =
                                              'card_number'; // Set to 'member' if it's not already
                                          searchQuery =
                                              ''; // Optionally reset the search query
                                          searchController.text = '';
                                        }
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: filterCriteria == 'card_number'
                                            ? const Color(0xFF13322B)
                                            : Colors.transparent,
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
                                            color:
                                                filterCriteria == 'card_number'
                                                    ? const Color(0xFFFFFFFF)
                                                    : Colors.black),
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
                                        if (filterCriteria == 'contacts') {
                                          filterCriteria =
                                              ''; // Clear the filterCriteria (or set to null)
                                          searchQuery =
                                              ''; // Optionally reset the search query
                                          searchController.text = '';
                                        } else {
                                          filterCriteria =
                                              'contacts'; // Set to 'member' if it's not already
                                          searchQuery =
                                              ''; // Optionally reset the search query
                                          searchController.text = '';
                                        }
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: filterCriteria == 'contacts'
                                            ? const Color(0xFF13322B)
                                            : Colors.transparent,
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
                                            color: filterCriteria == 'contacts'
                                                ? const Color(0xFFFFFFFF)
                                                : Colors.black),
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
                                          filterCriteria =
                                              ''; // Clear the filterCriteria (or set to null)
                                          searchQuery =
                                              ''; // Optionally reset the search query
                                          searchController.text = '';
                                        } else {
                                          filterCriteria =
                                              'email'; // Set to 'member' if it's not already
                                          searchQuery =
                                              ''; // Optionally reset the search query
                                          searchController.text = '';
                                        }
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: filterCriteria == 'email'
                                            ? const Color(0xFF13322B)
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: Colors.black,
                                          width: 1.0,
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        'Email Address',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: filterCriteria == 'email'
                                                ? const Color(0xFFFFFFFF)
                                                : Colors.black),
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
                                          filterCriteria =
                                              ''; // Clear the filterCriteria (or set to null)
                                          searchQuery =
                                              ''; // Optionally reset the search query
                                          searchController.text = '';
                                        } else {
                                          filterCriteria =
                                              'is_active'; // Set to 'member' if it's not already
                                          searchQuery =
                                              ''; // Optionally reset the search query
                                          searchController.text = '';
                                        }
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: filterCriteria == 'is_active'
                                            ? const Color(0xFF13322B)
                                            : Colors.transparent,
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
                                            color: filterCriteria == 'is_active'
                                                ? const Color(0xFFFFFFFF)
                                                : Colors.black),
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
                        // Pagination info
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: Row(
                            children: [
                              Text(
                                'Showing ${(_currentPage - 1) * _pageSize + 1} to ${_currentPage * _pageSize > filteredRequests.length ? filteredRequests.length : _currentPage * _pageSize} of ${filteredRequests.length} entries',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF40484D)),
                              ),
                              const Spacer(),
                              // Page navigation
                              if (filteredRequests.length > _pageSize) ...[
                                IconButton(
                                  onPressed: _currentPage > 1
                                      ? () => setState(() => _currentPage--)
                                      : null,
                                  icon: const Icon(Icons.chevron_left, size: 18),
                                  color: _currentPage > 1 ? const Color(0xFF00455D) : Colors.grey,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                const SizedBox(width: 4),
                                ...List.generate(
                                  (filteredRequests.length / _pageSize).ceil(),
                                  (i) => i + 1,
                                ).take(5).map((page) => GestureDetector(
                                  onTap: () => setState(() => _currentPage = page),
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    margin: const EdgeInsets.symmetric(horizontal: 2),
                                    decoration: BoxDecoration(
                                      color: _currentPage == page ? const Color(0xFF00455D) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$page',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _currentPage == page ? Colors.white : const Color(0xFF00455D),
                                        ),
                                      ),
                                    ),
                                  ),
                                )),
                                if ((filteredRequests.length / _pageSize).ceil() > 5)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4),
                                    child: Text('...', style: TextStyle(fontSize: 12, color: Color(0xFF70787E))),
                                  ),
                                IconButton(
                                  onPressed: _currentPage < (filteredRequests.length / _pageSize).ceil()
                                      ? () => setState(() => _currentPage++)
                                      : null,
                                  icon: const Icon(Icons.chevron_right, size: 18),
                                  color: _currentPage < (filteredRequests.length / _pageSize).ceil()
                                      ? const Color(0xFF00455D)
                                      : Colors.grey,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFE5EEFF)),
                        Expanded(
                          child: ListView.builder(
                            itemCount: (() {
                              final totalPages = (filteredRequests.length / _pageSize).ceil();
                              final start = (_currentPage - 1) * _pageSize;
                              final end = start + _pageSize;
                              return filteredRequests.length > start
                                  ? (end > filteredRequests.length ? filteredRequests.length - start : _pageSize)
                                  : 0;
                            })(),
                            itemBuilder: (context, index) {
                              final request = filteredRequests[(_currentPage - 1) * _pageSize + index];
                              final customerType =
                                  request['mp_customer_type_table']
                                          ?['customer_type'] ??
                                      'N/A';
                              final companyName =
                                  request['mp_companies_table']?['name'] ??
                                      '';
                              final cardTable = request['mp_card_table'];
                              final fullName =
                                  '${request['last_name']}, ${request['first_name']}';
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
                                    chunks.add(number.substring(
                                        i,
                                        i + 4 > number.length
                                            ? number.length
                                            : i + 4));
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
                                        Expanded(
                                            child: TableCellContent(
                                                content:
                                                    request['id'].toString())),
                                        Expanded(
                                            child: TableCellContent(
                                                content: fullName)),
                                        Expanded(
                                            child: TableCellContent(
                                                content: companyName.isEmpty
                                                    ? 'N/A'
                                                    : companyName)),
                                        Expanded(
                                            child: TableCellContent(
                                                content: customerType)),
                                        Expanded(
                                            child: TableCellContent(
                                                content: cardNumbers)),
                                        Expanded(
                                            child: TableCellContent(
                                                content:
                                                    request['contact_no'] ??
                                                        'N/A')),
                                        Expanded(
                                            child: TableCellContent(
                                                content:
                                                    request['email_address'] ??
                                                        'N/A')),
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
                                                    if (state.adminType ==
                                                        'admin') {
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
                                                              10), */ // Space between icons
                                                          IconButton(
                                                            icon: const Icon(Icons
                                                                .edit), // Edit icon
                                                            onPressed:
                                                                () async {
                                                              /*setState(()  {
                                                              // Set selectedRegion
                                                              selectedRegion = regions.firstWhere(
                                                                (region) => region.regionName == request['region'],
                                                                orElse: () => Region(code: '', regionName: 'Not Found'),
                                                              ).code;

                                                              // Set selectedProvince
                                                              selectedProvince = provinces.firstWhere(
                                                                (province) => province.name == request['province'],
                                                                orElse: () => Province(code: '', name: 'Not Found'),
                                                              ).code;

                                                              // Set selectedCity
                                                              selectedCity = cities.firstWhere(
                                                                (city) => city.name == request['city'],
                                                                orElse: () => City(code: '', name: 'Not Found'),
                                                              ).code;

                                                            
                                                            });*/

                                                              if (request['region'] != null &&
                                                                  request['province'] !=
                                                                      null &&
                                                                  request['city'] !=
                                                                      null) {
                                                                selectedRegion =
                                                                    await getRegionId(
                                                                        request[
                                                                            'region']);
                                                                selectedProvince =
                                                                    await getProvinceId(
                                                                        selectedRegion!,
                                                                        request[
                                                                            'province']);
                                                                selectedCity =
                                                                    await getCityId(
                                                                        selectedProvince!,
                                                                        request[
                                                                            'city']);
                                                                print(
                                                                    selectedRegion);
                                                                print(
                                                                    selectedProvince);
                                                                print(
                                                                    selectedCity);
                                                                await fetchProvinces(
                                                                    selectedRegion!,
                                                                    setState);
                                                                await fetchCities(
                                                                    selectedProvince!,
                                                                    setState);
                                                              }

                                                              // After setState completes, fetch the provinces and other data
                                                              /*WidgetsBinding.instance.addPostFrameCallback((_) async{
                                                              // Now that the state is updated, fetch provinces, cities, and barangays
                                                               await fetchProvinces(selectedRegion!, setState);
                                                               await fetchCities(selectedProvince!, setState);
                                                               await fetchBarangays(selectedCity!, setState);  // For debugging
                                                            });*/
                                                              var myApiUrl =
                                                                  apiBaseUrl;
                                                              List<
                                                                      Map<String,
                                                                          dynamic>>
                                                                  members =
                                                                  await ApiService(
                                                                          myApiUrl)
                                                                      .getMemberById(
                                                                          request[
                                                                              'id'],
                                                                          supabaseUrl,
                                                                          supabaseKey);
                                                              //print(members[0]['mp_customer_type_table']['customer_type']);

                                                              _showDialogEdit(
                                                                  context,
                                                                  members,
                                                                  setState);
                                                            },
                                                            tooltip:
                                                                'Edit', // Optional tooltip
                                                          ),
                                                        ],
                                                      );
                                                    } else if (state
                                                            .adminType ==
                                                        'upd') {
                                                      return Row(
                                                        children: [
                                                          // Space between icons
                                                          IconButton(
                                                            icon: const Icon(Icons
                                                                .edit), // Edit icon
                                                            onPressed:
                                                                () async {
                                                              setState(() {
                                                                if (eregionController
                                                                    .text
                                                                    .isNotEmpty) {
                                                                  fetchRegions(
                                                                      setState);
                                                                  selectedRegion =
                                                                      regions
                                                                          .firstWhere(
                                                                            (region) =>
                                                                                region.regionName ==
                                                                                eregionController.text,
                                                                            orElse: () =>
                                                                                Region(code: '', regionName: 'Not Found'),
                                                                          )
                                                                          .code;
                                                                  fetchProvinces(
                                                                      selectedRegion!,
                                                                      setState);
                                                                  selectedProvince =
                                                                      provinces
                                                                          .firstWhere(
                                                                            (province) =>
                                                                                province.name ==
                                                                                eprovinceController.text,
                                                                            orElse: () =>
                                                                                Province(code: '', name: 'Not Found'),
                                                                          )
                                                                          .code;
                                                                  fetchCities(
                                                                      selectedProvince!,
                                                                      setState);
                                                                  selectedCity =
                                                                      cities
                                                                          .firstWhere(
                                                                            (city) =>
                                                                                city.name ==
                                                                                ecityController.text,
                                                                            orElse: () =>
                                                                                City(code: '', name: 'Not Found'),
                                                                          )
                                                                          .code;
                                                                  fetchBarangays(
                                                                      selectedCity!,
                                                                      setState);
                                                                }
                                                              });
                                                              var myApiUrl =
                                                                  apiBaseUrl;
                                                              List<
                                                                      Map<String,
                                                                          dynamic>>
                                                                  members =
                                                                  await ApiService(
                                                                          myApiUrl)
                                                                      .getMemberById(
                                                                          request[
                                                                              'id'],
                                                                          supabaseUrl,
                                                                          supabaseKey);
                                                              _showDialogEdit(
                                                                  context,
                                                                  members,
                                                                  setState);
                                                            },
                                                            tooltip:
                                                                'Edit', // Optional tooltip
                                                          ),
                                                        ],
                                                      );
                                                    }
                                                  }
                                                  return const SizedBox
                                                      .shrink();
                                                },
                                              ),
                                              const SizedBox(
                                                  width:
                                                      10), // Space between icons
                                              IconButton(
                                                icon: const Icon(Icons
                                                    .more_vert), // Three-dot icon
                                                onPressed: () async {
                                                  var myApiUrl = apiBaseUrl;
                                                  List<Map<String, dynamic>>
                                                      members =
                                                      await ApiService(myApiUrl)
                                                          .getMemberById(
                                                              request['id'],
                                                              supabaseUrl,
                                                              supabaseKey);
                                                  showDetails(context, members);
                                                },
                                                            tooltip:
                                                                'Edit', // Optional tooltip
                                                          ),
                                                          IconButton(
                                                            icon: Icon(
                                                              request['is_active']
                                                                  ? Icons.person_off
                                                                  : Icons.person,
                                                              color: request['is_active']
                                                                  ? Colors.red
                                                                  : Colors.green,
                                                            ),
                                                            onPressed: () async {
                                                              final confirm = await showDialog<bool>(
                                                                context: context,
                                                                builder: (ctx) => AlertDialog(
                                                                  backgroundColor: Colors.white,
                                                                  shape: RoundedRectangleBorder(
                                                                      borderRadius: BorderRadius.circular(20.0),
                                                                      side: const BorderSide(color: Color(0xff13322b), width: 2)),
                                                                  title: Center(
                                                                      child: Text(
                                                                    request['is_active']
                                                                        ? 'Deactivate Account'
                                                                        : 'Activate Account',
                                                                    style: const TextStyle(
                                                                        fontSize: 16,
                                                                        fontWeight: FontWeight.w700,
                                                                        color: Color(0xff13322b)),
                                                                  )),
                                                                  content: Text(
                                                                    request['is_active']
                                                                        ? 'Are you sure you want to deactivate ${request['first_name']} ${request['last_name']}? They will not be able to sign in.'
                                                                        : 'Are you sure you want to activate ${request['first_name']} ${request['last_name']}?',
                                                                    style: const TextStyle(color: Color(0xff13322b)),
                                                                  ),
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed: () => Navigator.pop(ctx, false),
                                                                      child: const Text('Cancel', style: TextStyle(color: Colors.black)),
                                                                    ),
                                                                    ElevatedButton(
                                                                      onPressed: () => Navigator.pop(ctx, true),
                                                                      style: ElevatedButton.styleFrom(
                                                                          backgroundColor: request['is_active']
                                                                              ? Colors.red
                                                                              : const Color(0xff13322b)),
                                                                      child: Text(
                                                                          request['is_active'] ? 'Deactivate' : 'Activate',
                                                                          style: const TextStyle(color: Colors.white)),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                              if (confirm == true) {
                                                                try {
                                                                  final response = await http.post(
                                                                    Uri.parse(adminEndpoint('update_customer')),
                                                                    headers: buildApiHeaders(),
                                                                    body: json.encode({
                                                                      'customer_id': request['id'],
                                                                      'is_active': !request['is_active'],
                                                                    }),
                                                                  );
                                                                  if (response.statusCode == 200) {
                                                                    final wasActive = request['is_active'] == true;
                                                                    request['is_active'] = !wasActive;
                                                                    if (mounted) {
                                                                      setState(() {});
                                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                                        SnackBar(
                                                                          backgroundColor:
                                                                              const Color(0xff13322b),
                                                                          content: Text(
                                                                            wasActive
                                                                                ? '${request['first_name']} deactivated'
                                                                                : '${request['first_name']} activated',
                                                                          ),
                                                                        ),
                                                                      );
                                                                    }
                                                                  } else {
                                                                    if (mounted) {
                                                                      ScaffoldMessenger.of(context)
                                                                          .showSnackBar(
                                                                        SnackBar(
                                                                          backgroundColor: Colors.red,
                                                                          content: Text(
                                                                              'Failed to update status (${response.statusCode})'),
                                                                        ),
                                                                      );
                                                                    }
                                                                  }
                                                                } catch (e) {
                                                                  if (mounted) {
                                                                    ScaffoldMessenger.of(context)
                                                                        .showSnackBar(
                                                                      SnackBar(
                                                                        backgroundColor: Colors.red,
                                                                        content: Text(
                                                                            'Error toggling active: $e'),
                                                                      ),
                                                                    );
                                                                  }
                                                                }
                                                              }
                                                            },
                                                            tooltip: request['is_active']
                                                                ? 'Deactivate'
                                                                : 'Activate',
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
              }));
        });
  }

  Future<String> getRegionId(String regionName) async {
    var apiUrl = '$ggxUrl/v2/locations/countries/PH/regions';
    var jwt = ggx.generateJwt();
    final response = await http.get(Uri.parse(apiUrl), headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $jwt',
    });

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> regionsJson = data['data'];
      var region = regionsJson.firstWhere(
        (region) => region['name'] == regionName,
        orElse: () => null,
      );
      return region?['id'].toString() ?? ''; // Return the Region ID
    }
    throw Exception('Region not found');
  }

// Fetch Province ID by Region ID
  Future<String> getProvinceId(String regionId, String provinceName) async {
    var apiUrl = '$ggxUrl/v2/locations/regions/$regionId/provinces';
    var jwt = ggx.generateJwt();
    final response = await http.get(Uri.parse(apiUrl), headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $jwt',
    });

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> provincesJson = data['data'];
      var province = provincesJson.firstWhere(
        (province) => province['name'] == provinceName,
        orElse: () => null,
      );
      return province?['id'].toString() ?? ''; // Return the Province ID
    }
    throw Exception('Province not found');
  }

  Future<String> getCityId(String provinceId, String cityName) async {
    var apiUrl = '$ggxUrl/v2/locations/provinces/$provinceId/cities';
    var jwt = ggx.generateJwt();
    final response = await http.get(Uri.parse(apiUrl), headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $jwt',
    });

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> citiesJson = data['data'];
      var city = citiesJson.firstWhere(
        (city) => city['name'] == cityName,
        orElse: () => null,
      );
      return city?['id'].toString() ?? ''; // Return the City ID
    }
    throw Exception('City not found');
  }

  void _showDialogEdit(
      BuildContext context, final request, StateSetter setState) {
    final customerType =
        request[0]['mp_customer_type_table']?['customer_type'] ?? 'N/A';
    final cardList = request[0]['mp_card_table'];
    if (cardList == null || cardList.isEmpty) {
      _showMessage('This member has no card record. Please re-add them with a valid card.', 'No Card Found');
      return;
    }
    var cardTable = cardList[0];
    var selectedCard = cardTable;
    _eselectedSex = request[0]['sex'] ?? '';
    bool hasChange = false;
    String address = request[0]['address'] ?? '';
    String brgy = request[0]['barangay'] ?? '';
    String city = request[0]['city'] ?? '';
    String myProvince = request[0]['province'] ?? '';
    String myRegion = request[0]['region'] ?? '';
    String postal = request[0]['postal_code'] ?? '';
    String rbl = (selectedCard['mp_card_plan_table'] != null &&
            selectedCard['mp_card_plan_table'].isNotEmpty)
        ? selectedCard['mp_card_plan_table'][0]['mp_plan_table']
                    ['mp_plan_room_boards_table']['rb_amount']
                .toString() ??
            "0.0"
        : '';
    String bl = (selectedCard['mp_card_plan_table'] != null &&
            selectedCard['mp_card_plan_table'].isNotEmpty)
        ? selectedCard['mp_card_plan_table'][0]['mp_plan_table']
                    ['mp_limit_table']['amount']
                .toString() ??
            "0.0"
        : '';
    String et = (selectedCard['mp_card_plan_table'] != null &&
            selectedCard['mp_card_plan_table'].isNotEmpty)
        ? selectedCard['mp_card_plan_table'][0]['mp_plan_table']
                    ['enrollment_type_id']
                .toString() ??
            ""
        : '';
    String pt = selectedCard['card_type'].toString() ?? '4';
    String rbt = (selectedCard['mp_card_plan_table'] != null &&
            selectedCard['mp_card_plan_table'].isNotEmpty)
        ? selectedCard['mp_card_plan_table'][0]['mp_plan_table']
                    ['mp_plan_room_boards_table']['rb_id']
                .toString() ??
            ""
        : '';
    String blt = (selectedCard['mp_card_plan_table'] != null &&
            selectedCard['mp_card_plan_table'].isNotEmpty)
        ? selectedCard['mp_card_plan_table'][0]['mp_plan_table']
                    ['mp_limit_table']['lt_id']
                .toString() ??
            ""
        : '';
    String ld = (selectedCard['mp_card_plan_table'] != null &&
            selectedCard['mp_card_plan_table'].isNotEmpty)
        ? selectedCard['mp_card_plan_table'][0]['mp_plan_table']['limit_id']
                .toString() ??
            ""
        : '';
    String pbd = (selectedCard['mp_card_plan_table'] != null &&
            selectedCard['mp_card_plan_table'].isNotEmpty)
        ? selectedCard['mp_card_plan_table'][0]['mp_plan_table']['prb_id']
                .toString() ??
            ""
        : '';
    String cid = (selectedCard['mp_card_plan_table'] != null &&
            selectedCard['mp_card_plan_table'].isNotEmpty)
        ? selectedCard['mp_card_plan_table'][0]['card_id'].toString() ?? ""
        : '';
    String pd = (selectedCard['mp_card_plan_table'] != null &&
            selectedCard['mp_card_plan_table'].isNotEmpty)
        ? selectedCard['mp_card_plan_table'][0]['plan_id'].toString() ?? ""
        : '';
    String mail = request[0]['email_address'] ?? '';
    setState(() {
      efnameController.text = request[0]['first_name'];
      emnameController.text = request[0]['middle_name'] ?? '';
      elnameController.text = request[0]['last_name'];
      econtactNoController.text = request[0]['contact_no'] ?? '';
      eemailController.text = mail;
      ememberTypeController.text = request[0]['type_id'].toString();
      _birthday = request[0]['birth_date'] != null
          ? DateTime.parse(request[0]['birth_date'])
          : null;
      ecivilStatusController.text = request[0]['civil_status'] ?? '';
      ehouseAddressController.text = address;
      ebarangayController.text = brgy;
      ecityController.text = city;
      eprovinceController.text = myProvince;
      eregionController.text = myRegion;
      epostalCodeController.text = postal;
      eroomAndBoardLimitController.text = rbl;
      ebenefitLimitController.text = bl;
      eenrollmentTypeController.text = et;
      eplanTypeController.text = pt;
      eroomAndBoardTypeController.text = rbt;
      ebenefitLimitTypeController.text = blt;
      customerId = request[0]['id'].toString();
      limit_id = ld;
      prb_id = pbd;
      card_id = cid;
      plan_id = pd;
      if (eplanTypeController.text == '4') {
        ecardTypeController.text = 'PSMBFI';
      }
      ecardNumberController.text = selectedCard['card_number'];
      ecardExpiryController.text = selectedCard['expiration_date'] ?? '';
      ecardEffectiveController.text = selectedCard['effective_date'] ?? '';
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
                width: MediaQuery.of(context).size.width * 0.9 > 900 ? 900 : MediaQuery.of(context).size.width * 0.9,
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
                                    label: const Row(
                                      children: [
                                        Text('First Name',
                                            style:
                                                TextStyle(color: Colors.black)),
                                        Text(' *',
                                            style: TextStyle(
                                                color: Colors
                                                    .red)), // Asterisk in red
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
                                      label: const Row(
                                        children: [
                                          Text('Middle Name',
                                              style: TextStyle(
                                                  color: Colors.black)),
                                          Text(' *',
                                              style: TextStyle(
                                                  color: Colors
                                                      .red)), // Asterisk in red
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
                                      label: const Row(
                                        children: [
                                          Text('Last Name',
                                              style: TextStyle(
                                                  color: Colors.black)),
                                          Text(' *',
                                              style: TextStyle(
                                                  color: Colors
                                                      .red)), // Asterisk in red
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
                                label: const Row(
                                  children: [
                                    Text('Contact No',
                                        style: TextStyle(color: Colors.black)),
                                    Text(' *',
                                        style: TextStyle(
                                            color:
                                                Colors.red)), // Asterisk in red
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
                                  } else if (value!.length < 11) {
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
                                label: const Row(
                                  children: [
                                    Text('Email Address',
                                        style: TextStyle(color: Colors.black)),
                                    Text(' *',
                                        style: TextStyle(
                                            color:
                                                Colors.red)), // Asterisk in red
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
                                  if (value!.isNotEmpty) {
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
                                                  groupValue:
                                                      _eselectedSex, // Set groupValue to _selectedSex
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _eselectedSex = value ??
                                                          ''; // Update the selected value
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
                                                        _eselectedSex, // Set groupValue to _selectedSex
                                                    onChanged: (value) {
                                                      setState(() {
                                                        _eselectedSex = value ??
                                                            ''; // Update the selected value
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
                                          _selectDate(context, setState,
                                              _birthday.toString());
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
                                      onChanged: (selectedItem) {},
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
                                      label: const Row(
                                        children: [
                                          Text('House Address',
                                              style: TextStyle(
                                                  color: Colors.black)),
                                          Text(' *',
                                              style: TextStyle(
                                                  color: Colors
                                                      .red)), // Asterisk in red
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
                                  itemAsString: (region) => region.regionName,
                                  hintText: 'Select Region',
                                  selectedItem: regions.firstWhere(
                                    (region) =>
                                        region.regionName == myRegion ||
                                        (region.code == selectedRegion &&
                                            region.regionName != myRegion),
                                    orElse: () => Region(
                                        code: '', regionName: 'Select Region'),
                                  ),
                                  onChanged: (Region? newValue) {
                                    setState(() {
                                      selectedRegion = newValue?.code;
                                      eregionController.text =
                                          newValue!.regionName;
                                      fetchProvinces(selectedRegion!, setState);
                                      provinces
                                          .clear(); // Clear previous provinces
                                      cities.clear(); // Clear previous cities
                                      barangays
                                          .clear(); // Clear previous barangays
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
                                    (province) =>
                                        province.name ==
                                            eprovinceController.text ||
                                        (province.code == selectedProvince &&
                                            province.name !=
                                                eprovinceController.text),
                                    orElse: () => Province(
                                        code: '', name: 'Select Province'),
                                  ),
                                  onChanged: (Province? newValue) {
                                    setState(() {
                                      selectedProvince = newValue?.code;
                                      eprovinceController.text = newValue!.name;
                                      fetchCities(selectedProvince!, setState);
                                      cities.clear(); // Clear previous cities
                                      barangays
                                          .clear(); // Clear previous barangays
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
                                    (city) =>
                                        city.name == ecityController.text ||
                                        (city.code == selectedCity &&
                                            city.name != ecityController.text),
                                    orElse: () =>
                                        City(code: '', name: 'Select City'),
                                  ),
                                  onChanged: (City? newValue) {
                                    setState(() {
                                      selectedCity = newValue?.code;
                                      ecityController.text = newValue!.name;
                                      fetchBarangays(selectedCity!,
                                          setState); // Clear previous cities
                                      barangays
                                          .clear(); // Clear previous barangays
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
                                    (brgy) =>
                                        brgy.name == ebarangayController.text ||
                                        (brgy.code == selectedBarangay &&
                                            brgy.name !=
                                                ebarangayController.text),
                                    orElse: () => Barangay(
                                        code: '',
                                        name: 'Select Barangay',
                                        postal: ''),
                                  ),
                                  onChanged: (Barangay? newValue) {
                                    setState(() {
                                      selectedBarangay = newValue?.code;
                                      ebarangayController.text = newValue!.name;
                                      epostalCodeController.text =
                                          newValue.postal;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: CustomTextFormField(
                                  label: const Row(
                                    children: [
                                      Text('Postal Code',
                                          style:
                                              TextStyle(color: Colors.black)),
                                      Text(' *',
                                          style: TextStyle(
                                              color: Colors
                                                  .red)), // Asterisk in red
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
                                          ebenefitLimitController.text = '';
                                          eroomAndBoardLimitController.text =
                                              '';
                                          _isFormValid = true;
                                          selectedRegion = null;
                                          _eselectedSex = null;
                                          _birthday = null;
                                          /*provinces.clear();
                                          cities.clear();
                                          barangays.clear();*/
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

                                        if (!_formKey.currentState!.validate())
                                          return;
                                        if (econtactNoController
                                                .text.isNotEmpty &&
                                            econtactNoController.text.length ==
                                                11) {
                                          if (regExp.hasMatch(
                                                  eemailController.text) &&
                                              efnameController
                                                  .text.isNotEmpty &&
                                              elnameController
                                                  .text.isNotEmpty &&
                                              _birthday != null) {
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
                                                  child: StatefulBuilder(
                                                      builder:
                                                          (BuildContext context,
                                                              setState) {
                                                    return isLoading
                                                        ? const SizedBox(
                                                            width:
                                                                900, // Set the fixed width of the form to 120
                                                            height: 650,
                                                            child: Center(
                                                              child:
                                                                  SpinKitCircle(
                                                                color: Color(
                                                                    0xff13322B),
                                                                size: 50.0,
                                                              ),
                                                            ),
                                                          ) // Show spinner when loading
                                                        : Form(
                                                            key: _formKey2,
                                                            child: SizedBox(
                                                              width:
                                                                  900, // Set the fixed width of the form to 120
                                                              height:
                                                                  650, // Adjust height as needed to fit additional rows
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        left:
                                                                            20,
                                                                        right:
                                                                            20,
                                                                        top:
                                                                            27), // Add padding inside modal
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start, // Align content to start
                                                                  children: [
                                                                    const Text(
                                                                      "Edit Member",
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            18,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        color: Color(
                                                                            0xff13322b), // Set title text color to black
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                        height:
                                                                            38),

                                                                    // Personal Details Title
                                                                    Container(
                                                                      alignment:
                                                                          Alignment
                                                                              .centerLeft, // Align to the left
                                                                      child:
                                                                          const Text(
                                                                        "Plan Details", // Title for the radio buttons
                                                                        style:
                                                                            TextStyle(
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          color:
                                                                              Color(0xff13322b), // Set title color
                                                                        ),
                                                                        textAlign:
                                                                            TextAlign.left, // Align text to the left
                                                                      ),
                                                                    ),

                                                                    Align(
                                                                      alignment:
                                                                          Alignment
                                                                              .centerRight,
                                                                      child: TextButton
                                                                          .icon(
                                                                        onPressed:
                                                                            () async {
                                                                          final updated =
                                                                              await _showPlanTypeManagerDialog(context);
                                                                          if (updated) {
                                                                            setState(() {});
                                                                          }
                                                                        },
                                                                        icon:
                                                                            const Icon(
                                                                          Icons
                                                                              .tune,
                                                                          size:
                                                                              16,
                                                                          color:
                                                                              Color(0xff13322b),
                                                                        ),
                                                                        label:
                                                                            const Text(
                                                                          'Manage Plan Types',
                                                                          style:
                                                                              TextStyle(
                                                                            color:
                                                                                Color(0xff13322b),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),

                                                                    const SizedBox(
                                                                        height:
                                                                            10), // Space below the title

                                                                    // First row with 3 text fields
                                                                    Row(
                                                                      children: [
                                                                        Expanded(
                                                                          child:
                                                                              CustomListDropdownFormField(
                                                                            label:
                                                                                'Select Member Type',
                                                                            labelStyle:
                                                                                const TextStyle(
                                                                              color: Color(0xff13322b),
                                                                            ),
                                                                            items:
                                                                                memberTypeItems,
                                                                            controller:
                                                                                ememberTypeController,
                                                                            onChanged:
                                                                                (selectedItem) {
                                                                              setState(() {
                                                                                ememberTypeController.text = ememberTypeController.text;
                                                                              });
                                                                            },
                                                                          ),
                                                                        ),

                                                                        const SizedBox(
                                                                            width:
                                                                                8), // Space between text fields
                                                                        Expanded(
                                                                          child:
                                                                              CustomListDropdownFormField(
                                                                            label:
                                                                                'Select Enrollment Type',
                                                                            labelStyle:
                                                                                const TextStyle(
                                                                              color: Color(0xff13322b),
                                                                            ),
                                                                            items:
                                                                                enrollmentTypeItems,
                                                                            controller:
                                                                                eenrollmentTypeController,
                                                                            onChanged:
                                                                                (selectedItem) {
                                                                              setState(() {
                                                                                eenrollmentTypeController.text = eenrollmentTypeController.text;
                                                                              });
                                                                            },
                                                                          ),
                                                                        ),

                                                                        const SizedBox(
                                                                            width:
                                                                                8),
                                                                        Expanded(
                                                                          child:
                                                                              CustomListDropdownFormField(
                                                                            label:
                                                                                'Select Plan Type',
                                                                            labelStyle:
                                                                                const TextStyle(
                                                                              color: Color(0xff13322b),
                                                                            ),
                                                                            items:
                                                                                _localPlanTypeItems,
                                                                            controller:
                                                                                eplanTypeController,
                                                                            onChanged:
                                                                                (selectedItem) {
                                                                              setState(() {
                                                                                eplanTypeController.text = eplanTypeController.text;
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
                                                                          child:
                                                                              CustomListDropdownFormField(
                                                                            label:
                                                                                'Select Room and Board Type',
                                                                            labelStyle:
                                                                                const TextStyle(
                                                                              color: Color(0xff13322b),
                                                                            ),
                                                                            items:
                                                                                roomBoardTypeItems,
                                                                            controller:
                                                                                eroomAndBoardTypeController,
                                                                            onChanged:
                                                                                (selectedItem) {
                                                                              setState(() {
                                                                                eroomAndBoardTypeController.text = eroomAndBoardTypeController.text;
                                                                              });
                                                                            },
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                            width:
                                                                                8),
                                                                        Expanded(
                                                                          child: CustomTextFormField(
                                                                              label: const Row(
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
                                                                    const SizedBox(
                                                                        height:
                                                                            16), // Add spacing between rows

                                                                    // Third row with 2 text fields
                                                                    Row(
                                                                      children: [
                                                                        Expanded(
                                                                          child:
                                                                              CustomListDropdownFormField(
                                                                            label:
                                                                                'Select Benefit Limit Type',
                                                                            labelStyle:
                                                                                const TextStyle(
                                                                              color: Color(0xff13322b),
                                                                            ),
                                                                            items:
                                                                                benefitTypeItems,
                                                                            controller:
                                                                                ebenefitLimitTypeController,
                                                                            onChanged:
                                                                                (selectedItem) {
                                                                              setState(() {
                                                                                ebenefitLimitTypeController.text = ebenefitLimitTypeController.text;
                                                                              });
                                                                            },
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                            width:
                                                                                8),
                                                                        Expanded(
                                                                          child: CustomTextFormField(
                                                                              label: const Row(
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
                                                                        height:
                                                                            20),
                                                                    const SizedBox(
                                                                        height:
                                                                            10), // Space above the title

                                                                    // Personal Details Title
                                                                    Container(
                                                                      alignment:
                                                                          Alignment
                                                                              .centerLeft, // Align to the left
                                                                      child:
                                                                          const Text(
                                                                        "Card Details", // Title for the radio buttons
                                                                        style:
                                                                            TextStyle(
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          color:
                                                                              Color(0xff13322b), // Set title color
                                                                        ),
                                                                        textAlign:
                                                                            TextAlign.left, // Align text to the left
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
                                                                            label:
                                                                                const Row(
                                                                              children: [
                                                                                Text('Card Type', style: TextStyle(color: Colors.black)),
                                                                                Text(' *', style: TextStyle(color: Colors.red)), // Asterisk in red
                                                                              ],
                                                                            ),
                                                                            labelStyle:
                                                                                const TextStyle(
                                                                              color: Color(0xff13322b),
                                                                              fontSize: 14,
                                                                            ),
                                                                            controller:
                                                                                ecardTypeController,
                                                                            isRead:
                                                                                false,
                                                                            isNumeric:
                                                                                false,
                                                                            validator:
                                                                                (value) {
                                                                              //return null;
                                                                            },
                                                                            maxLength:
                                                                                16,
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                            width:
                                                                                8),
                                                                        Expanded(
                                                                          child:
                                                                              CustomTextFormField(
                                                                            label:
                                                                                const Row(
                                                                              children: [
                                                                                Text('Card Number', style: TextStyle(color: Colors.black)),
                                                                                Text(' *', style: TextStyle(color: Colors.red)), // Asterisk in red
                                                                              ],
                                                                            ),
                                                                            labelStyle:
                                                                                const TextStyle(
                                                                              color: Color(0xff13322b),
                                                                              fontSize: 14,
                                                                            ),
                                                                            controller:
                                                                                ecardNumberController,
                                                                            isNumeric:
                                                                                true,
                                                                            validator:
                                                                                (value) {
                                                                              //return null;
                                                                              if (value == null || value.isEmpty) {
                                                                                return 'Card number is required';
                                                                              } else if (value.length != 16) {
                                                                                return 'Card number should be 16 digit';
                                                                              }
                                                                              return null;
                                                                            },
                                                                            maxLength:
                                                                                16,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    const SizedBox(
                                                                        height:
                                                                            10),
                                                                    // Card Expiry Date row
                                                                    Row(
                                                                      children: [
                                                                        Expanded(
                                                                          child: GestureDetector(
                                                                            onTap: () async {
                                                                              final picked = await showDatePicker(
                                                                                context: context,
                                                                                initialDate: DateTime.now(),
                                                                                firstDate: DateTime(2020),
                                                                                lastDate: DateTime(2040),
                                                                                builder: (context, child) {
                                                                                  return Theme(
                                                                                    data: Theme.of(context).copyWith(
                                                                                      colorScheme: const ColorScheme.light(primary: Color(0xff13322b)),
                                                                                    ),
                                                                                    child: child!,
                                                                                  );
                                                                                },
                                                                              );
                                                                              if (picked != null) {
                                                                                setState(() {
                                                                                  cardEffectiveController.text = picked.toIso8601String().split('T')[0];
                                                                                });
                                                                              }
                                                                            },
                                                                            child: AbsorbPointer(
                                                                              child: CustomTextFormField(
                                                                                label: const Row(
                                                                                  children: [
                                                                                    Text('Effective Date', style: TextStyle(color: Colors.black)),
                                                                                    Text(' *', style: TextStyle(color: Colors.red)),
                                                                                  ],
                                                                                ),
                                                                                labelStyle: const TextStyle(color: Color(0xff13322b), fontSize: 14),
                                                                                controller: cardEffectiveController,
                                                                                isNumeric: false,
                                                                                validator: (value) {
                                                                                  if (value == null || value.isEmpty) {
                                                                                    return 'Effective date is required';
                                                                                  }
                                                                                  return null;
                                                                                },
                                                                                maxLength: 10,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        const SizedBox(width: 8),
                                                                        Expanded(
                                                                          child: GestureDetector(
                                                                            onTap: () async {
                                                                              final picked = await showDatePicker(
                                                                                context: context,
                                                                                initialDate: DateTime.now().add(const Duration(days: 365)),
                                                                                firstDate: DateTime(2020),
                                                                                lastDate: DateTime(2040),
                                                                                builder: (context, child) {
                                                                                  return Theme(
                                                                                    data: Theme.of(context).copyWith(
                                                                                      colorScheme: const ColorScheme.light(primary: Color(0xff13322b)),
                                                                                    ),
                                                                                    child: child!,
                                                                                  );
                                                                                },
                                                                              );
                                                                              if (picked != null) {
                                                                                setState(() {
                                                                                  cardExpiryController.text = picked.toIso8601String().split('T')[0];
                                                                                });
                                                                              }
                                                                            },
                                                                            child: AbsorbPointer(
                                                                              child: CustomTextFormField(
                                                                                label: const Row(
                                                                                  children: [
                                                                                    Text('Expiry Date', style: TextStyle(color: Colors.black)),
                                                                                    Text(' *', style: TextStyle(color: Colors.red)),
                                                                                  ],
                                                                                ),
                                                                                labelStyle: const TextStyle(color: Color(0xff13322b), fontSize: 14),
                                                                                controller: cardExpiryController,
                                                                                isNumeric: false,
                                                                                validator: (value) {
                                                                                  if (value == null || value.isEmpty) {
                                                                                    return 'Expiry date is required';
                                                                                  }
                                                                                  return null;
                                                                                },
                                                                                maxLength: 10,
                                                                              ),
                                                                            ),
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
                                                                    SizedBox(
                                                                        height: _isFormValid
                                                                            ? 160
                                                                            : 100), // Spacing before the close button
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
                                                                            onPressed:
                                                                                () {
                                                                              Navigator.pop(context); // Close the dialog
                                                                            },
                                                                            style:
                                                                                ElevatedButton.styleFrom(
                                                                              shape: RoundedRectangleBorder(
                                                                                borderRadius: BorderRadius.circular(5),
                                                                                side: const BorderSide(color: Color(0xff13322b)), // Set the border color
                                                                              ),
                                                                              backgroundColor: Colors.white, // Set button background color to white
                                                                            ),
                                                                            child:
                                                                                const Text(
                                                                              'Back',
                                                                              style: TextStyle(color: Colors.black), // Set button text color to black for visibility
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                            width:
                                                                                10),
                                                                        if (efnameController.text != request[0]['first_name'] ||
                                                                            emnameController.text !=
                                                                                request[0]['middle_name'] ||
                                                                            elnameController.text != request[0]['last_name'] ||
                                                                            econtactNoController.text != request[0]['contact_no'] ||
                                                                            eemailController.text != mail ||
                                                                            _eselectedSex != request[0]['sex'] ||
                                                                            _birthday != DateTime.parse(request[0]['birth_date']) ||
                                                                            ecivilStatusController.text != request[0]['civil_status'] ||
                                                                            ehouseAddressController.text != address ||
                                                                            eregionController.text != myRegion ||
                                                                            eprovinceController.text != myProvince ||
                                                                            ecityController.text != city ||
                                                                            ebarangayController.text != brgy ||
                                                                            epostalCodeController.text != postal ||
                                                                            ememberTypeController.text != request[0]['type_id'].toString() ||
                                                                            eenrollmentTypeController.text != et ||
                                                                            eplanTypeController.text != pt ||
                                                                            eroomAndBoardTypeController.text != rbt ||
                                                                            eroomAndBoardLimitController.text != rbl ||
                                                                            ebenefitLimitTypeController.text != blt)
                                                                          SizedBox(
                                                                            width:
                                                                                200, // Set a fixed width for both buttons
                                                                            height:
                                                                                40, // Set a fixed height for both buttons
                                                                            child:
                                                                                ElevatedButton(
                                                                              onPressed: () {
                                                                                if (!_formKey2.currentState!.validate()) return;
                                                                                if (eroomAndBoardLimitController.text.isNotEmpty && ebenefitLimitController.text.isNotEmpty && ecardNumberController.text.isNotEmpty) {
                                                                                  if (ecardNumberController.text.length == 16) {
                                                                                    updateMember();
                                                                                    setState(() {
                                                                                      isLoading = true;
                                                                                    });
                                                                                  }
                                                                                }
                                                                              },
                                                                              style: ElevatedButton.styleFrom(
                                                                                shape: RoundedRectangleBorder(
                                                                                  borderRadius: BorderRadius.circular(5),
                                                                                ),
                                                                                backgroundColor: const Color(0xff13322b), // Set button background color
                                                                              ),
                                                                              child: const Text(
                                                                                "Update",
                                                                                style: TextStyle(
                                                                                  color: Colors.white, // Set submit button text color to white
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

  void showDetails(BuildContext context, final request) {
    if (request == null || request.isEmpty) {
      _showMessage(
          'Unable to load member details. Please try again.', 'No Data Found');
      return;
    }
    final firstMember = request[0];
    if (firstMember == null) {
      _showMessage(
          'Unable to load member details. Please try again.', 'No Data Found');
      return;
    }
    final customerType =
        firstMember['mp_customer_type_table']?['customer_type'] ?? 'N/A';
    final cardList = firstMember['mp_card_table'];
    if (cardList == null || (cardList is List && cardList.isEmpty)) {
      _showMessage(
          'This member has no card record on file.', 'No Card Found');
      return;
    }
    var cardTable = cardList[0];
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
                                Text(
                                    request[0]['first_name']?.toString() ??
                                        'N/A',
                                    style:
                                        const TextStyle(color: Colors.black)),
                              ]),
                              TableRow(children: [
                                const Text("Middle Name",
                                    style: TextStyle(color: Colors.black)),
                                Text(request[0]['middle_name'] ?? 'N/A',
                                    style:
                                        const TextStyle(color: Colors.black)),
                              ]),
                              TableRow(children: [
                                const Text("Last Name",
                                    style: TextStyle(color: Colors.black)),
                                Text(
                                    request[0]['last_name']?.toString() ??
                                        'N/A',
                                    style:
                                        const TextStyle(color: Colors.black)),
                              ]),
                              TableRow(children: [
                                const Text("Contact Number",
                                    style: TextStyle(color: Colors.black)),
                                Text(
                                    request[0]['contact_no']?.toString() ??
                                        'N/A',
                                    style:
                                        const TextStyle(color: Colors.black)),
                              ]),
                              TableRow(children: [
                                const Text("Email Address",
                                    style: TextStyle(color: Colors.black)),
                                Text(request[0]['email_address'] ?? 'N/A',
                                    style:
                                        const TextStyle(color: Colors.black)),
                              ]),
                              TableRow(children: [
                                const Text("Sex",
                                    style: TextStyle(color: Colors.black)),
                                Text(request[0]['sex'] ?? 'N/A',
                                    style:
                                        const TextStyle(color: Colors.black)),
                              ]),
                              TableRow(children: [
                                const Text("Birthdate",
                                    style: TextStyle(color: Colors.black)),
                                Text(
                                    request[0]['birth_date']?.toString() ??
                                        'N/A',
                                    style:
                                        const TextStyle(color: Colors.black)),
                              ]),
                              TableRow(children: [
                                const Text("Civil Status",
                                    style: TextStyle(color: Colors.black)),
                                Text(request[0]['civil_status'] ?? 'N/A',
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
                                Text(request[0]['address'] ?? 'N/A',
                                    style:
                                        const TextStyle(color: Colors.black)),
                              ]),
                              TableRow(children: [
                                const Text("Barangay",
                                    style: TextStyle(color: Colors.black)),
                                Text(request[0]['barangay'] ?? 'N/A',
                                    style:
                                        const TextStyle(color: Colors.black)),
                              ]),
                              TableRow(children: [
                                const Text("City",
                                    style: TextStyle(color: Colors.black)),
                                Text(request[0]['city'] ?? 'N/A',
                                    style:
                                        const TextStyle(color: Colors.black)),
                              ]),
                              TableRow(children: [
                                const Text("Province",
                                    style: TextStyle(color: Colors.black)),
                                Text(request[0]['province'] ?? 'N/A',
                                    style:
                                        const TextStyle(color: Colors.black)),
                              ]),
                              TableRow(children: [
                                const Text("Region",
                                    style: TextStyle(color: Colors.black)),
                                Text(request[0]['region'] ?? 'N/A',
                                    style:
                                        const TextStyle(color: Colors.black)),
                              ]),
                              TableRow(children: [
                                const Text("Postal Code",
                                    style: TextStyle(color: Colors.black)),
                                Text(request[0]['postal_code'] ?? 'N/A',
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
                                const Text("Member Type",
                                    style: TextStyle(color: Colors.black)),
                                Text(customerType ?? 'N/A',
                                    style:
                                        const TextStyle(color: Colors.black)),
                              ]),
                              TableRow(children: [
                                const Text("Enrollment Type",
                                    style: TextStyle(color: Colors.black)),
                                Text(
                                  (selectedCard['mp_card_plan_table'] != null &&
                                          selectedCard['mp_card_plan_table']
                                              .isNotEmpty)
                                      ? selectedCard['mp_card_plan_table'][0]
                                                      ['mp_plan_table']
                                                  ['mp_enrollment_type_table']
                                              ['enrollment_type'] ??
                                          "N/A"
                                      : 'N/A',
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ]),
                              TableRow(children: [
                                const Text("Plan Type",
                                    style: TextStyle(color: Colors.black)),
                                Text(
                                  (selectedCard['mp_card_plan_table'] != null &&
                                          selectedCard['mp_card_plan_table']
                                              .isNotEmpty)
                                      ? selectedCard['mp_card_plan_table'][0]
                                                          ['mp_plan_table']
                                                      ['mp_limit_table']
                                                  ['mp_limit_type_table']
                                              ['limit_type'] ??
                                          "N/A"
                                      : "N/A",
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ]),
                              TableRow(children: [
                                const Text("Room and Board Type",
                                    style: TextStyle(color: Colors.black)),
                                Text(
                                  (selectedCard['mp_card_plan_table'] != null &&
                                          selectedCard['mp_card_plan_table']
                                              .isNotEmpty)
                                      ? selectedCard['mp_card_plan_table'][0]
                                                          ['mp_plan_table']
                                                      [
                                                      'mp_plan_room_boards_table']
                                                  ['mp_room_boards_table']
                                              ['room_boards'] ??
                                          "N/A"
                                      : 'N/A',
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ]),
                              TableRow(children: [
                                const Text("Room and Board Limit",
                                    style: TextStyle(color: Colors.black)),
                                Text(
                                  (selectedCard['mp_card_plan_table'] != null &&
                                          selectedCard['mp_card_plan_table']
                                              .isNotEmpty)
                                      ? selectedCard['mp_card_plan_table'][0]
                                                          ['mp_plan_table'][
                                                      'mp_plan_room_boards_table']
                                                  ['rb_amount']
                                              ?.toString() ??
                                          "0.0"
                                      : 'N/A',
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ]),
                              TableRow(children: [
                                const Text("Benefit Limit",
                                    style: TextStyle(color: Colors.black)),
                                Text(
                                  (selectedCard['mp_card_plan_table'] != null &&
                                          selectedCard['mp_card_plan_table']
                                              .isNotEmpty)
                                      ? selectedCard['mp_card_plan_table'][0]
                                                      ['mp_plan_table']
                                                  ['mp_limit_table']['amount']
                                              ?.toString() ??
                                          "0.0"
                                      : 'N/A',
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ]),
                              TableRow(children: [
                                const Text("Card Type",
                                    style: TextStyle(color: Colors.black)),
                                Text(
                                  (selectedCard['mp_card_variants_table'] !=
                                          null)
                                      ? selectedCard['mp_card_variants_table']
                                              ['card_variant'] ??
                                          'N/A'
                                      : 'N/A',
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ]),
                              TableRow(children: [
                                const Text("Card Number",
                                    style: TextStyle(color: Colors.black)),
                                Text(
                                  selectedCard['card_number'] ?? 'N/A',
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ]),
                              TableRow(children: [
                                const Text("Card Validity",
                                    style: TextStyle(color: Colors.black)),
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

  Widget _buildPillStepperHeader(StateSetter dialogSetState) {
    final stepLabels = ['Member Info', 'Plan & Card', 'Confirm'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
      child: Row(
        children: List.generate(stepLabels.length, (i) {
          final isActive = i == _addMemberStep;
          final isCompleted = i < _addMemberStep;
          final isClickable = i < _addMemberStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: isClickable
                        ? () => dialogSetState(() => _addMemberStep = i)
                        : null,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xff13322b)
                            : (isCompleted
                                ? const Color(0xffE8F0ED)
                                : const Color(0xffF1F1F1)),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.white
                                  : const Color(0xff13322b),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: isCompleted
                                  ? const Icon(Icons.check,
                                      size: 14, color: Color(0xff13322b))
                                  : Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        color: isActive
                                            ? const Color(0xff13322b)
                                            : Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              stepLabels[i],
                              style: TextStyle(
                                color: isActive
                                    ? Colors.white
                                    : (isCompleted
                                        ? const Color(0xff13322b)
                                        : const Color(0xff757575)),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (i < stepLabels.length - 1)
                  Container(
                    width: 6,
                    height: 1.5,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    color: isCompleted
                        ? const Color(0xff13322b)
                        : const Color(0xffE0E0E0),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDialogHeader(BuildContext ctx, StateSetter setState) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 16, 18),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xffE8ECEF), width: 1),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Member',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff13322b))),
                SizedBox(height: 2),
                Text('Fill in the details to register a new member.',
                    style: TextStyle(fontSize: 12, color: Color(0xff7A8A86))),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _pickFiles(setState),
            icon: const Icon(Icons.upload_file,
                size: 18, color: Color(0xff13322b)),
            label: const Text('Bulk Upload',
                style: TextStyle(
                    color: Color(0xff13322b), fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xff13322b), width: 1.2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: () => Navigator.pop(ctx),
            icon: const Icon(Icons.close, color: Color(0xff13322b)),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xff13322b),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xff13322b),
                letterSpacing: 0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(BuildContext ctx, StateSetter setState) {
    switch (_addMemberStep) {
      case 0:
        return _buildStep1MemberInfo(ctx, setState);
      case 1:
        return _buildStep2PlanCard(ctx, setState);
      case 2:
        return _buildStep3Confirm(ctx, setState);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1MemberInfo(BuildContext ctx, StateSetter setState) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Personal Details'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomTextFormField(
                  label: const Row(children: [
                    Text('First Name', style: TextStyle(color: Colors.black)),
                    Text(' *', style: TextStyle(color: Colors.red)),
                  ]),
                  labelStyle: const TextStyle(
                      color: Color(0xff13322b), fontSize: 13),
                  controller: fnameController,
                  isNumeric: false,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'First name is required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextFormField(
                  label: const Row(children: [
                    Text('Middle Name', style: TextStyle(color: Colors.black)),
                  ]),
                  labelStyle: const TextStyle(
                      color: Color(0xff13322b), fontSize: 13),
                  controller: mnameController,
                  isNumeric: false,
                  validator: (value) => null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextFormField(
                  label: const Row(children: [
                    Text('Last Name', style: TextStyle(color: Colors.black)),
                    Text(' *', style: TextStyle(color: Colors.red)),
                  ]),
                  labelStyle: const TextStyle(
                      color: Color(0xff13322b), fontSize: 13),
                  controller: lnameController,
                  isNumeric: false,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Last name is required';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomTextFormField(
                  label: const Row(children: [
                    Text('Contact No', style: TextStyle(color: Colors.black)),
                    Text(' *', style: TextStyle(color: Colors.red)),
                  ]),
                  labelStyle: const TextStyle(
                      color: Color(0xff13322b), fontSize: 13),
                  controller: contactNoController,
                  isNumeric: true,
                  maxLength: 11,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Contact number is required';
                    }
                    final regExp = RegExp(r'^\d+$');
                    if (!regExp.hasMatch(value)) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextFormField(
                  label: const Row(children: [
                    Text('Email Address',
                        style: TextStyle(color: Colors.black)),
                    Text(' *', style: TextStyle(color: Colors.red)),
                  ]),
                  labelStyle: const TextStyle(
                      color: Color(0xff13322b), fontSize: 13),
                  controller: emailController,
                  isNumeric: false,
                  isEmail: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email address is required';
                    }
                    final regExp = RegExp(
                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                    if (!regExp.hasMatch(value)) {
                      return 'Please input a valid email';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildSexField(setState)),
              const SizedBox(width: 12),
              Expanded(child: _buildBirthdayField(ctx, setState)),
              const SizedBox(width: 12),
              Expanded(
                child: CustomStringDropdownFormField(
                  label: 'Civil Status',
                  labelStyle: const TextStyle(
                      color: Color(0xff13322b), fontSize: 13),
                  items: civilStatusTypeItems,
                  controller: civilStatusController,
                  onChanged: (selectedItem) {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _buildSectionHeader('Address'),
          CustomTextFormField(
            label: const Row(children: [
              Text('House Address', style: TextStyle(color: Colors.black)),
            ]),
            labelStyle: const TextStyle(
                color: Color(0xff13322b), fontSize: 13),
            controller: houseAddressController,
            isNumeric: false,
            validator: (value) => null,
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildRegionDropdown(setState)),
              const SizedBox(width: 12),
              Expanded(child: _buildProvinceDropdown(setState)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildCityDropdown(setState)),
              const SizedBox(width: 12),
              Expanded(child: _buildBarangayDropdown(setState)),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextFormField(
                  label: const Row(children: [
                    Text('Postal Code', style: TextStyle(color: Colors.black)),
                  ]),
                  labelStyle: const TextStyle(
                      color: Color(0xff13322b), fontSize: 13),
                  controller: postalCodeController,
                  isNumeric: true,
                  maxLength: 4,
                  validator: (value) => null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSexField(StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Sex *',
            style: TextStyle(
                fontSize: 13,
                color: Color(0xff13322b),
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(
              color: noSex
                  ? Colors.red.withOpacity(0.5)
                  : const Color(0xff13322b).withOpacity(0.35),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Radio<String>(
                      value: 'Male',
                      groupValue: _selectedSex,
                      onChanged: (v) => setState(() => _selectedSex = v),
                      activeColor: const Color(0xff13322b),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ),
                    const Text('Male',
                        style: TextStyle(
                            fontSize: 13, color: Color(0xff13322b))),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Radio<String>(
                      value: 'Female',
                      groupValue: _selectedSex,
                      onChanged: (v) => setState(() => _selectedSex = v),
                      activeColor: const Color(0xff13322b),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ),
                    const Text('Female',
                        style: TextStyle(
                            fontSize: 13, color: Color(0xff13322b))),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (noSex)
          const Padding(
            padding: EdgeInsets.only(left: 4, top: 4),
            child: Text('Please select a sex',
                style: TextStyle(fontSize: 11, color: Colors.red)),
          ),
      ],
    );
  }

  Widget _buildBirthdayField(BuildContext ctx, StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Birthday *',
            style: TextStyle(
                fontSize: 13,
                color: Color(0xff13322b),
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () {
            setState(() => isDateError = false);
            _selectDate(ctx, setState, _birthday.toString());
          },
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              border: Border.all(
                color: isDateError
                    ? Colors.red.withOpacity(0.5)
                    : const Color(0xff13322b).withOpacity(0.35),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 14, color: Color(0xff13322b)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _birthday != null
                        ? "${_birthday?.toLocal()}".split(' ')[0]
                        : dateLabel,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDateError
                          ? Colors.red.withOpacity(0.7)
                          : const Color(0xff13322b),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isDateError)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4),
            child: Text(dateLabel,
                style: const TextStyle(fontSize: 11, color: Colors.red)),
          ),
      ],
    );
  }

  Widget _buildRegionDropdown(StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Region',
            style: TextStyle(
                fontSize: 13,
                color: Color(0xff13322b),
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        SizedBox(
          height: 48,
          child: CustomDropdown<Region>(
            items: regions,
            itemAsString: (r) => r.regionName,
            hintText: 'Select Region',
            selectedItem: regions.firstWhere(
              (r) => r.code == selectedRegion,
              orElse: () => Region(code: '', regionName: 'Select Region'),
            ),
            onChanged: (Region? newValue) {
              setState(() {
                selectedRegion = newValue?.code;
                eregionController.text = newValue!.regionName;
                fetchProvinces(selectedRegion!, setState);
                provinces.clear();
                cities.clear();
                barangays.clear();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProvinceDropdown(StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Province',
            style: TextStyle(
                fontSize: 13,
                color: Color(0xff13322b),
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        SizedBox(
          height: 48,
          child: CustomDropdown<Province>(
            items: provinces,
            itemAsString: (p) => p.name,
            hintText: 'Select Province',
            selectedItem: provinces.firstWhere(
              (p) => p.code == selectedProvince,
              orElse: () => Province(code: '', name: 'Select Province'),
            ),
            onChanged: (Province? newValue) {
              setState(() {
                selectedProvince = newValue?.code;
                provinceController.text = newValue!.name;
                fetchCities(selectedProvince!, setState);
                cities.clear();
                barangays.clear();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCityDropdown(StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('City',
            style: TextStyle(
                fontSize: 13,
                color: Color(0xff13322b),
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        SizedBox(
          height: 48,
          child: CustomDropdown<City>(
            items: cities,
            itemAsString: (c) => c.name,
            hintText: 'Select City',
            selectedItem: cities.firstWhere(
              (c) => c.code == selectedCity,
              orElse: () => City(code: '', name: 'Select City'),
            ),
            onChanged: (City? newValue) {
              setState(() {
                selectedCity = newValue?.code;
                cityController.text = newValue!.name;
                fetchBarangays(selectedCity!, setState);
                barangays.clear();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBarangayDropdown(StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Barangay',
            style: TextStyle(
                fontSize: 13,
                color: Color(0xff13322b),
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        SizedBox(
          height: 48,
          child: CustomDropdown<Barangay>(
            items: barangays,
            itemAsString: (b) => b.name,
            hintText: 'Select Barangay',
            selectedItem: barangays.firstWhere(
              (b) => b.code == selectedBarangay,
              orElse: () =>
                  Barangay(code: '', name: 'Select Barangay', postal: ''),
            ),
            onChanged: (Barangay? newValue) {
              setState(() {
                selectedBarangay = newValue?.code;
                barangayController.text = newValue!.name;
                postalCodeController.text = newValue.postal;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStep2PlanCard(BuildContext ctx, StateSetter setState) {
    return Form(
      key: _formKey2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Plan Details'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildStatusDropdown(
                  label: 'Member Type',
                  items: memberTypeItems,
                  controller: memberTypeController,
                  setState: setState,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatusDropdown(
                  label: 'Enrollment Type',
                  items: enrollmentTypeItems,
                  controller: enrollmentTypeController,
                  setState: setState,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatusDropdown(
                  label: 'Plan Type',
                  items: _localPlanTypeItems,
                  controller: planTypeController,
                  setState: setState,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildStatusDropdown(
                  label: 'Room & Board Type',
                  items: roomBoardTypeItems,
                  controller: roomAndBoardTypeController,
                  setState: setState,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextFormField(
                  label: const Row(children: [
                    Text('Room & Board Limit',
                        style: TextStyle(color: Colors.black)),
                    Text(' *', style: TextStyle(color: Colors.red)),
                  ]),
                  labelStyle: const TextStyle(
                      color: Color(0xff13322b), fontSize: 13),
                  controller: roomAndBoardLimitController,
                  isNumeric: true,
                  maxLength: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildStatusDropdown(
                  label: 'Benefit Limit Type',
                  items: benefitTypeItems,
                  controller: benefitLimitTypeController,
                  setState: setState,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextFormField(
                  label: const Row(children: [
                    Text('Benefit Limit',
                        style: TextStyle(color: Colors.black)),
                    Text(' *', style: TextStyle(color: Colors.red)),
                  ]),
                  labelStyle: const TextStyle(
                      color: Color(0xff13322b), fontSize: 13),
                  controller: benefitLimitController,
                  isNumeric: true,
                  maxLength: 6,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              const Expanded(
                child: Text('Card Details',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff13322b),
                        letterSpacing: 0.2)),
              ),
              TextButton.icon(
                onPressed: () async {
                  final updated =
                      await _showPlanTypeManagerDialog(ctx);
                  if (updated) setState(() {});
                },
                icon: const Icon(Icons.tune,
                    size: 14, color: Color(0xff13322b)),
                label: const Text('Manage Plans',
                    style: TextStyle(
                        color: Color(0xff13322b), fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Card Type *',
                        style: TextStyle(
                            fontSize: 13,
                            color: Color(0xff13322b),
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      value: _selectedCardVariantId,
                      dropdownColor: Colors.white,
                      iconEnabledColor: const Color(0xff13322b),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: const BorderSide(
                              color: Color(0xff13322b), width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: BorderSide(
                              color: const Color(0xff13322b).withOpacity(0.35),
                              width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: const BorderSide(
                              color: Color(0xff13322b), width: 2.0),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      hint: const Text('Select Card Type',
                          style: TextStyle(
                              color: Color(0xffBDC9CA), fontSize: 13)),
                      items: _cardVariants.map((variant) {
                        return DropdownMenuItem<int>(
                          value: variant['card_variant_id'],
                          child: Text(
                            variant['card_name'] ??
                                variant['card_variant'] ??
                                '',
                            style: const TextStyle(
                                color: Color(0xff13322b), fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCardVariantId = value;
                          final selected = _cardVariants.firstWhere(
                            (v) => v['card_variant_id'] == value,
                            orElse: () => {},
                          );
                          cardTypeController.text =
                              selected['card_name'] ?? '';
                        });
                      },
                      validator: (value) => null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextFormField(
                  label: const Row(children: [
                    Text('Card Number',
                        style: TextStyle(color: Colors.black)),
                    Text(' *', style: TextStyle(color: Colors.red)),
                  ]),
                  labelStyle: const TextStyle(
                      color: Color(0xff13322b), fontSize: 13),
                  controller: cardNumberController,
                  isNumeric: true,
                  maxLength: 16,
                  validator: (value) {
                    if (value == null || value.length != 16) {
                      return 'Card number must be 16 digits';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildDatePickerField(
                  label: 'Effective Date',
                  controller: ecardEffectiveController,
                  setState: setState,
                  initialDate: DateTime.now(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDatePickerField(
                  label: 'Expiry Date',
                  controller: ecardExpiryController,
                  setState: setState,
                  initialDate: DateTime.now().add(const Duration(days: 365)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required TextEditingController controller,
    required StateSetter setState,
    required DateTime initialDate,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                color: Color(0xff13322b),
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: controller.text.isNotEmpty
                  ? (DateTime.tryParse(controller.text) ?? initialDate)
                  : initialDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2040),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                        primary: Color(0xff13322b)),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() {
                controller.text = picked.toIso8601String().split('T')[0];
              });
            }
          },
          child: AbsorbPointer(
            child: TextFormField(
              controller: controller,
              readOnly: true,
              style: const TextStyle(
                  color: Color(0xff13322b), fontSize: 13),
              decoration: InputDecoration(
                hintText: 'yyyy-mm-dd',
                hintStyle: TextStyle(
                    color: const Color(0xff13322b).withOpacity(0.4),
                    fontSize: 13),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide(
                      color: const Color(0xff13322b).withOpacity(0.35),
                      width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide(
                      color: const Color(0xff13322b).withOpacity(0.35),
                      width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: const BorderSide(
                      color: Color(0xff13322b), width: 2.0),
                ),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: const Icon(Icons.calendar_today,
                    size: 16, color: Color(0xff13322b)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown({
    required String label,
    required List<StatusItem> items,
    required TextEditingController controller,
    required StateSetter setState,
  }) {
    int? selectedId = int.tryParse(controller.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                color: Color(0xff13322b),
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          value: selectedId,
          dropdownColor: Colors.white,
          iconEnabledColor: const Color(0xff13322b),
          isExpanded: true,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: const BorderSide(
                  color: Color(0xff13322b), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: BorderSide(
                  color: const Color(0xff13322b).withOpacity(0.35),
                  width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: const BorderSide(
                  color: Color(0xff13322b), width: 2.0),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          hint: Text('Select $label',
              style: TextStyle(
                  color: const Color(0xff13322b).withOpacity(0.4),
                  fontSize: 13)),
          items: items.map((item) {
            return DropdownMenuItem<int>(
              value: item.id,
              child: Text(
                item.status,
                style: const TextStyle(
                    color: Color(0xff13322b), fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              controller.text = value?.toString() ?? '';
            });
          },
          validator: (value) => null,
        ),
      ],
    );
  }

  Widget _buildStep3Confirm(BuildContext ctx, StateSetter setState) {
    if (isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: SpinKitCircle(
            color: Color(0xff13322B),
            size: 50.0,
          ),
        ),
      );
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConfirmSection('Name & Contact', 0, setState, [
            _confirmRow('First Name',
                fnameController.text.isEmpty ? '-' : fnameController.text),
            _confirmRow('Middle Name',
                mnameController.text.isEmpty ? '-' : mnameController.text),
            _confirmRow('Last Name',
                lnameController.text.isEmpty ? '-' : lnameController.text),
            _confirmRow('Contact No',
                contactNoController.text.isEmpty ? '-' : contactNoController.text),
            _confirmRow('Email',
                emailController.text.isEmpty ? '-' : emailController.text),
          ]),
          const SizedBox(height: 12),
          _buildConfirmSection('Personal & Address', 1, setState, [
            _confirmRow('Sex', _selectedSex ?? '-'),
            _confirmRow('Birthday',
                _birthday != null ? "${_birthday?.toLocal()}".split(' ')[0] : '-'),
            _confirmRow('Civil Status',
                civilStatusController.text.isEmpty ? '-' : civilStatusController.text),
            _confirmRow('House Address',
                houseAddressController.text.isEmpty ? '-' : houseAddressController.text),
            _confirmRow('Region',
                regionController.text.isEmpty ? '-' : regionController.text),
            _confirmRow('Province',
                provinceController.text.isEmpty ? '-' : provinceController.text),
            _confirmRow('City',
                cityController.text.isEmpty ? '-' : cityController.text),
            _confirmRow('Barangay',
                barangayController.text.isEmpty ? '-' : barangayController.text),
            _confirmRow('Postal Code',
                postalCodeController.text.isEmpty ? '-' : postalCodeController.text),
          ]),
          const SizedBox(height: 12),
          _buildConfirmSection('Plan & Card', 2, setState, [
            _confirmRow('Member Type',
                memberTypeController.text.isEmpty ? '-' : memberTypeController.text),
            _confirmRow('Enrollment Type',
                enrollmentTypeController.text.isEmpty ? '-' : enrollmentTypeController.text),
            _confirmRow('Plan Type',
                planTypeController.text.isEmpty ? '-' : planTypeController.text),
            _confirmRow('Room & Board Limit',
                roomAndBoardLimitController.text.isEmpty ? '-' : roomAndBoardLimitController.text),
            _confirmRow('Benefit Limit',
                benefitLimitController.text.isEmpty ? '-' : benefitLimitController.text),
            _confirmRow('Card Type',
                _selectedCardVariantId != null
                    ? (_cardVariants.firstWhere(
                            (v) => v['card_variant_id'] == _selectedCardVariantId,
                            orElse: () => {})['card_name'] ??
                        '-')
                    : '-'),
            _confirmRow('Card Number',
                cardNumberController.text.isEmpty ? '-' : cardNumberController.text),
            _confirmRow('Effective Date',
                ecardEffectiveController.text.isEmpty ? '-' : ecardEffectiveController.text),
            _confirmRow('Expiry Date',
                ecardExpiryController.text.isEmpty ? '-' : ecardExpiryController.text),
          ]),
        ],
      ),
    );
  }

  Widget _buildDialogFooter(BuildContext ctx, StateSetter setState) {
    final isLast = _addMemberStep == 2;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xffE8ECEF), width: 1),
        ),
      ),
      child: Row(
        children: [
          if (_addMemberStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _addMemberStep--),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                      color: Color(0xff13322b), width: 1.2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Back',
                    style: TextStyle(
                        color: Color(0xff13322b),
                        fontWeight: FontWeight.w600)),
              ),
            ),
          if (_addMemberStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () {
                      if (!isLast) {
                        if (!_validateCurrentStep(setState)) return;
                        setState(() => _addMemberStep++);
                      } else {
                        if (!_formKey.currentState!.validate()) return;
                        if (!_formKey2.currentState!.validate()) return;
                        addMember(setState);
                        setState(() => isLoading = true);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff13322b),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      isLast ? 'Submit' : 'Continue',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  bool _validateCurrentStep(StateSetter setState) {
    if (_addMemberStep == 0) {
      if (!_formKey.currentState!.validate()) return false;
      if (_selectedSex == null) {
        setState(() => noSex = true);
        return false;
      }
      if (_birthday == null) {
        setState(() {
          isDateError = true;
          dateLabel = 'Birthday is required';
        });
        return false;
      }
      final age = calculateAge(_birthday.toString());
      if (age < 16) {
        setState(() {
          isDateError = true;
          noSex = false;
          _birthday = null;
          dateLabel = 'Invalid date; age must be 16 or older.';
        });
        return false;
      }
      return true;
    } else if (_addMemberStep == 1) {
      if (!_formKey2.currentState!.validate()) return false;
      if (roomAndBoardLimitController.text.isEmpty ||
          benefitLimitController.text.isEmpty ||
          cardNumberController.text.length != 16) {
        return false;
      }
      return true;
    }
    return true;
  }

  void _showDialog(BuildContext context, StateSetter setState) {
    _addMemberStep = 0;

    void _resetForm(StateSetter dialogSetState) {
      dialogSetState(() {
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
        benefitLimitController.text = '';
        roomAndBoardLimitController.text = '';
        _selectedFiles = [];
        _birthday = null;
        _isFormValid = true;
        provinces.clear();
        cities.clear();
        barangays.clear();
        selectedRegion = null;
        selectedProvince = null;
        selectedCity = null;
        selectedBarangay = null;
        _selectedSex = null;
        noSex = false;
        isDateError = false;
        dateLabel = 'yyyy-mm-dd';
        _addMemberStep = 0;
        _selectedCardVariantId = null;
        memberTypeController.text = '1';
        enrollmentTypeController.text = '1';
        planTypeController.text = _defaultPlanTypeId().toString();
        roomAndBoardTypeController.text = '2';
        benefitLimitTypeController.text = '1';
        cardTypeController.text = _cardLabelForPlanType(
            int.tryParse(planTypeController.text) ?? _defaultPlanTypeId());
      });
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        selectedType = 1;
        return StatefulBuilder(
          builder: (BuildContext dialogContext, StateSetter dialogSetState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: MediaQuery.of(dialogContext).size.width * 0.9 > 900
                    ? 900
                    : MediaQuery.of(dialogContext).size.width * 0.9,
                height: 820,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Add Member",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff13322b),
                            ),
                          ),
                          Row(
                            children: [
                              SizedBox(
                                width: 160,
                                height: 40,
                                child: ElevatedButton(
                                  onPressed: () {
                                    _pickFiles(dialogSetState);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    backgroundColor: const Color(0xff13322b),
                                  ),
                                  child: const Text(
                                    'Bulk Upload',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: IconButton(
                                  onPressed: () {
                                    _resetForm(dialogSetState);
                                    Navigator.pop(dialogContext);
                                  },
                                  icon: const Icon(Icons.close,
                                      color: Color(0xff13322b)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Custom pill-style stepper header (replaces the default Stepper header)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildPillStepperHeader(dialogSetState),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: _buildStepContent(dialogContext, dialogSetState),
                      ),
                    ),
                    _buildDialogFooter(dialogContext, dialogSetState),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildConfirmSection(String title, int step,
      StateSetter dialogSetState, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffF7F9FB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffBDC9CA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xff13322b))),
              TextButton.icon(
                onPressed: () {
                  dialogSetState(() => _addMemberStep = step);
                },
                icon: const Icon(Icons.edit, size: 14, color: Color(0xff13322b)),
                label: const Text('Edit',
                    style: TextStyle(color: Color(0xff13322b), fontSize: 12)),
              ),
            ],
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _confirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: Color(0xff757575))),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff13322b))),
        ],
      ),
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
                  isLoading = false;
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
