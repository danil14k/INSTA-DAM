class User {
  String? id;
  String username;
  String password;
  String? displayName;
  String bio;
  String profileImagePath;

  User({
    this.id,
    required this.username,
    required this.password,
    this.displayName,
    this.bio = '',
    this.profileImagePath = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'displayName': displayName,
      'bio': bio,
      'profileImagePath': profileImagePath,
    };
  }

  factory User.fromMap(Map<String, dynamic> m, {String? docId}) => User(
        id: docId ?? m['id']?.toString(),
        username: m['username'],
        password: m['password'] ?? '',
        displayName: m['displayName'],
        bio: m['bio'] ?? '',
        profileImagePath: m['profileImagePath'] ?? '',
      );
}
