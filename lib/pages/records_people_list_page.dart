import 'package:flutter/material.dart';
import 'package:jinlv/models/figure.dart';
import 'package:jinlv/pages/figure_chat_page.dart';
import 'package:jinlv/services/chat_storage.dart';
import 'package:jinlv/services/figure_service.dart';
import 'package:jinlv/services/records_stats_service.dart';

const Color _primaryYellow = Color(0xFFFFEB3B);

/// 交流记录列表页
class RecordsPeopleListPage extends StatefulWidget {
  const RecordsPeopleListPage({super.key});

  @override
  State<RecordsPeopleListPage> createState() => _RecordsPeopleListPageState();
}

class _RecordsPeopleListPageState extends State<RecordsPeopleListPage> {
  List<ChatSession> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await FigureService.load();
    final sessions = await RecordsStatsService.getPeopleRecords();
    if (mounted) setState(() {
      _list = sessions;
      _loading = false;
    });
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(t.year, t.month, t.day);
    if (msgDate == today) {
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
    if (today.difference(msgDate).inDays == 1) return '昨天';
    return '${t.month}/${t.day}';
  }

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
          '交流记录',
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
                      final s = _list[i];
                      final figure = FigureService.getFigureById(s.figureId);
                      if (figure == null) return const SizedBox.shrink();
                      return _buildSessionItem(s, figure);
                    },
                  ),
                ),
    );
  }

  Widget _buildSessionItem(ChatSession session, Figure figure) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FigureChatPage(figure: figure),
          ),
        );
        _load();
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
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                session.avatar,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: Colors.green.withValues(alpha: 0.3),
                  child: const Icon(Icons.person, color: Colors.green, size: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.nickname,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session.lastMessage,
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(session.lastTime),
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
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            '暂无交流记录',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
