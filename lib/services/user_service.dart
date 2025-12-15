import '../data/db_helper.dart';
import '../models/user_model.dart';

class UserService {
  static Future<void> addUser(UserModel user) async {
    await DBHelper.instance.insertUser(user.toMap());
  }

  static Future<List<UserModel>> getUsers() async {
    final data = await DBHelper.instance.fetchUsers();
    return data.map((e) => UserModel.fromMap(e)).toList();
  }
}
