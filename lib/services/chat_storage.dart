import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 聊天消息模型
class StoredChatMessage {
  final bool isFromFigure;
  final String content;
  final DateTime time;

  StoredChatMessage({
    required this.isFromFigure,
    required this.content,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
        'isFromFigure': isFromFigure,
        'content': content,
        'time': time.toIso8601String(),
      };

  factory StoredChatMessage.fromJson(Map<String, dynamic> json) => StoredChatMessage(
        isFromFigure: json['isFromFigure'] as bool,
        content: json['content'] as String,
        time: DateTime.parse(json['time'] as String),
      );
}

/// 聊天会话摘要（用于消息列表）
class ChatSession {
  final String figureId;
  final String nickname;
  final String avatar;
  final String lastMessage;
  final DateTime lastTime;

  ChatSession({
    required this.figureId,
    required this.nickname,
    required this.avatar,
    required this.lastMessage,
    required this.lastTime,
  });

  Map<String, dynamic> toJson() => {
        'figureId': figureId,
        'nickname': nickname,
        'avatar': avatar,
        'lastMessage': lastMessage,
        'lastTime': lastTime.toIso8601String(),
      };

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
        figureId: json['figureId'] as String,
        nickname: json['nickname'] as String,
        avatar: json['avatar'] as String,
        lastMessage: json['lastMessage'] as String,
        lastTime: DateTime.parse(json['lastTime'] as String),
      );
}

/// 聊天记录本地存储
class ChatStorage {
  static const String _keySessions = 'chat_sessions';
  static const String _keyMessagesPrefix = 'chat_messages_';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static String _messagesKey(String figureId) => '$_keyMessagesPrefix$figureId';

  /// 获取某角色的聊天记录
  static Future<List<StoredChatMessage>> getMessages(String figureId) async {
    await init();
    final json = _prefs!.getString(_messagesKey(figureId));
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => StoredChatMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 保存消息并更新会话
  static Future<void> saveMessage(
    String figureId,
    String nickname,
    String avatar,
    StoredChatMessage message,
  ) async {
    await init();

    final messages = await getMessages(figureId);
    messages.add(message);
    await _prefs!.setString(
      _messagesKey(figureId),
      jsonEncode(messages.map((m) => m.toJson()).toList()),
    );

    final sessions = await getSessions();
    final index = sessions.indexWhere((s) => s.figureId == figureId);
    final session = ChatSession(
      figureId: figureId,
      nickname: nickname,
      avatar: avatar,
      lastMessage: message.content,
      lastTime: message.time,
    );
    if (index >= 0) {
      sessions[index] = session;
    } else {
      sessions.insert(0, session);
    }
    sessions.sort((a, b) => b.lastTime.compareTo(a.lastTime));
    await _prefs!.setString(_keySessions, jsonEncode(sessions.map((s) => s.toJson()).toList()));
  }

  /// 获取所有聊天会话（按最新消息排序）
  static Future<List<ChatSession>> getSessions() async {
    await init();
    final json = _prefs!.getString(_keySessions);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => ChatSession.fromJson(e as Map<String, dynamic>)).toList();
  }
}
