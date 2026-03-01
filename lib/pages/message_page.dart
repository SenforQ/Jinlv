import 'package:flutter/material.dart';
import 'package:jinlv/models/figure.dart';
import 'package:jinlv/pages/figure_chat_page.dart';
import 'package:jinlv/services/chat_storage.dart';
import 'package:jinlv/services/figure_service.dart';

const Color _primaryYellow = Color(0xFFFFEB3B);

class MessagePage extends StatefulWidget {
  const MessagePage({super.key, required this.currentTabIndex});

  final int currentTabIndex;

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  List<ChatSession> _sessions = [];
  bool _loading = true;
  static const int _messageTabIndex = 3;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  @override
  void didUpdateWidget(MessagePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentTabIndex == _messageTabIndex && oldWidget.currentTabIndex != _messageTabIndex) {
      _loadSessions();
    }
  }

  Future<void> _loadSessions() async {
    await FigureService.load();
    final sessions = await ChatStorage.getSessions();
    if (mounted) {
      setState(() {
        _sessions = sessions;
        _loading = false;
      });
    }
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(t.year, t.month, t.day);
    if (msgDate == today) {
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
    if (today.difference(msgDate).inDays == 1) {
      return '昨天';
    }
    return '${t.month}/${t.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          '消息',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: _primaryYellow))
          : _sessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 64, color: Colors.white.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text(
                        '暂无聊天记录',
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '去探索页与达人咨询攻略吧',
                        style: TextStyle(color: Colors.white38, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSessions,
                  color: _primaryYellow,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _sessions.length,
                    itemBuilder: (_, i) {
                      final s = _sessions[i];
                      final figure = FigureService.getFigureById(s.figureId);
                      if (figure == null) return const SizedBox.shrink();
                      return _buildSessionItem(s, figure);
                    },
                  ),
                ),
    );
  }

  Widget _buildSessionItem(ChatSession session, Figure figure) {
    return InkWell(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FigureChatPage(figure: figure),
          ),
        );
        _loadSessions();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                session.avatar,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 56,
                  height: 56,
                  color: Colors.white12,
                  child: const Icon(Icons.person, color: Colors.white38, size: 28),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          session.nickname,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTime(session.lastTime),
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    session.lastMessage,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
