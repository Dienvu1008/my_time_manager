import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../ai/core/ai_message.dart';
import '../../ai/core/ai_tool_call.dart';

/// Một cuộc trò chuyện (conversation) với trợ lý AI — dòng tiêu đề trong danh
/// sách lịch sử chat, giống các ứng dụng AI thương mại.
///
/// Nội dung tin nhắn được lưu ở bảng riêng ([ChatMessageRecord]); model này chỉ
/// giữ metadata: tiêu đề và mốc thời gian. [updatedAt] tăng mỗi khi có tin nhắn
/// mới, dùng để sắp xếp (mới nhất lên đầu) và để tính retention (tự xóa sau N
/// ngày kể từ lần cập nhật cuối).
class Conversation {
  Conversation({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        title = title ?? '',
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String id;

  /// Tiêu đề hiển thị. Rỗng = chưa đặt (UI có thể hiện "Cuộc trò chuyện mới").
  String title;

  final DateTime createdAt;
  DateTime updatedAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'] as String,
      title: (map['title'] as String?) ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  Conversation copyWith({
    String? title,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String toJson() => json.encode(toMap());
  factory Conversation.fromJson(String source) =>
      Conversation.fromMap(json.decode(source) as Map<String, dynamic>);
}

/// Một tin nhắn được lưu bền vững, thuộc về một [Conversation].
///
/// Lưu đủ để dựng lại CẢ HAI biểu diễn khi mở lại chat:
///   - [AiMessage] (dành cho model): [role], [content], [toolCalls],
///     [toolCallId], [name];
///   - bong bóng hiển thị: thêm cờ [isError] (tin lỗi hiện khác màu).
///
/// [toolCalls] được lưu dưới dạng chuỗi JSON (một cột TEXT), giống cách các
/// model khác lưu danh sách phức tạp.
class ChatMessageRecord {
  ChatMessageRecord({
    String? id,
    required this.conversationId,
    required this.role,
    this.content = '',
    this.toolCalls = const [],
    this.toolCallId,
    this.name,
    this.isError = false,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  String id;
  final String conversationId;
  final AiRole role;
  final String content;
  final List<AiToolCall> toolCalls;
  final String? toolCallId;
  final String? name;

  /// True nếu đây là tin lỗi hiển thị (vai trò assistant nhưng là thông báo lỗi
  /// cho người dùng). Không đưa vào lịch sử gửi cho model.
  final bool isError;

  final DateTime createdAt;

  /// Dựng bản ghi lưu trữ từ một [AiMessage] của model.
  factory ChatMessageRecord.fromAiMessage(
    String conversationId,
    AiMessage message, {
    bool isError = false,
    DateTime? createdAt,
  }) {
    return ChatMessageRecord(
      conversationId: conversationId,
      role: message.role,
      content: message.content,
      toolCalls: message.toolCalls,
      toolCallId: message.toolCallId,
      name: message.name,
      isError: isError,
      createdAt: createdAt,
    );
  }

  /// Chuyển về [AiMessage] để nạp lại vào lịch sử model.
  AiMessage toAiMessage() => AiMessage(
        role: role,
        content: content,
        toolCalls: toolCalls,
        toolCallId: toolCallId,
        name: name,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'conversationId': conversationId,
        'role': role.wireName,
        'content': content,
        'toolCalls':
            toolCalls.isEmpty ? null : jsonEncode(toolCalls.map((c) => c.toJson()).toList()),
        'toolCallId': toolCallId,
        'name': name,
        'isError': isError ? 1 : 0,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ChatMessageRecord.fromMap(Map<String, dynamic> map) {
    final rawCalls = map['toolCalls'] as String?;
    final calls = <AiToolCall>[];
    if (rawCalls != null && rawCalls.isNotEmpty) {
      final decoded = jsonDecode(rawCalls);
      if (decoded is List) {
        for (final e in decoded) {
          calls.add(AiToolCall.fromJson(Map<String, dynamic>.from(e as Map)));
        }
      }
    }
    return ChatMessageRecord(
      id: map['id'] as String,
      conversationId: map['conversationId'] as String,
      role: AiRole.fromWireName(map['role'] as String),
      content: (map['content'] as String?) ?? '',
      toolCalls: calls,
      toolCallId: map['toolCallId'] as String?,
      name: map['name'] as String?,
      isError: (map['isError'] as int?) == 1,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
    );
  }
}
