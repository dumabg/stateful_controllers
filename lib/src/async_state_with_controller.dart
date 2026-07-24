import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:state_controller/src/async_factory_isolated_creator_web.dart'
    if (dart.library.io) 'package:state_controller/src/async_factory_isolated_creator.dart';

import 'async_factory.dart';
import 'async_state.dart' show AsyncState;
import 'disposable.dart';

/// Define an [AsyncState] that uses an async controller.
/// The controller is created by a factory.
/// Override [controllerParamsFactory] to return the factory and the param
/// needed by the factory for creating the controller.
/// When the controller is created, could be used via [controller] property.
/// The controller creation could be mocked with
/// [onMockingControllerParamsFactory].
abstract class AsyncStateWithControllerParams<T extends StatefulWidget, U>
    extends AsyncState<T> {
  U? _controller;
  U get controller => _controller!;
  (AsyncFactory<U, T>, T)? _factory;
  AsyncFactoryIsolatedCreator<U, T>? _isolatedCreator;

  @protected
  (AsyncFactory<U, T>, T) get controllerParamsFactory;

  /// Allow to register a callback for mocking the controller
  /// creation.
  static FutureOr<dynamic> Function(
    AsyncFactory<dynamic, dynamic> controllerFactory,
    // ignore: avoid_annotating_with_dynamic
    dynamic params,
  )?
  onMockingControllerParamsFactory;

  Future<U> createController() {
    final AsyncFactory<U, T> factory = _factory!.$1;
    final T params = _factory!.$2;
    if (factory is AsyncFactoryIsIsolated) {
      _isolatedCreator = AsyncFactoryIsolatedCreator<U, T>();
      return _isolatedCreator!.createController(factory, params);
    } else {
      return factory.create(params);
    }
  }

  @override
  @mustCallSuper
  Future<void> asyncInitState() async {
    _isolatedCreator = null;
    _factory = controllerParamsFactory;
    _controller =
        (await onMockingControllerParamsFactory?.call(
              _factory!.$1,
              _factory!.$2,
            ))
            as U? ??
        await createController();
    _isolatedCreator = null;
    _factory = null;
  }

  /// Determine if the controller is created. It's possible that the controller
  /// isn't created on buildWhenLoading, buildWhenError and dispose methods.
  bool isControllerCreated() => _controller != null;

  @override
  @mustCallSuper
  void dispose() {
    if (_controller == null) {
      if (_factory != null) {
        final AsyncFactory<U, T> factory = _factory!.$1;
        if ((factory is AsyncFactoryIsIsolated) && (_isolatedCreator != null)) {
          _isolatedCreator!.kill();
        } else {
          if (factory is AsyncFactoryIsCancellable) {
            (factory as AsyncFactoryIsCancellable).cancel();
          }
        }
      }
    } else {
      if (_controller is Disposable) {
        (_controller! as Disposable).dispose();
      }
    }
    super.dispose();
  }
}

/// Define an [AsyncState] that uses an async controller.
/// The controller is created by a factory.
/// Override [controllerFactory] to return the factory [AsyncFactory] that will
/// be used for creating the controller with the default param [widget].
/// When the controller is created, could be used via [controller] property.
/// The controller creation could be mocked with
/// [onMockingControllerParamsFactory].
abstract class AsyncStateWithController<T extends StatefulWidget, U>
    extends AsyncStateWithControllerParams<T, U> {
  @override
  (AsyncFactory<U, T>, T) get controllerParamsFactory =>
      (controllerFactory, widget);

  AsyncFactory<U, T> get controllerFactory;
}
