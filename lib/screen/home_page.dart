import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:medicare_admin_remaster/bloc/auth/auth_bloc.dart';
import 'package:medicare_admin_remaster/screen/login_page.dart';
import 'package:medicare_admin_remaster/screen/subpages/admin_page.dart';
import 'package:medicare_admin_remaster/screen/subpages/doctor_management_page.dart';
import 'package:medicare_admin_remaster/screen/subpages/health_card_page.dart';
import 'package:medicare_admin_remaster/screen/subpages/loa_request_page.dart';
import 'package:medicare_admin_remaster/screen/subpages/overview_page.dart';
import 'package:medicare_admin_remaster/screen/subpages/pnp_page.dart';
import 'package:medicare_admin_remaster/screen/subpages/user_management_page.dart';
import 'package:medicare_admin_remaster/services/cache_service.dart';
import 'package:medicare_admin_remaster/shared/api.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedCardIndex = 0;
  int _currentPageIndex = 0;
  int _pendingCount = 0;
  bool _isLoading = true;
  Timer? _timer;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = const [
      OverviewPage(),
      HealthCardPage(),
      LoaRequestPage(),
      UserManagementPage(),
      PnpPage(),
      DoctorManagementPage(),
      AdminPage(),
    ];

    CacheService.instance.initLoaRequests();
    CacheService.instance.initMembers();

    _fetchPendingCount('pending');
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchPendingCount('pending');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchPendingCount(String status) async {
    try {
      final response = await http.post(
        Uri.parse(adminEndpoint('count_status')),
        headers: buildApiHeaders(),
        body: json.encode({'status': status}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _pendingCount = data['count'] ?? 0;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _changePage(int pageIndex, String adminType) {
    if (pageIndex == _currentPageIndex) return;

    if (adminType == 'upd') {
      if (pageIndex == 0) {
        setState(() {
          _currentPageIndex = 0;
          _selectedCardIndex = 0;
        });
      } else if (pageIndex == 1) {
        setState(() {
          _currentPageIndex = 3;
          _selectedCardIndex = 1;
        });
      }
    } else if (adminType == 'claims' || adminType == 'concierge') {
      if (pageIndex == 6) return;
      setState(() {
        _currentPageIndex = pageIndex;
        _selectedCardIndex = pageIndex;
      });
    } else {
      setState(() {
        _currentPageIndex = pageIndex;
        _selectedCardIndex = pageIndex;
      });
    }
  }

  int _getCardListLength(String adminType) {
    if (adminType == 'upd') return 2;
    if (adminType == 'claims' || adminType == 'concierge') return 6;
    return 7;
  }

  List<String> _getCardTitles(String adminType) {
    if (adminType == 'upd') {
      return ['Overview', 'Members'];
    } else if (adminType == 'claims') {
      return [
        'Overview',
        'Health Card',
        'LOA Requests',
        'Members',
        'PNP',
        'Doctor',
      ];
    } else {
      return [
        'Overview',
        'Health Card',
        'LOA Requests',
        'Members',
        'Analytics',
        'Doctor',
        'Admin',
      ];
    }
  }

  List<IconData> _getCardIcons(String adminType) {
    if (adminType == 'upd') {
      return [Icons.dashboard_outlined, Icons.people_outline];
    } else if (adminType == 'claims') {
      return [
        Icons.dashboard_outlined,
        Icons.credit_card_outlined,
        Icons.description_outlined,
        Icons.people_outline,
        Icons.local_hospital_outlined,
        Icons.person_outline,
      ];
    } else {
      return [
        Icons.dashboard_outlined,
        Icons.credit_card_outlined,
        Icons.description_outlined,
        Icons.people_outline,
        Icons.analytics_outlined,
        Icons.person_outline,
        Icons.admin_panel_settings_outlined,
      ];
    }
  }

  int _sidebarIndexToPage(int sidebarIndex, String adminType) {
    if (adminType == 'upd') {
      return sidebarIndex == 0 ? 0 : 3;
    }
    return sidebarIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthInitial) {
            CacheService.instance.reset();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        },
        builder: (context, authState) {
          if (authState is AuthLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00455D)),
            );
          } else if (authState is AuthSuccess) {
            final adminType = authState.adminType.toString();
            final cardTitles = _getCardTitles(adminType);
            final cardCount = _getCardListLength(adminType);
            final cardIcons = _getCardIcons(adminType);

            return Row(
              children: [
                // Sidebar
                Container(
                  width: 260,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      right: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Logo Section
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset(
                              'assets/Medicare.png',
                              height: 36,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'ADMIN PORTAL',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF00455D),
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Section Label
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'DASHBOARD',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF70787E),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Navigation Items
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: cardCount,
                          itemBuilder: (context, index) {
                            final isSelected = _selectedCardIndex == index;
                            return _buildNavItem(
                              title: cardTitles[index],
                              icon: cardIcons[index],
                              isSelected: isSelected,
                              onTap: () => _changePage(index, adminType),
                              badge: index == 2 && !_isLoading && _pendingCount > 0
                                  ? _pendingCount.toString()
                                  : null,
                            );
                          },
                        ),
                      ),

                      // Bottom Section: Help + Logout
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            _buildNavItem(
                              title: 'Help',
                              icon: Icons.help_outline,
                              isSelected: false,
                              onTap: () {},
                            ),
                            const SizedBox(height: 4),
                            _buildNavItem(
                              title: 'Logout',
                              icon: Icons.logout,
                              isSelected: false,
                              isDestructive: true,
                              onTap: () => _handleLogout(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Content
                Expanded(
                  child: IndexedStack(
                    index: _currentPageIndex,
                    children: _pages,
                  ),
                ),
              ],
            );
          }
          return Container();
        },
      ),
    );
  }

  Widget _buildNavItem({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    String? badge,
    bool isDestructive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFE8F5F0)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: const Color(0xFF00455D).withOpacity(0.15), width: 1)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isDestructive
                      ? Colors.red.shade400
                      : isSelected
                          ? const Color(0xFF00455D)
                          : const Color(0xFF70787E),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isDestructive
                          ? Colors.red.shade400
                          : isSelected
                              ? const Color(0xFF00455D)
                              : const Color(0xFF40484D),
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Confirm Logout',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0B1C30))),
        content: const Text('Are you sure you want to logout?',
            style: TextStyle(fontSize: 14, color: Color(0xFF40484D))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF70787E))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      context.read<AuthBloc>().add(AuthLogoutRequested());
    }
  }
}
