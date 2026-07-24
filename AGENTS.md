# Using `state_controllers`

`state_controllers` separates Flutter UI from mutable application logic:

- Keep widgets and their `State` classes focused on rendering and immutable
  widget configuration.
- Put actions, mutable state, and resource ownership in a controller.
- Every `StatefulWidget` with state must have a controller.
- Do not use `setState` in application widget states. Use `ValueNotifier`
  fields on the controller and rebuild the affected UI with
  `watch`.
- Do not create `Dialog`s, `SnackBar`s, or other UI in a controller. The state
  owns the UI; the controller may request an action through a widget-exposed
  callback or another UI boundary.
- A controller must not import presentation-only Flutter APIs such as
  `material.dart` unless it genuinely owns a non-UI lifecycle resource. Prefer
  `foundation.dart` for `ValueNotifier`.
- Import the library through its public entrypoint:

```dart
import 'package:state_controllers/state_controllers.dart';
```

Do not import files from `package:state_controllers/src/...`; they are internal
implementation details.

## Choose the right state base class

| Situation                                                          | Base class                                           | What to implement                               |
| ------------------------------------------------------------------ | ---------------------------------------------------- | ----------------------------------------------- |
| The controller can be created immediately                          | `StateWithController<Widget, Controller>`            | `createController()`                            |
| The state needs async setup but no controller                      | `AsyncState<Widget>`                                 | `asyncInitState()` and `buildWhenDone()`        |
| The controller is created asynchronously using the widget as input | `AsyncStateWithController<Widget, Controller>`       | `controllerFactory` and `buildWhenDone()`       |
| An async controller needs an input other than the widget           | `AsyncStateWithControllerParams<Widget, Controller>` | `controllerParamsFactory` and `buildWhenDone()` |

Use `controller`:

- It is available after `createController()` in `StateWithController`.
- In async state classes, it is available in `buildWhenDone()`; it may not be
  available in loading, error, or disposal paths.

## Synchronous controller example

```dart
class CounterController {
  CounterController(int initialValue) : count = ValueNotifier(initialValue);

  final ValueNotifier<int> count;

  void increment() => count.value++;
}

class CounterView extends StatefulWidget {
  const CounterView({required this.initialValue, super.key});

  final int initialValue;

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState
    extends StateWithController<CounterView, CounterController> {
  @override
  CounterController createController() => CounterController(widget.initialValue);

  @override
  Widget build(BuildContext context) => watch<int>(
        valueListenable: controller.count,
        builder: (context, count, child) => Text('$count'),
      );
}
```

## Reactive values and disposal

Use a `ValueNotifier` for controller values that affect the UI, and render it
with `watch`. `watch` creates a `ValueListenableBuilder` and takes ownership of
the notifier it receives: it disposes that notifier when the widget state is
disposed.

Never dispose the same notifier in both places. If a notifier is passed to
`watch`, do not also dispose it in the controller's `dispose()` method.

If a controller owns other resources, implement `Disposable`; the state base
class will call `dispose()` when the widget is removed.

```dart
class SearchController implements Disposable {
  final FocusNode focusNode = FocusNode();

  @override
  void dispose() => focusNode.dispose();
}
```

## Async controllers

Create an `AsyncFactory<Controller, Parameter>` to load an async controller.
When the widget is the parameter, use `AsyncStateWithController`:

```dart
class UsersFactory implements AsyncFactory<UsersController, UsersView> {
  @override
  Future<UsersController> create(UsersView widget) async {
    final users = await loadUsers(widget.limit);
    return UsersController(users);
  }
}

class _UsersViewState
    extends AsyncStateWithController<UsersView, UsersController> {
  @override
  AsyncFactory<UsersController, UsersView> get controllerFactory =>
      UsersFactory();

  @override
  Widget buildWhenDone(BuildContext context) => Text('${controller.users}');
}
```

Override `buildWhenLoading` and `buildWhenError` for custom UI. Call
`retryAsyncInitState()` from error UI to attempt initialization again.

For application-wide defaults, set `AsyncState.defaultBuildWhenLoading`,
`AsyncState.defaultBuildWhenError`, and optionally `AsyncState.onError` during
application startup.

### Cancellation and isolate work

- Implement `AsyncFactoryIsCancellable` when initialization can be canceled.
  Its `cancel()` method is called if the widget is disposed before the
  controller is ready.
- Implement `AsyncFactoryIsIsolated` when `create()` should run in a
  separate Dart isolate. The factory, parameter, result, and captured data must
  all be sendable across isolates.

## Testing widgets that use controllers

Replace controller creation through the provided global hooks:

- `StateWithController.onMockingController` for synchronous controllers.
- `AsyncStateWithControllerParams.onMockingControllerParamsFactory` for async
  controllers. It may return a controller or a `Future`.

Set the hook in `setUp` and reset it in `tearDown` so it does not affect another
test. Because these hooks are global, do not change them concurrently.

```dart
tearDown(() {
  StateWithController.onMockingController = null;
});
```
