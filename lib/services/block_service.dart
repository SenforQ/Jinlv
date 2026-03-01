import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 拉黑/屏蔽服务 - 本地存储
class BlockService {
  static const String _keyBlocked = 'explore_blocked_ids';
  static const String _keyMuted = 'explore_muted_ids';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<Set<String>> _getSet(String key) async {
    await init();
    final json = _prefs!.getString(key);
    if (json == null) return {};
    final list = jsonDecode(json) as List;
    return list.map((e) => e as String).toSet();
  }

  static Future<void> _saveSet(String key, Set<String> ids) async {
    await init();
    await _prefs!.setString(key, jsonEncode(ids.toList()));
  }

  static Future<Set<String>> getBlockedIds() => _getSet(_keyBlocked);
  static Future<Set<String>> getMutedIds() => _getSet(_keyMuted);

  static Future<void> blockFigure(String id) async {
    final ids = await getBlockedIds();
    ids.add(id);
    await _saveSet(_keyBlocked, ids);
  }

  static Future<void> muteFigure(String id) async {
    final ids = await getMutedIds();
    ids.add(id);
    await _saveSet(_keyMuted, ids);
  }

  static Future<bool> isBlockedOrMuted(String id) async {
    final blocked = await getBlockedIds();
    final muted = await getMutedIds();
    return blocked.contains(id) || muted.contains(id);
  }
}
