import 'package:flutter/material.dart';
import 'package:jinlv/pages/journey_detail_page.dart';
import 'package:jinlv/services/records_stats_service.dart';

const Color _primaryYellow = Color(0xFFFFEB3B);

/// 城市记录列表页
class RecordsCitiesListPage extends StatefulWidget {
  const RecordsCitiesListPage({super.key});

  @override
  State<RecordsCitiesListPage> createState() => _RecordsCitiesListPageState();
}

class _RecordsCitiesListPageState extends State<RecordsCitiesListPage> {
  List<CityRecord> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await RecordsStatsService.getCityRecords();
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
          '去过城市',
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
                      final r = _list[i];
                      return _buildCityCard(r);
                    },
                  ),
                ),
    );
  }

  Widget _buildCityCard(CityRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _showCityJourneys(record),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.pink.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.place, color: Colors.pink, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.city,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${record.journeyCount} 次旅行',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.white38, size: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCityJourneys(CityRecord record) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${record.city} - 旅行记录',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: record.journeys.length,
                itemBuilder: (_, i) {
                  final j = record.journeys[i];
                  return ListTile(
                    leading: Icon(Icons.flight_takeoff, color: _primaryYellow, size: 24),
                    title: Text(j.name, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      '${_formatDate(j.startDate)} - ${_formatDate(j.endDate)}',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JourneyDetailPage(journey: j),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
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
          Icon(Icons.place_outlined, size: 64, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            '暂无城市记录',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
