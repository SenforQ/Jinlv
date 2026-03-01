import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/journey_node.dart';

/// 行程节点本地存储
class JourneyNodeStorage {
  static const String _keyPrefix = 'journey_nodes_';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static String _key(String journeyId) => '$_keyPrefix$journeyId';

  static Future<List<JourneyNode>> getNodes(String journeyId) async {
    await init();
    final json = _prefs!.getString(_key(journeyId));
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list
        .map((e) => JourneyNode.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  static Future<void> saveNodes(String journeyId, List<JourneyNode> nodes) async {
    await init();
    final list = nodes.map((e) => e.toJson()).toList();
    await _prefs!.setString(_key(journeyId), jsonEncode(list));
  }

  static Future<void> addNode(JourneyNode node) async {
    final list = await getNodes(node.journeyId);
    list.add(node);
    list.sort((a, b) => a.startTime.compareTo(b.startTime));
    await saveNodes(node.journeyId, list);
  }

  static Future<void> updateNode(JourneyNode node) async {
    final list = await getNodes(node.journeyId);
    final index = list.indexWhere((n) => n.id == node.id);
    if (index >= 0) {
      list[index] = node;
      list.sort((a, b) => a.startTime.compareTo(b.startTime));
      await saveNodes(node.journeyId, list);
    }
  }

  static Future<void> deleteNode(String journeyId, String nodeId) async {
    final list = await getNodes(journeyId);
    list.removeWhere((n) => n.id == nodeId);
    await saveNodes(journeyId, list);
  }
}
