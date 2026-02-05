class User {
  int? id;
  String username;
  String password;
  String? displayName;

  User({this.id, required this.username, required this.password, this.displayName});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'displayName': displayName,
    };
  }

  factory User.fromMap(Map<String, dynamic> m) => User(
        id: m['id'],
        username: m['username'],
        password: m['password'] ?? '',
        displayName: m['displayName'],
      );
}
