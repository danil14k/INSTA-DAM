class User {
  int? id;
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
      'id': id,
      'username': username,
      'password': password,
      'displayName': displayName,
      'bio': bio,
      'profileImagePath': profileImagePath,
    };
  }

  factory User.fromMap(Map<String, dynamic> m) => User(
        id: m['id'],
        username: m['username'],
        password: m['password'] ?? '',
        displayName: m['displayName'],
        bio: m['bio'] ?? '',
        profileImagePath: m['profileImagePath'] ?? '',
      );
}
