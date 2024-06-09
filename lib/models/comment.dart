import 'dart:convert';

class Comment {
  final String authorName;
  final String content;
  final DateTime createdTime;

  Comment({required this.authorName, required this.content, required this.createdTime});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is Comment &&
      other.authorName == authorName &&
      other.content == content &&
      other.createdTime == createdTime;
  }

  @override
  int get hashCode => authorName.hashCode ^ content.hashCode ^ createdTime.hashCode;

  Map<String, dynamic> toMap() {
    return {
      'authorName': authorName,
      'content': content,
      'createdTime': createdTime.millisecondsSinceEpoch,
    };
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      authorName: map['authorName'] ?? '',
      content: map['content'] ?? '',
      createdTime: DateTime.fromMillisecondsSinceEpoch(map['createdTime']),
    );
  }

  String toJson() => json.encode(toMap());

  factory Comment.fromJson(String source) => Comment.fromMap(json.decode(source));

  @override
  String toString() => 'Comment(authorName: $authorName, content: $content, createdTime: $createdTime)';

  Comment copyWith({
    String? authorName,
    String? content,
    DateTime? createdTime,
  }) {
    return Comment(
      authorName: authorName ?? this.authorName,
      content: content ?? this.content,
      createdTime: createdTime ?? this.createdTime,
    );
  }
}
