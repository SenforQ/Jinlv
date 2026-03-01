import 'package:flutter/material.dart';
import 'package:jinlv/models/journey.dart';
import 'package:jinlv/pages/journey_detail_page.dart';
import 'package:jinlv/services/records_stats_service.dart';

const Color _primaryYellow = Color(0xFFFFEB3B);

/// 旅行记录列表页
class RecordsTravelListPage extends StatefulWidget {
  const RecordsTravelListPage({super.key});

  @override
  State<RecordsTravelListPage> createState() => _RecordsTravelListPageState();
}

class _RecordsTravelListPageState extends State<RecordsTravelListPage> {
  List<Journey> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await RecordsStatsService.getTravelRecords();
    if (mounted) setState(() {
      _list = list;
      _loading = false;
    });
  }

  String _formatDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '旅行记录',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: _primaryYellow))
          : _list.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: _primaryYellow,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _list.length,
                    itemBuilder: (_, i) {
                      final j = _list[i];
                      return _buildJourneyCard(j);
                    },
                  ),
                ),
    );
  }

  Widget _buildJourneyCard(Journey journey) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => JourneyDetailPage(journey: journey),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.flight_takeoff, color: Colors.amber, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    journey.name,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.place_outlined, size: 14, color: Colors.white54),
                      const SizedBox(width: 4),
                      Text(
                        journey.destination,
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDate(journey.startDate)} - ${_formatDate(journey.endDate)} · ${journey.durationText}',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white38, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flight_takeoff, size: 64, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            '暂无旅行记录',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
