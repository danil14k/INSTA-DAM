class Comment {
  int? id;
  int postId;
  String username;
  String text;
  String date;

  Comment({this.id, required this.postId, required this.username, required this.text, required this.date});

  Map<String, dynamic> toMap() => {
        'id': id,
        'postId': postId,
        'username': username,
        'text': text,
        'date': date,
      };

  factory Comment.fromMap(Map<String, dynamic> m) => Comment(id: m['id'], postId: m['postId'], username: m['username'], text: m['text'], date: m['date']);
}
