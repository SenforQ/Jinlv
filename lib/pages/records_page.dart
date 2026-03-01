import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:jinlv/pages/records_cities_list_page.dart';
import 'package:jinlv/pages/records_consumption_list_page.dart';
import 'package:jinlv/pages/records_people_list_page.dart';
import 'package:jinlv/pages/records_travel_list_page.dart';
import 'package:jinlv/services/records_stats_service.dart';

const Color _primaryYellow = Color(0xFFFFEB3B);

class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key});

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  double _consumption = 0;
  int _cities = 0;
  int _travelRecords = 0;
  int _peopleCommunicated = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final consumption = await RecordsStatsService.getTotalConsumption();
    final cities = await RecordsStatsService.getCitiesVisited();
    final travelRecords = await RecordsStatsService.getTravelRecordsCount();
    final people = await RecordsStatsService.getPeopleCommunicated();
    if (mounted) {
      setState(() {
        _consumption = consumption;
        _cities = cities;
        _travelRecords = travelRecords;
        _peopleCommunicated = people;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        onRefresh: _loadStats,
        color: _primaryYellow,
        child: _loading
            ? Center(child: CircularProgressIndicator(color: _primaryYellow))
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '记录',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildMainSection(),
                          const SizedBox(height: 24),
                          _buildStatsCards(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMainSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          _buildActivityRings(),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMetricItem('实际消费', '¥${_formatConsumption(_consumption)}', Colors.blue, _openConsumptionList),
                const SizedBox(height: 12),
                _buildMetricItem('去过城市', '$_cities 座', Colors.pink, _openCitiesList),
                const SizedBox(height: 12),
                _buildMetricItem('旅行记录', '$_travelRecords 条', Colors.amber, _openTravelList),
                const SizedBox(height: 12),
                _buildMetricItem('交流人数', '$_peopleCommunicated 人', Colors.green, _openPeopleList),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openConsumptionList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RecordsConsumptionListPage()),
    ).then((_) => _loadStats());
  }

  void _openCitiesList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RecordsCitiesListPage()),
    ).then((_) => _loadStats());
  }

  void _openTravelList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RecordsTravelListPage()),
    ).then((_) => _loadStats());
  }

  void _openPeopleList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RecordsPeopleListPage()),
    ).then((_) => _loadStats());
  }

  String _formatConsumption(double v) {
    if (v >= 10000) return '${(v / 10000).toStringAsFixed(1)}万';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }

  Widget _buildActivityRings() {
    // 从外到内：绿(交流人数)、黄(旅行记录)、粉(城市)、蓝(消费)
    const colors = [Colors.green, Colors.amber, Colors.pink, Colors.blue];
    const targets = [10000.0, 20.0, 30.0, 20.0]; // 消费、城市、记录、人数
    final values = [_consumption, _cities.toDouble(), _travelRecords.toDouble(), _peopleCommunicated.toDouble()];
    // 圆环从外到内：绿(人数)、黄(记录)、粉(城市)、蓝(消费)
    final progresses = [
      (values[3] / targets[3]).clamp(0.0, 1.0),
      (values[2] / targets[2]).clamp(0.0, 1.0),
      (values[1] / targets[1]).clamp(0.0, 1.0),
      (values[0] / targets[0]).clamp(0.0, 1.0),
    ];
    const size = 100.0;
    const strokeWidth = 6.0;
    const gap = 4.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < 4; i++)
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(i * (strokeWidth + gap)),
                child: CircularProgressIndicator(
                  value: progresses[i],
                  strokeWidth: strokeWidth,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(colors[i]),
                ),
              ),
            ),
          Text(
            '${_travelRecords + _cities + _peopleCommunicated}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: Colors.white38, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '旅行统计',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard('实际消费', '¥${_formatConsumption(_consumption)}', Colors.blue, _openConsumptionList)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('去过城市', '$_cities 座', Colors.pink, _openCitiesList)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard('旅行记录', '$_travelRecords 条', Colors.amber, _openTravelList)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('交流人数', '$_peopleCommunicated 人', Colors.green, _openPeopleList)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          CustomPaint(
            size: const Size(double.infinity, 24),
            painter: _WaveLinePainter(color: color.withValues(alpha: 0.6)),
          ),
        ],
        ),
      ),
    );
  }
}

/// 简易波浪线
class _WaveLinePainter extends CustomPainter {
  _WaveLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height / 2);
    for (var x = 0.0; x <= size.width; x += 4) {
      final y = size.height / 2 + 8 * math.sin(x * 0.05);
      path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
