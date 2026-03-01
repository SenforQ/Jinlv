import 'package:flutter/material.dart';
import 'package:jinlv/services/records_stats_service.dart';

const Color _primaryYellow = Color(0xFFFFEB3B);

/// 消费记录列表页
class RecordsConsumptionListPage extends StatefulWidget {
  const RecordsConsumptionListPage({super.key});

  @override
  State<RecordsConsumptionListPage> createState() => _RecordsConsumptionListPageState();
}

class _RecordsConsumptionListPageState extends State<RecordsConsumptionListPage> {
  List<ConsumptionRecord> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await RecordsStatsService.getConsumptionRecords();
    if (mounted) setState(() {
      _list = list;
      _loading = false;
    });
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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
          '消费记录',
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
                      return Container(
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
                                color: Colors.blue.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.payments_outlined, color: Colors.blue, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.title,
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    r.subtitle,
                                    style: TextStyle(color: Colors.white54, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(r.date),
                                    style: TextStyle(color: Colors.white38, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '¥${r.amount.toStringAsFixed(0)}',
                              style: const TextStyle(color: _primaryYellow, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            '暂无消费记录',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
