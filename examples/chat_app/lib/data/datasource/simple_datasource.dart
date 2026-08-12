import 'package:example/domain/entities/user_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

abstract class SimpleDataSource {
  Future<void> signIn(String login);

  Future<void> signOut();

  Future<bool> isSignIn();

  Future<UserEntity?> getCurrentUser();
}

class SimpleDataSourceImpl extends SimpleDataSource {
  SimpleDataSourceImpl(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<UserEntity?> getCurrentUser() async {
    if (!await isSignIn()) return null;
    return UserEntity(_prefs.getString(_loginKey), _prefs.getString(_uidKey));
  }

  @override
  Future<bool> isSignIn() => Future.value(_prefs.containsKey(_uidKey));

  @override
  Future<void> signIn(String login) => Future.wait(
      [_prefs.setString(_loginKey, login), _prefs.setString(_uidKey, const Uuid().v4())]);

  @override
  Future<void> signOut() => Future.wait([_prefs.remove(_uidKey), _prefs.remove(_loginKey)]);
}

const _uidKey = 'user_uid';
const _loginKey = 'user_login';
