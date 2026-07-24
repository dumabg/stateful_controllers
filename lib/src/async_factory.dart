/// Defines an async factory. The factory must create
/// an instance of T using P params.
abstract class AsyncFactory<T, P> {
  /// Return an instance of T using P params.
  Future<T> create(P param);
}

/// Marks AsyncFactory like cancellable.
/// While the factory is creating the controller and for some reason would be
/// canceled the creation, for example when the widget is disposed, the factory
/// is notified.
abstract interface class AsyncFactoryIsCancellable {
  /// Notify that the creation of the controller must be cancelled.
  /// This method is called automatically when the widget is disposed but the
  /// factory is still creating the controller.
  void cancel();
}

/// Marks the async factory like isolated.
/// The execution of [AsyncFactory.create] will be in an isolated.
/// If the widget is disposed while the factory is creating the controller,
/// the isolate will be killed.
/// The factory, parameter, result, and data they capture must obey Dart isolate
/// sendability rules.
/// Web doesn't supports Isolates, so this feature is not available on web.
/// If is used in web, it will be executed in the main isolate, like a normal
/// [AsyncFactory].
abstract interface class AsyncFactoryIsIsolated {}
