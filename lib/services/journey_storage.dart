import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/journey.dart';

/// 旅程记录本地存储
class JourneyStorage {
  static const String _keyJourneys = 'journey_list';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<List<Journey>> getJourneys() async {
    await init();
    final json = _prefs!.getString(_keyJourneys);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => Journey.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> saveJourneys(List<Journey> journeys) async {
    await init();
    final list = journeys.map((e) => e.toJson()).toList();
    await _prefs!.setString(_keyJourneys, jsonEncode(list));
  }

  static Future<void> addJourney(Journey journey) async {
    final list = await getJourneys();
    list.insert(0, journey);
    await saveJourneys(list);
  }

  static Future<void> updateJourney(Journey journey) async {
    final list = await getJourneys();
    final index = list.indexWhere((j) => j.id == journey.id);
    if (index >= 0) {
      list[index] = journey;
      await saveJourneys(list);
    }
  }

  static Future<void> deleteJourney(String id) async {
    final list = await getJourneys();
    list.removeWhere((j) => j.id == id);
    await saveJourneys(list);
  }
}
