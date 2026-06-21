import 'dart:convert';

import 'package:medicare_admin_remaster/class/status_item.dart';
import 'package:medicare_admin_remaster/shared/list.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalMemberConfigService {
  static const String _planTypesKey = 'member_plan_type_items_v1';

  Future<List<StatusItem>> loadPlanTypes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_planTypesKey);
    if (raw == null || raw.isEmpty) {
      return List<StatusItem>.from(planTypeItems);
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return List<StatusItem>.from(planTypeItems);
      }

      final parsed = decoded
          .map((item) => _toStatusItem(item))
          .whereType<StatusItem>()
          .toList();

      if (parsed.isEmpty) {
        return List<StatusItem>.from(planTypeItems);
      }

      parsed.sort((a, b) => a.id.compareTo(b.id));
      return parsed;
    } catch (_) {
      return List<StatusItem>.from(planTypeItems);
    }
  }

  Future<void> savePlanTypes(List<StatusItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = items
        .map((item) => <String, dynamic>{
              'id': item.id,
              'status': item.status,
            })
        .toList();

    await prefs.setString(_planTypesKey, jsonEncode(payload));
  }

  Future<void> resetPlanTypes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_planTypesKey);
  }

  StatusItem? _toStatusItem(dynamic raw) {
    if (raw is! Map) {
      return null;
    }

    final idRaw = raw['id'];
    final statusRaw = raw['status'];
    final id = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '');
    final status = statusRaw?.toString().trim() ?? '';

    if (id == null || status.isEmpty) {
      return null;
    }

    return StatusItem(id: id, status: status);
  }
}
