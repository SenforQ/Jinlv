/// 行程节点（单日行程活动）
class JourneyNode {
  final String id;
  final String journeyId;
  final String title;
  final String? subtitle;
  final String type; // 景点、美食、住宿、交通 等
  final DateTime startTime;
  final DateTime endTime;
  final double? budget;
  final String footprint; // 足迹记录
  final String status; // 未开始、进行中、已完成

  JourneyNode({
    required this.id,
    required this.journeyId,
    required this.title,
    this.subtitle,
    this.type = '景点',
    required this.startTime,
    required this.endTime,
    this.budget,
    this.footprint = '',
    this.status = '未开始',
  });

  String get durationText {
    final minutes = endTime.difference(startTime).inMinutes;
    if (minutes < 60) return '$minutes分钟';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '$h小时';
    return '$h小时$m分钟';
  }

  String get timeRangeText =>
      '${_formatTime(startTime)} - ${_formatTime(endTime)} · $durationText';

  static String _formatTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'journeyId': journeyId,
        'title': title,
        'subtitle': subtitle,
        'type': type,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'budget': budget,
        'footprint': footprint,
        'status': status,
      };

  factory JourneyNode.fromJson(Map<String, dynamic> json) => JourneyNode(
        id: json['id'] as String,
        journeyId: json['journeyId'] as String,
        title: json['title'] as String,
        subtitle: json['subtitle'] as String?,
        type: json['type'] as String? ?? '景点',
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        budget: (json['budget'] as num?)?.toDouble(),
        footprint: json['footprint'] as String? ?? '',
        status: json['status'] as String? ?? '未开始',
      );

  JourneyNode copyWith({
    String? title,
    String? subtitle,
    String? type,
    DateTime? startTime,
    DateTime? endTime,
    double? budget,
    String? footprint,
    String? status,
  }) =>
      JourneyNode(
        id: id,
        journeyId: journeyId,
        title: title ?? this.title,
        subtitle: subtitle ?? this.subtitle,
        type: type ?? this.type,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        budget: budget ?? this.budget,
        footprint: footprint ?? this.footprint,
        status: status ?? this.status,
      );
}
