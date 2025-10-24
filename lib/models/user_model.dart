//models/user_model.dart
// A simple model class to represent a user.
class User {
  final int? id;
  final String username;
  final String password;

  User({this.id, required this.username, required this.password});

  // Convert a User into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
    };
  }

  // A factory constructor to create a User from a Map.
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
    );
  }

  @override
  String toString() {
    return 'User{id: $id, username: $username}';
  }
}
