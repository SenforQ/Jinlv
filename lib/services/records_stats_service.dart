import 'package:jinlv/models/journey.dart';
import 'package:jinlv/services/chat_storage.dart';
import 'package:jinlv/services/journey_node_storage.dart';
import 'package:jinlv/services/journey_storage.dart';

/// 消费记录项
class ConsumptionRecord {
  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final DateTime date;

  ConsumptionRecord({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
  });
}

/// 城市记录项
class CityRecord {
  final String city;
  final int journeyCount;
  final List<Journey> journeys;

  CityRecord({required this.city, required this.journeyCount, required this.journeys});
}

/// 记录统计服务
class RecordsStatsService {
  /// 实际消费（旅程预算 + 行程节点预算）
  static Future<double> getTotalConsumption() async {
    final journeys = await JourneyStorage.getJourneys();
    double total = 0;

    for (final j in journeys) {
      if (j.budget != null && j.budget!.isNotEmpty) {
        total += double.tryParse(j.budget!.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
      }
      final nodes = await JourneyNodeStorage.getNodes(j.id);
      for (final n in nodes) {
        if (n.budget != null) total += n.budget!;
      }
    }
    return total;
  }

  /// 去过的城市数（唯一目的地）
  static Future<int> getCitiesVisited() async {
    final journeys = await JourneyStorage.getJourneys();
    final cities = journeys.map((j) => j.destination.trim()).where((d) => d.isNotEmpty).toSet();
    return cities.length;
  }

  /// 旅行记录数
  static Future<int> getTravelRecordsCount() async {
    final journeys = await JourneyStorage.getJourneys();
    return journeys.length;
  }

  /// 交流过的人数（聊天会话数）
  static Future<int> getPeopleCommunicated() async {
    final sessions = await ChatStorage.getSessions();
    return sessions.length;
  }

  /// 消费记录列表（旅程预算 + 节点预算）
  static Future<List<ConsumptionRecord>> getConsumptionRecords() async {
    final journeys = await JourneyStorage.getJourneys();
    final list = <ConsumptionRecord>[];

    for (final j in journeys) {
      if (j.budget != null && j.budget!.isNotEmpty) {
        final v = double.tryParse(j.budget!.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
        if (v > 0) {
          list.add(ConsumptionRecord(
            id: 'j_${j.id}',
            title: j.name,
            subtitle: j.destination,
            amount: v,
            date: j.startDate,
          ));
        }
      }
      final nodes = await JourneyNodeStorage.getNodes(j.id);
      for (final n in nodes) {
        if (n.budget != null && n.budget! > 0) {
          list.add(ConsumptionRecord(
            id: n.id,
            title: n.title,
            subtitle: '${j.name} · ${j.destination}',
            amount: n.budget!,
            date: n.startTime,
          ));
        }
      }
    }
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// 城市记录列表（按目的地分组）
  static Future<List<CityRecord>> getCityRecords() async {
    final journeys = await JourneyStorage.getJourneys();
    final map = <String, List<Journey>>{};
    for (final j in journeys) {
      final city = j.destination.trim();
      if (city.isEmpty) continue;
      map.putIfAbsent(city, () => []).add(j);
    }
    return map.entries
        .map((e) => CityRecord(city: e.key, journeyCount: e.value.length, journeys: e.value))
        .toList()
      ..sort((a, b) => b.journeyCount.compareTo(a.journeyCount));
  }

  /// 旅行记录列表
  static Future<List<Journey>> getTravelRecords() async {
    final list = await JourneyStorage.getJourneys();
    list.sort((a, b) => b.startDate.compareTo(a.startDate));
    return list;
  }

  /// 交流记录列表（聊天会话）
  static Future<List<ChatSession>> getPeopleRecords() async {
    return ChatStorage.getSessions();
  }
}
