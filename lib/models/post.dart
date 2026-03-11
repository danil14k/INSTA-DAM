class Post {
  int? id;
  String imageUrl;
  String username;
  String description;
  String date;
  int likes;

  Post({this.id, required this.imageUrl, required this.username, required this.description, required this.date, this.likes = 0});

  Map<String, dynamic> toMap() => {
        'id': id,
        'imageUrl': imageUrl,
        'username': username,
        'description': description,
        'date': date,
        'likes': likes,
      };

  factory Post.fromMap(Map<String, dynamic> m) => Post(id: m['id'], imageUrl: m['imageUrl'], username: m['username'], description: m['description'], date: m['date'], likes: m['likes'] ?? 0);
}
