class UserModel {
  final int? id;
  final String username;
  final String email;

  UserModel({this.id, required this.username, required this.email});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      username: map['username'],
      email: map['email'],
    );
  }
}
