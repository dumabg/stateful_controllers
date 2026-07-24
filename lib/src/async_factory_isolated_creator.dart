import 'dart:async';
import 'dart:isolate';

import 'async_factory.dart';

class _AsyncIsolateData<U, T> {
  final AsyncFactory<U, T> asyncFactory;
  final T params;
  final SendPort sendPort;

  _AsyncIsolateData(this.asyncFactory, this.params, this.sendPort);
}

Future<void> _launchIsolate<U, T>(_AsyncIsolateData<U, T> data) async {
  final U instance = await data.asyncFactory.create(data.params);
  data.sendPort.send(instance);
}

class AsyncFactoryIsolatedCreator<U, T> {
  Isolate? _isolate;

  Future<U> createController(AsyncFactory<U, T> factory, T params) async {
    final completer = Completer<U>();
    final receivePort = ReceivePort();
    receivePort.listen((message) {
      if (message is U) {
        completer.complete(message);
      } else {
        completer.completeError(
          'Invalid message returned. Expected $U, '
          'returned ${message.runtimeType}',
        );
      }
      receivePort.close();
    });
    try {
      _isolate = await Isolate.spawn(
        _launchIsolate<U, T>,
        _AsyncIsolateData<U, T>(factory, params, receivePort.sendPort),
      );
    } on Object {
      receivePort.close();
      rethrow;
    }
    return completer.future;
  }

  void kill() {
    _isolate?.kill(priority: Isolate.immediate);
  }
}
