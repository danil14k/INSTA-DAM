class Post {
  String? id;
  String imageUrl;
  String username;
  String description;
  String date;
  int likes;
  String mediaPath;
  String mediaType;
  String location;

  Post({
    this.id,
    required this.imageUrl,
    required this.username,
    required this.description,
    required this.date,
    this.likes = 0,
    this.mediaPath = '',
    this.mediaType = '',
    this.location = '',
  });

  bool get hasMedia => mediaPath.isNotEmpty && mediaType.isNotEmpty;
  bool get isVideo => mediaType == 'video';
  bool get isImage => mediaType == 'image';

  Map<String, dynamic> toMap() => {
        'imageUrl': imageUrl,
        'username': username,
        'description': description,
        'date': date,
        'likes': likes,
        'mediaPath': mediaPath,
        'mediaType': mediaType,
        'location': location,
      };

  factory Post.fromMap(Map<String, dynamic> m, {String? docId}) => Post(
        id: docId ?? m['id']?.toString(),
        imageUrl: m['imageUrl'] ?? '',
        username: m['username'],
        description: m['description'],
        date: m['date'],
        likes: m['likes'] ?? 0,
        mediaPath: m['mediaPath'] ?? '',
        mediaType: m['mediaType'] ?? '',
        location: m['location'] ?? '',
      );
}
