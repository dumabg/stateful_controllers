import 'package:state_controllers/state_controllers.dart';

import 'users_widget.dart';

class UsersControllerFactory
    implements AsyncFactory<UsersController, UsersWidget>
//, AsyncFactoryIsIsolated
{
  @override
  Future<UsersController> create(UsersWidget widget) async {
    // Calls to the server to obtain the users
    // final List<String> users = await Server.call(numUsers: widget.numUsers);
    // Simulating the call:
    final numUsers = widget.numUsers;
    final List<String> users = await Future<List<String>>.delayed(
      const Duration(seconds: 4),
      () => List.generate(numUsers, (index) => 'user$index'),
    );
    return UsersController(users: users);
  }
}

class UsersController implements Disposable {
  final List<String> users;

  UsersController({required this.users});

  @override
  void dispose() {
    // ignore: avoid_print
    print('Users controller disposed');
  }
}
