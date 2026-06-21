import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:medicare_admin_remaster/shared/api.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class CacheService {
  CacheService._();
  static final CacheService instance = CacheService._();

  bool _loaInitialized = false;
  bool _membersInitialized = false;

  List<Map<String, dynamic>> _loaRequests = [];
  List<Map<String, dynamic>> _members = [];

  final _loaController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final _membersController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  supabase.RealtimeChannel? _loaChannel;
  supabase.RealtimeChannel? _membersChannel;

  Stream<List<Map<String, dynamic>>> get loaRequestsStream =>
      _loaController.stream;
  Stream<List<Map<String, dynamic>>> get membersStream =>
      _membersController.stream;

  List<Map<String, dynamic>> get currentLoaRequests =>
      List.unmodifiable(_loaRequests);
  List<Map<String, dynamic>> get currentMembers =>
      List.unmodifiable(_members);

  // ── LOA Requests ──────────────────────────────────────────────────────

  Future<void> initLoaRequests() async {
    if (_loaInitialized) return;
    _loaInitialized = true;

    await _fetchLoaRequests();
    if (useSupabase) _subscribeLoaRealtime();
  }

  Future<void> _fetchLoaRequests() async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/admin/get_loa_request'),
        headers: buildApiHeaders(includeContentType: false),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _loaRequests =
            List<Map<String, dynamic>>.from(data['loa_request'] ?? []);
        _loaController.add(_loaRequests);
      }
    } catch (e) {
      print('CacheService: Error fetching LOA requests: $e');
    }
  }

  void _subscribeLoaRealtime() {
    _loaChannel?.unsubscribe();
    _loaChannel = supabase.Supabase.instance.client
        .channel('admin_loa_cache')
        .onPostgresChanges(
          event: supabase.PostgresChangeEvent.insert,
          table: 'mp_form_request_table',
          callback: (_) => _fetchLoaRequests(),
        )
        .onPostgresChanges(
          event: supabase.PostgresChangeEvent.update,
          table: 'mp_form_request_table',
          callback: (payload) {
            final updated = Map<String, dynamic>.from(payload.newRecord);
            updated['status'] = updated['form_status'] ?? '';
            updated['locked_by'] = updated['locked_by'] ?? '';
            final idx = _loaRequests.indexWhere(
              (m) => m['request_id'] == updated['request_id'],
            );
            if (idx != -1) {
              _loaRequests[idx] = {..._loaRequests[idx], ...updated};
              _loaController.add(List.from(_loaRequests));
            }
          },
        )
        .onPostgresChanges(
          event: supabase.PostgresChangeEvent.delete,
          table: 'mp_form_request_table',
          callback: (payload) {
            final deleted = payload.oldRecord;
            _loaRequests.removeWhere(
              (m) => m['request_id'] == deleted['request_id'],
            );
            _loaController.add(List.from(_loaRequests));
          },
        )
        .subscribe();
  }

  Future<void> refreshLoaRequests() => _fetchLoaRequests();

  // ── Members ───────────────────────────────────────────────────────────

  Future<void> initMembers() async {
    if (_membersInitialized) return;
    _membersInitialized = true;

    await _fetchMembers();
    if (useSupabase) _subscribeMembersRealtime();
  }

  Future<void> _fetchMembers() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/admin/get_all_members'),
        headers: buildApiHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _members =
            List<Map<String, dynamic>>.from(data['members'] ?? []);
        _membersController.add(_members);
      }
    } catch (e) {
      print('CacheService: Error fetching members: $e');
    }
  }

  void _subscribeMembersRealtime() {
    _membersChannel?.unsubscribe();
    _membersChannel = supabase.Supabase.instance.client
        .channel('admin_members_cache')
        .onPostgresChanges(
          event: supabase.PostgresChangeEvent.insert,
          table: 'mp_customers_info_table',
          callback: (_) => _fetchMembers(),
        )
        .onPostgresChanges(
          event: supabase.PostgresChangeEvent.update,
          table: 'mp_customers_info_table',
          callback: (payload) {
            final updated = Map<String, dynamic>.from(payload.newRecord);
            final idx = _members.indexWhere(
              (m) => m['id'] == updated['id'],
            );
            if (idx != -1) {
              _members[idx] = {..._members[idx], ...updated};
              _membersController.add(List.from(_members));
            }
          },
        )
        .onPostgresChanges(
          event: supabase.PostgresChangeEvent.delete,
          table: 'mp_customers_info_table',
          callback: (payload) {
            final deleted = payload.oldRecord;
            _members.removeWhere((m) => m['id'] == deleted['id']);
            _membersController.add(List.from(_members));
          },
        )
        .subscribe();
  }

  Future<void> refreshMembers() => _fetchMembers();

  // ── Cleanup ───────────────────────────────────────────────────────────

  void dispose() {
    _loaChannel?.unsubscribe();
    _membersChannel?.unsubscribe();
    _loaChannel = null;
    _membersChannel = null;
    _loaController.close();
    _membersController.close();
    _loaInitialized = false;
    _membersInitialized = false;
    _loaRequests = [];
    _members = [];
  }

  void reset() {
    _loaChannel?.unsubscribe();
    _membersChannel?.unsubscribe();
    _loaChannel = null;
    _membersChannel = null;
    _loaInitialized = false;
    _membersInitialized = false;
    _loaRequests = [];
    _members = [];
  }
}
