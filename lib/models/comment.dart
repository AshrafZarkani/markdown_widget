import 'dart:convert';

class Comment {
  final String id;
  final String authorName;
  final String content;
  final DateTime createdTime;
  final List<Comment> replies;

  Comment({
    required this.id,
    required this.authorName,
    required this.content,
    required this.createdTime,
    required this.replies,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Comment &&
        other.id == id &&
        other.authorName == authorName &&
        other.content == content &&
        other.createdTime == createdTime;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      authorName.hashCode ^
      content.hashCode ^
      createdTime.hashCode;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'authorName': authorName,
      'content': content,
      'createdTime': createdTime.millisecondsSinceEpoch,
      'replies': replies.map((reply) => reply.toMap()).toList(),
    };
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'] ?? '',
      authorName: map['authorName'] ?? '',
      content: map['content'] ?? '',
      createdTime: DateTime.fromMillisecondsSinceEpoch(map['createdTime']),
      replies:
          List<Comment>.from(map['replies']?.map((x) => Comment.fromMap(x))),
    );
  }

  String toJson() => json.encode(toMap());

  factory Comment.fromJson(String source) =>
      Comment.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Comment(id: $id, authorName: $authorName, content: $content, createdTime: $createdTime, replies: $replies)';
  }

  Comment copyWith({
    String? id,
    String? authorName,
    String? content,
    DateTime? createdTime,
    List<Comment>? replies,
  }) {
    return Comment(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      content: content ?? this.content,
      createdTime: createdTime ?? this.createdTime,
      replies: replies ?? this.replies,
    );
  }
}
