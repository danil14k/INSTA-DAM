class Comment {
  String? id;
  String postId;
  String username;
  String text;
  String date;

  Comment({this.id, required this.postId, required this.username, required this.text, required this.date});

  Map<String, dynamic> toMap() => {
        'postId': postId,
        'username': username,
        'text': text,
        'date': date,
      };

  factory Comment.fromMap(Map<String, dynamic> m, {String? docId}) =>
      Comment(id: docId ?? m['id']?.toString(), postId: m['postId'].toString(), username: m['username'], text: m['text'], date: m['date']);
}
