import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class OfflineCacheService {
  OfflineCacheService._();
  static final OfflineCacheService instance = OfflineCacheService._();
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> cacheIntents(String companyId, List<Intent> intents) async {
    final data = intents.map((i) => i.toJson()).toList();
    await _prefs?.setString('intents_$companyId', jsonEncode(data));
  }

  List<Intent>? getCachedIntents(String companyId) {
    final raw = _prefs?.getString('intents_$companyId');
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Intent.fromJson(e)).toList();
    } catch (_) { return null; }
  }

  Future<void> saveVisitorId(String id) async => _prefs?.setString('visitor_id', id);
  String? getVisitorId() => _prefs?.getString('visitor_id');

  Future<void> saveSessionId(String companyId, String id) async =>
      _prefs?.setString('session_$companyId', id);
  String? getSessionId(String companyId) => _prefs?.getString('session_$companyId');

  Future<void> savePendingMessage(String companyId, Message msg) async {
    final key  = 'pending_$companyId';
    final raw  = _prefs?.getString(key) ?? '[]';
    final list = jsonDecode(raw) as List;
    list.add({
      'id': msg.id, 'content': msg.content,
      'sender': msg.sender.name, 'created_at': msg.createdAt.toIso8601String(),
    });
    await _prefs?.setString(key, jsonEncode(list));
  }
}
