import 'package:flutter/material.dart';
import 'package:jinlv/services/zhipu_ai_service.dart';

const Color _primaryYellow = Color(0xFFFFEB3B);

/// AI 聊天页面 - 智谱 GLM-4-Flash，回复英文
class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _addWelcome();
  }

  static const List<Map<String, String>> _presetPlaces = [
    {'name': '北京故宫', 'desc': '穿越明清，感受皇家气韵'},
    {'name': '云南大理', 'desc': '苍山洱海，风花雪月'},
    {'name': '桂林山水', 'desc': '山水甲天下，人间仙境'},
    {'name': '成都九寨沟', 'desc': '九寨归来不看水'},
    {'name': '上海外滩', 'desc': '东方明珠，魔都夜景'},
    {'name': '厦门鼓浪屿', 'desc': '文艺小岛，琴声悠扬'},
    {'name': '西安兵马俑', 'desc': '世界第八大奇迹'},
    {'name': '杭州西湖', 'desc': '上有天堂，下有苏杭'},
  ];

  void _addWelcome() {
    _messages.add(_ChatMessage(
      isFromAi: true,
      content: '你好！我是你的旅行助手。可以问我任何关于目的地、攻略或推荐的问题，我会用英文为你解答。',
      time: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;

    _controller.clear();
    final userMsg = _ChatMessage(isFromAi: false, content: text, time: DateTime.now());
    setState(() {
      _messages.add(userMsg);
      _loading = true;
    });
    _scrollToBottom();

    final history = _messages
        .map((m) => {'role': m.isFromAi ? 'assistant' : 'user', 'content': m.content})
        .toList();

    try {
      final reply = await ZhipuAiService.chat(history);
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(isFromAi: true, content: reply, time: DateTime.now()));
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(
            isFromAi: true,
            content: '抱歉，出了点问题：$e',
            time: DateTime.now(),
          ));
          _loading = false;
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        ),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/user_default.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 40,
                  height: 40,
                  color: _primaryYellow.withValues(alpha: 0.3),
                  child: const Icon(Icons.travel_explore, color: _primaryYellow, size: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '推荐地方',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                ...List.generate(_messages.length, (i) => _buildMessageBubble(_messages[i])),
                if (_messages.length <= 1) _buildPresetPlaces(),
              ],
            ),
          ),
          if (_loading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _primaryYellow),
                  ),
                  const SizedBox(width: 12),
                  Text('AI 正在思考...', style: TextStyle(color: Colors.white54, fontSize: 14)),
                ],
              ),
            ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    if (msg.isFromAi) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/user_default.png',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 36,
                  height: 36,
                  color: _primaryYellow.withValues(alpha: 0.3),
                  child: const Icon(Icons.smart_toy, color: _primaryYellow, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.zero,
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Text(
                  msg.content,
                  style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _primaryYellow.withValues(alpha: 0.3),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.zero,
                  ),
                ),
                child: Text(
                  msg.content,
                  style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildPresetPlaces() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '热门推荐',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _presetPlaces.map((p) {
              return GestureDetector(
                onTap: () {
                  _controller.text = '介绍一下${p['name']}，${p['desc']}';
                  _sendMessage();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        p['name']!,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        p['desc']!,
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_loading,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: '输入想了解的目的地...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _loading ? null : _sendMessage,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _loading ? Colors.grey : _primaryYellow,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.black, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final bool isFromAi;
  final String content;
  final DateTime time;

  _ChatMessage({required this.isFromAi, required this.content, required this.time});
}
