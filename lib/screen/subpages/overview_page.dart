import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:medicare_admin_remaster/bloc/auth/auth_bloc.dart';
import 'package:medicare_admin_remaster/screen/login_page.dart';
import 'package:medicare_admin_remaster/shared/api.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  bool _isLoading = true;
  String? _error;
  Timer? _timer;

  int _totalMembers = 0;
  int _activeMembers = 0;
  int _inactiveMembers = 0;
  int _pendingLOAs = 0;
  int _approvedLOAs = 0;
  int _rejectedLOAs = 0;
  int _cancelledLOAs = 0;
  int _totalAdmins = 0;
  int _totalDoctors = 0;
  List<Map<String, dynamic>> _recentLOAs = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardStats();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchDashboardStats();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse(adminEndpoint('dashboard_stats')),
        headers: buildApiHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _totalMembers = data['totalMembers'] ?? 0;
            _activeMembers = data['activeMembers'] ?? 0;
            _inactiveMembers = data['inactiveMembers'] ?? 0;
            _pendingLOAs = data['pendingLOAs'] ?? 0;
            _approvedLOAs = data['approvedLOAs'] ?? 0;
            _rejectedLOAs = data['rejectedLOAs'] ?? 0;
            _cancelledLOAs = data['cancelledLOAs'] ?? 0;
            _totalAdmins = data['totalAdmins'] ?? 0;
            _totalDoctors = data['totalDoctors'] ?? 0;
            _recentLOAs = List<Map<String, dynamic>>.from(data['recentLOAs'] ?? []);
            _isLoading = false;
            _error = null;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Failed to load dashboard data';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'approved':
        return const Color(0xff66cce9);
      case 'pending':
        return const Color(0xfffec316);
      case 'rejected':
        return const Color(0xfff0516e);
      case 'cancelled':
        return const Color(0xffD8DEE1);
      default:
        return const Color(0xffD8DEE1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
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
                    'Overview',
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
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        },
        builder: (context, authState) {
          if (authState is AuthLoading) {
            return const Center(
              child: SpinKitCircle(color: Color(0xff13322B), size: 50.0),
            );
          }

          if (authState is! AuthSuccess) {
            return Container();
          }

          if (_isLoading) {
            return const Center(
              child: SpinKitCircle(color: Color(0xff13322B), size: 50.0),
            );
          }

          if (_error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _isLoading = true);
                      _fetchDashboardStats();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff13322B)),
                    child: const Text('Retry', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Members Row ──
                _buildSectionTitle('Members'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatCard(
                      label: 'TOTAL MEMBERS',
                      value: _totalMembers,
                      color: const Color(0xff13322B),
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      label: 'ACTIVE',
                      value: _activeMembers,
                      color: const Color(0xff66cce9),
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      label: 'INACTIVE',
                      value: _inactiveMembers,
                      color: const Color(0xffD8DEE1),
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      label: 'TOTAL ADMINS',
                      value: _totalAdmins,
                      color: const Color(0xff13322B),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ── LOA Requests Row ──
                _buildSectionTitle('LOA Requests'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatCard(
                      label: 'PENDING',
                      value: _pendingLOAs,
                      color: const Color(0xfffec316),
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      label: 'APPROVED',
                      value: _approvedLOAs,
                      color: const Color(0xff66cce9),
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      label: 'REJECTED',
                      value: _rejectedLOAs,
                      color: const Color(0xfff0516e),
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      label: 'CANCELLED',
                      value: _cancelledLOAs,
                      color: const Color(0xffD8DEE1),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ── Quick Stats Row ──
                _buildSectionTitle('Quick Stats'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildQuickStatTile(
                      icon: Icons.medical_services_outlined,
                      label: 'Total Doctors',
                      value: '$_totalDoctors',
                    ),
                    const SizedBox(width: 16),
                    _buildQuickStatTile(
                      icon: Icons.shield_outlined,
                      label: 'System Status',
                      value: 'Operational',
                      valueColor: const Color(0xff13322B),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ── Recent LOA Activity ──
                _buildSectionTitle('Recent LOA Activity'),
                const SizedBox(height: 12),
                _buildRecentLoaTable(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontFamily: "Roboto-M",
        color: Color(0xff222222),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required int value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 32,
                  fontFamily: "Roboto-M",
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: "Roboto-M",
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatTile({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = const Color(0xff222222),
  }) {
    return Expanded(
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: const Color(0xff13322B)),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: "Roboto-L",
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontFamily: "Roboto-M",
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentLoaTable() {
    if (_recentLOAs.isEmpty) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'No recent LOA requests',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xff13322B),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(width: 120, child: _HeaderText('Request ID')),
                  SizedBox(width: 200, child: _HeaderText('Patient Name')),
                  SizedBox(width: 180, child: _HeaderText('Type')),
                  SizedBox(width: 120, child: _HeaderText('Status')),
                  SizedBox(width: 120, child: _HeaderText('Date')),
              ],
            ),
          ),
          // Rows
          ...List.generate(_recentLOAs.length, (index) {
            final loa = _recentLOAs[index];
            final isLast = index == _recentLOAs.length - 1;
            final status = (loa['form_status'] ?? '').toString();
            final customer = loa['mp_customers_info_table'];
            final firstName = (customer is Map) ? (customer['first_name'] ?? '').toString() : '';
            final lastName = (customer is Map) ? (customer['last_name'] ?? '').toString() : '';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: index.isEven ? Colors.grey.shade50 : Colors.white,
                border: isLast
                    ? null
                    : Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      '${loa['request_id'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 13, fontFamily: "Roboto-R", color: Color(0xff222222)),
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: Text(
                      '$firstName $lastName',
                      style: const TextStyle(fontSize: 13, fontFamily: "Roboto-R", color: Color(0xff222222)),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: Text(
                      '${loa['mp_form_type_table']?['form_type'] ?? loa['form_type_id'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 13, fontFamily: "Roboto-R", color: Color(0xff222222)),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: "Roboto-M",
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: Text(
                      _formatDate(loa['date_created']?.toString()),
                      style: const TextStyle(fontSize: 13, fontFamily: "Roboto-R", color: Color(0xff222222)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  final String text;
  const _HeaderText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontFamily: "Roboto-M",
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}
