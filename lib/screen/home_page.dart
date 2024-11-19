import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:medicare_admin_remaster/bloc/auth/auth_bloc.dart';
import 'package:medicare_admin_remaster/screen/login_page.dart';
import 'package:medicare_admin_remaster/screen/subpages/admin_page.dart';
//import 'package:medicare_admin_remaster/screen/subpages/data_analytics_page.dart';
import 'package:medicare_admin_remaster/screen/subpages/doctor_management_page.dart';
import 'package:medicare_admin_remaster/screen/subpages/health_card_page.dart';
import 'package:medicare_admin_remaster/screen/subpages/loa_request_page.dart';
import 'package:medicare_admin_remaster/screen/subpages/overview_page.dart';
import 'package:medicare_admin_remaster/screen/subpages/pnp_page.dart';
import 'package:medicare_admin_remaster/screen/subpages/user_management_page.dart';
import 'package:medicare_admin_remaster/shared/api.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Widget currentPage = const OverviewPage(); // Default page
  int selectedCardIndex = -1; // Track selected card index
  List<bool> isHovered = List.generate(7, (_) => false);
  int pendingCount = 0; // To hold the pending count
  bool isLoading = true; // To manage loading state
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    fetchPendingCount('pending'); // Fetch pending count on init
    // Start a timer to refresh the pending count every 30 seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      fetchPendingCount('pending');
    });
  }

  Future<void> fetchPendingCount(String status) async {
    try {
      final response = await http.post(
        Uri.parse('https://medicareplus-api.vercel.app/api/admin/count_status'),
        headers: {
          'Content-Type': 'application/json',
          'supabase-url': supabaseUrl, // Add Supabase URL
          'supabase-key': supabaseKey,
        },
        body: json.encode({
          'status': status,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          pendingCount = data['count'] ?? 0; // Update pending count
          status = data['status'] ?? status; // Update status
          isLoading = false; // Loading complete
        });
      } else {
        throw Exception('Failed to load status count');
      }
    } catch (e) {
      print('Error: $e'); // Log the error for debugging
      setState(() {
        isLoading = false; // Loading complete even if there's an error
      });
    }
  }
/*
  void changePage(int pageIndex) {
    setState(() {
      selectedCardIndex = pageIndex; // Update selected index
      switch (pageIndex) {
        case 0:
          currentPage = const OverviewPage();
          break;
        // case 1:
        //   currentPage = const DataAnalyticsPage();
        //   break;
        case 1:
          currentPage = const HealthCardPage();
          break;
        case 2:
          currentPage = const LoaRequestPage();
          break;
        case 3:
          currentPage = const UserManagementPage();
          break;
        case 4:
          currentPage = const PnpPage();
          break;
        case 5:
          currentPage = const DoctorManagementPage();
          break;
        case 6:
          currentPage = const AdminPage();
          break;
      }
    });
  }*/

  void changePage(int pageIndex, String adminType) {
  setState(() {
    selectedCardIndex = pageIndex; // Update selected index

    // Restrict page navigation based on adminType
    if (adminType == 'upd') {
      // UPD can only access Overview, Health Card, and Customer (indices 0, 1, 2)
      if (pageIndex == 0) {
        currentPage = const OverviewPage();
      } else if (pageIndex == 1) {
        currentPage = const UserManagementPage();
      } else {
        // Prevent navigation to restricted pages for UPD admin
        return;
      }
    } else if (adminType == 'claims' || adminType == 'concierge') {
      // Claims can access all except Admin (index 6)
      if (pageIndex == 0) {
        currentPage = const OverviewPage();
      } else if (pageIndex == 1) {
        currentPage = const HealthCardPage();
      } else if (pageIndex == 2) {
        currentPage = const LoaRequestPage();
      } else if (pageIndex == 3) {
        currentPage = const UserManagementPage();
      } else if (pageIndex == 4) {
        currentPage = const PnpPage();
      } else if (pageIndex == 5) {
        currentPage = const DoctorManagementPage();
      } else {
        // Prevent navigation to Admin page for Claims admin
        return;
      }
    } else {
      // For other admins, allow all pages
      switch (pageIndex) {
        case 0:
          currentPage = const OverviewPage();
          break;
        case 1:
          currentPage = const HealthCardPage();
          break;
        case 2:
          currentPage = const LoaRequestPage();
          break;
        case 3:
          currentPage = const UserManagementPage();
          break;
        case 4:
          currentPage = const PnpPage();
          break;
        case 5:
          currentPage = const DoctorManagementPage();
          break;
        case 6:
          currentPage = const AdminPage();
          break;
      }
    }
  });
}


  int getCardListLength(String adminType) {
    if (adminType == 'upd') {
      return 2;  // 'UPD' admin can see 3 cards
    } else if (adminType == 'claims' || adminType == 'concierge') {
      return 6;  // 'Claims' admin can see 6 cards
    } else {
      return 7;  // Default case, other admin types can see all 7 cards
    }
  }


  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
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
              child: CircularProgressIndicator(
                color: Colors.red,
              ),
            );
          } else if (authState is AuthSuccess) {
            return Row(children: [
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 5),
                child: SizedBox(
                  width: width * .18,
                  child: Column(
                    children: [
                      // Image and dashboard title
                      Expanded(
                        flex: 10,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.white),
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/Medicare.png',
                              height: 200,
                            ),
                          ),
                        ),
                      ),
                      // Dashboard title
                      Expanded(
                        flex: 5,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.white),
                          ),
                          child: const Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.only(left: 16.0),
                              child: Text(
                                'DASHBOARD',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: "Roboto-L",
                                  color: Color(0XFF13322B),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Cards
                      Expanded(
                        flex: 70,
                        child: Column(
                          children: List.generate(getCardListLength(authState.adminType.toString()), (index) {
                            List<String> cardTitles;
                            if (authState.adminType.toString() == 'upd') {
                              // UPD admin type can only see these titles
                              cardTitles = [
                                'Overview',
                                'Customer',
                              ];
                            } else if (authState.adminType.toString() == 'claims') {
                              // Claims admin type can see everything except Admin
                              cardTitles = [
                                'Overview',
                                'Health Card',
                                'LOA Requests ${isLoading ? '' : '($pendingCount)'}',
                                'Customer',
                                'PNP',
                                'Doctor',
                              ];
                            } else {
                              // Other admins have access to all titles
                              cardTitles = [
                                'Overview',
                                'Health Card',
                                'LOA Requests ${isLoading ? '' : '($pendingCount)'}',
                                'Customer',
                                'PNP',
                                'Doctor',
                                'Admin',
                              ];
                            }

                            return MouseRegion(
                              onEnter: (_) {
                                setState(() {
                                  isHovered[index] = true;
                                });
                              },
                              onExit: (_) {
                                setState(() {
                                  isHovered[index] = false;
                                });
                              },
                              child: GestureDetector(
                                onTap: () => changePage(index,authState.adminType.toString()),
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Stack(
                                    children: [
                                      Container(
                                        height: 80,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: selectedCardIndex == index
                                                ? const Color(0xFF13322B)
                                                : (isHovered[index]
                                                    ? Colors.grey
                                                    : Colors.transparent),
                                            width: 1.0,
                                          ),
                                        ),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            cardTitles[index],
                                            style: const TextStyle(
                                              color: Color(0XFF13322B),
                                              fontSize: 20,
                                              fontFamily: "Roboto-M",
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Vertical line on the right edge of the card
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 40,
                                          decoration: BoxDecoration(
                                            color: (selectedCardIndex == index)
                                                ? const Color(0xFF13322B)
                                                : (isHovered[index]
                                                    ? Colors.grey
                                                    : Colors.transparent),
                                            borderRadius:
                                                const BorderRadius.only(
                                              topRight: Radius.circular(10),
                                              bottomRight: Radius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      // Logout button
                      Container(
                        height: height * .05,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.white),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: SizedBox(
                            height: 40,
                            width: 300,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff13322B),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () async {
                                bool? confirmLogout = await showDialog<bool>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                          backgroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20.0),
                                              side: const BorderSide(color: Color(0xff13322b), width: 2)),
                                          title: const Center(
                                              child: Text(
                                            'Confirm Logout',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xff13322b)),
                                          )),
                                          content: const Text('Are you sure you want to logout?',
                                              style: TextStyle(fontSize: 16, color: Color(0xff13322b))),
                                          actions: <Widget>[
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                SizedBox(
                                              width:
                                                  100, // Same width for the Select Files button
                                              height:
                                                  35, // Same height for the Select Files button
                                              child: ElevatedButton(
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(false),
                                                style: ElevatedButton.styleFrom(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5),
                                                    side: const BorderSide(
                                                        color: Color(
                                                            0xff13322b)), // Set the border color
                                                  ),
                                                  backgroundColor: Colors
                                                      .white, // Set button background color to white
                                                ),
                                                child: const Text(
                                                  'Cancel',
                                                  style: TextStyle(
                                                      color: Colors
                                                          .black), // Set button text color to black for visibility
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            SizedBox(
                                              width:
                                                  100, // Same width for the Select Files button
                                              height:
                                                  35, // Same height for the Select Files button
                                              child: ElevatedButton(
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(true),
                                                style: ElevatedButton.styleFrom(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5),
                                                    side: const BorderSide(
                                                        color: Color(
                                                            0xff13322b)), // Set the border color
                                                  ),
                                                  backgroundColor: const Color(
                                                      0xff13322b), // Set button background color to white
                                                ),
                                                child: const Text(
                                                  'Logout',
                                                  style: TextStyle(
                                                      color: Color(
                                                          0xffffffff)), // Set button text color to black for visibility
                                                ),
                                              ),
                                            ),
                                              ],
                                            ),
                                        
                                          ],
                                        );
                                  
                                  },
                                );

                                if (confirmLogout == true) {
                                  context
                                      .read<AuthBloc>()
                                      .add(AuthLogoutRequested());
                                }
                              },
                              child: const Text('Logout',
                                  style: TextStyle(
                                      fontSize: 14, color: Color(0xFFFFFFFF))),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Right side content
              Expanded(
                flex: 6,
                child: currentPage,
              ),
            ]);
          }
          return Container(); // Fallback if no auth state is found
        },
      ),
    );
  }
}
