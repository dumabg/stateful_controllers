import 'package:flutter/material.dart';
import 'package:stateful_controllers/stateful_controllers.dart';
import 'users_controller.dart';

class UsersWidget extends StatefulWidget {
  final TextStyle style;
  final int numUsers;
  const UsersWidget({required this.numUsers, required this.style, super.key});

  @override
  State<UsersWidget> createState() => _UsersWidgetState();
}

class _UsersWidgetState
    extends AsyncStateWithController<UsersWidget, UsersController> {
  @override
  Widget buildWhenDone(BuildContext context) {
    return ListView(
      children: controller.users
          .map((String e) => ListTile(title: Text(e, style: widget.style)))
          .toList(),
    );
  }

  @override
  AsyncFactory<UsersController, UsersWidget> get controllerFactory =>
      UsersControllerFactory();
}
