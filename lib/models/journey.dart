/// 旅程记录模型
class Journey {
  final String id;
  final String name;
  final String destination;
  final String? coverPath;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final String? budget;

  Journey({
    required this.id,
    required this.name,
    required this.destination,
    this.coverPath,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    this.budget,
  });

  /// 行程时长文案，如 "2天1晚"
  String get durationText {
    final days = endDate.difference(startDate).inDays;
    if (days == 0) return '1天';
    if (days == 1) return '2天1晚';
    return '${days + 1}天${days}晚';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'destination': destination,
        'coverPath': coverPath,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'budget': budget,
      };

  factory Journey.fromJson(Map<String, dynamic> json) => Journey(
        id: json['id'] as String,
        name: json['name'] as String,
        destination: json['destination'] as String,
        coverPath: json['coverPath'] as String?,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        budget: json['budget'] as String?,
      );
}
