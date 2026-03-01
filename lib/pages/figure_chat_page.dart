import 'package:flutter/material.dart';
import 'package:jinlv/models/figure.dart';
import 'package:jinlv/services/chat_storage.dart';

const Color _primaryYellow = Color(0xFFFFEB3B);

/// 攻略咨询 - 与角色聊天
class FigureChatPage extends StatefulWidget {
  const FigureChatPage({super.key, required this.figure});

  final Figure figure;

  @override
  State<FigureChatPage> createState() => _FigureChatPageState();
}

class _ChatMessage {
  final bool isFromFigure;
  final String content;
  final DateTime time;

  _ChatMessage({required this.isFromFigure, required this.content, required this.time});

  factory _ChatMessage.fromStored(StoredChatMessage m) =>
      _ChatMessage(isFromFigure: m.isFromFigure, content: m.content, time: m.time);
}

class _FigureChatPageState extends State<FigureChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final stored = await ChatStorage.getMessages(widget.figure.id);
    if (mounted) {
      setState(() {
        if (stored.isEmpty) {
          _addGreeting();
        } else {
          _messages.addAll(stored.map((m) => _ChatMessage.fromStored(m)));
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _addGreeting() {
    final greeting = '你好呀～我是${widget.figure.nickname}，很高兴认识你！'
        '有什么关于旅行攻略的问题都可以问我哦～';
    final msg = StoredChatMessage(
      isFromFigure: true,
      content: greeting,
      time: DateTime.now(),
    );
    _messages.add(_ChatMessage.fromStored(msg));
    ChatStorage.saveMessage(
      widget.figure.id,
      widget.figure.nickname,
      widget.figure.avatar,
      msg,
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    final msg = StoredChatMessage(
      isFromFigure: false,
      content: text,
      time: DateTime.now(),
    );
    setState(() {
      _messages.add(_ChatMessage.fromStored(msg));
    });
    ChatStorage.saveMessage(
      widget.figure.id,
      widget.figure.nickname,
      widget.figure.avatar,
      msg,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        ),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                widget.figure.avatar,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 40,
                  height: 40,
                  color: Colors.white12,
                  child: const Icon(Icons.person, color: Colors.white38),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              widget.figure.nickname,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (_, i) => _buildMessageBubble(_messages[i]),
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    if (msg.isFromFigure) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                widget.figure.avatar,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 36,
                  height: 36,
                  color: Colors.white12,
                  child: const Icon(Icons.person, color: Colors.white38, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.zero,
                    topRight: const Radius.circular(16),
                    bottomLeft: const Radius.circular(16),
                    bottomRight: const Radius.circular(16),
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
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: const Radius.circular(16),
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
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: '输入消息...',
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
            onTap: _sendMessage,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: _primaryYellow,
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
