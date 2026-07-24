import 'package:state_controllers/state_controllers.dart';

class AsyncFactoryIsolatedCreator<U, T> {
  Future<U> createController(AsyncFactory<U, T> factory, T params) async {
    return factory.create(params);
  }

  void kill() {}
}
