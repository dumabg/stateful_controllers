# state_controllers

A small Flutter library for keeping widget state and application logic in
separate controller classes. It provides base `State` classes that create a
controller, make it available to the UI, and optionally manage asynchronous
creation and disposal.

The intended split is simple:

- The widget and its `State` contain UI only.
- The controller contains the widget's logic and mutable values.
- Values that affect the UI use `ValueNotifier` and are read with
  `ValueListenableBuilder`

## Features

- Create synchronous or asynchronous controllers from a `State`.
- Dispose controllers that implement `Disposable`.
- Rebuild from `ValueNotifier` values with `watch`, then dispose those
  notifiers automatically.
- Show customizable loading and error states while initializing asynchronously.
- Retry failed asynchronous initialization.
- Cancel an in-progress controller factory, or run a marked controller factory in a Dart isolate.
- Replace controller creation globally in widget tests.

## Installation

Add the package to your Flutter project:

```sh
flutter pub add state_controllers
```

Then import its public API:

```dart
import 'package:state_controllers/state_controllers.dart';
```

## Synchronous controllers

Create the controller in its own file. Its constructor receives the widget,
which lets it use immutable configuration without putting logic in the
widget's `State`.

```dart
// counter_controller.dart
class CounterController {
  final ValueNotifier<int> count;

  CounterController(CounterWidget widget)
      : count = ValueNotifier<int>(widget.initialValue);

  void increment() => count.value++;
}
```

Extend `StateWithController` and implement `createController`. The controller is
created during `initState` and can receive the widget as a constructor argument.

There is no `setState` call. Use `watch` to receive change notifications. It is a wrapper of `ValueListenableBuilder` but every notifier passed to `watch` is tracked and disposed when the `State` is disposed.

```dart
// counter_widget.dart
class CounterWidget extends StatefulWidget {
  const Counter({required this.initialValue, super.key});

  final int initialValue;

  @override
  State<Counter> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends StateWithController<CounterWidget, CounterController> {
  @override
  CounterController createController() =>
      CounterController(widget);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        watch<int>(
          valueListenable: controller.count,
          builder: (context, value, child) => Text('$value'),
        ),
        IconButton(
          onPressed: controller.increment,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
```

A controller that owns other resources can implement `Disposable`. 

`dispose` is called automatically when the `State` is disposed.

```dart
class SearchController implements Disposable {
  final FocusNode focusNode = FocusNode();

  @override
  void dispose() {
    focusNode.dispose();
  }
}
```

Do not also dispose a notifier in the controller if it is passed to `watch`,
`watch` owns that notifier's disposal.

## Asynchronous controllers

Create the `State` with `AsyncStateWithController` for a widget that the controller is only valid after asynchronous work. It has 3 build methods for the different asynchronous states:

- `buildWhenLoading`: `build` used when the controller is being created.
- `buildWhenError`: `build` used if the controller creation fails.
- `buildWhenDone`: `build` used when the controller is ready.

The controller is created with a factory. Define an `AsyncFactory`, responsible for creating the controller.

```dart
class UsersController {
  final List<String> users;

  UsersController(this.users);
}

class UsersControllerFactory
    implements AsyncFactory<UsersController, UsersView> {
  @override
  Future<UsersController> create(UsersView widget) async {
    final List<String> users = await loadUsers(limit: widget.limit);
    return UsersController(users);
  }
}

class UsersView extends StatefulWidget {
  final int limit;

  const UsersView({required this.limit, super.key});

  @override
  State<UsersView> createState() => _UsersViewState();
}

class _UsersViewState
    extends AsyncStateWithController<UsersView, UsersController> {
  @override
  AsyncFactory<UsersController, UsersView> get controllerFactory =>
      UsersControllerFactory();

  @override
  Widget buildWhenDone(BuildContext context) {
    return ListView(
      children: controller.users
          .map((user) => ListTile(title: Text(user)))
          .toList(),
    );
  }
}
```

Use the lower-level `AsyncStateWithControllerParams` when you want to provide
the factory with a different parameter (not the widget):

```dart
class UsersControllerFactory
    implements AsyncFactory<UsersController, MyParam> {
  @override
  Future<UsersController> create(MyParam myParam) async {
    ---
  }
}


class _UsersViewState
    extends AsyncStateWithControllerParams<UsersView, UsersController> {
  @override
  (AsyncFactory<UsersController, MyParam>, MyParam)
      get controllerParamsFactory => (UsersControllerFactory(), MyParam());

}
```

### Loading, errors, and retry

Override either builder to customize one widget:

```dart
@override
Widget buildWhenLoading(BuildContext context) =>
    const Center(child: Text('Loading users...'));

@override
Widget buildWhenError(BuildContext context) => Center(
      child: FilledButton(
        onPressed: retryAsyncInitState,
        child: const Text('Try again'),
      ),
    );
```

Application-wide defaults are available as static callbacks:

```dart
AsyncState.defaultBuildWhenLoading =
    (context) => const Center(child: CircularProgressIndicator());
AsyncState.defaultBuildWhenError =
    (context) => const Center(child: Text('Something went wrong'));
```

For asynchronous setup that does not need a controller, extend `AsyncState`
directly and implement `asyncInitState`.

### Cancellation and isolates

An asynchronous factory may implement either marker interface:

- `AsyncFactoryIsCancellable`: its `cancel()` method is called if the widget
  is disposed before the controller is created.
- `AsyncFactoryIsIsolated`: `create()` runs in a separate isolate. If the
  widget is disposed first, that isolate is killed. The factory, parameter, result, and data they capture must obey Dart isolate sendability rules.

  WARNING: web doesn't supports Isolates.

```dart
class DataFactory
    implements
        AsyncFactory<DataController, DataView>,
        AsyncFactoryIsCancellable {
  bool _canceled = false;
  @override
  Future<DataController> create(DataView widget) async {
     ...
     if (!_canceled) {
        ...
     }
  }

  @override
  void cancel() {
    _canceled = true;
  }
}


class DataFactory
    implements
        AsyncFactory<DataController, DataView>,
        AsyncFactoryIsIsolated {

  @override
  Future<DataController> create(DataView widget) async {
     ...
  }
}

```

## Async errors

To capture async errors, assign the static `AsyncState.onError` callback:

```dart
AsyncState.onError = (error, stackTrace) {
  // Report the error to your logging service.
};
```

## Testing with mock controllers

Controller creation can be replaced without changing production widgets. Reset
the static callback in `tearDown` so it cannot leak into another test.

For `StateWithController`:

```dart
setUp(() {
  StateWithController.onMockingController = (widget) {
    if (widget is Counter) return FakeCounterController();
    return null; // Fall back to createController for other widgets.
  };
});

tearDown(() {
  StateWithController.onMockingController = null;
});
```

For asynchronous controllers, the callback may return either a controller or a
`Future`:

```dart
setUp(() {
  AsyncStateWithControllerParams.onMockingControllerParamsFactory =
      (factory, params) {
    if (factory is UsersControllerFactory) return FakeUsersController();
    return null; // Fall back to the real factory.
  };
});

tearDown(() {
  AsyncStateWithControllerParams.onMockingControllerParamsFactory = null;
});
```

These hooks are global, so avoid changing them concurrently from multiple
tests.

## API overview

| Type                                     | Purpose                                                                   |
| ---------------------------------------- | ------------------------------------------------------------------------- |
| `StateWithController`                    | Creates a synchronous controller for a `State`.                           |
| `AsyncState`                             | Runs asynchronous state initialization with loading, error, and retry UI. |
| `AsyncStateWithController`               | Creates an async controller using the widget as its factory parameter.    |
| `AsyncStateWithControllerParams`         | Creates an async controller from an explicit factory/parameter pair.      |
| `AsyncFactory`                           | Defines asynchronous controller creation.                                 |
| `AsyncFactoryIsCancellable`              | Adds cancellation while creation is in progress.                          |
| `AsyncFactoryIsIsolated`                 | Marks factory creation to run in a spawned isolate.                       |
| `Disposable`                             | Lets a controller release resources with its widget.                      |
| `AutoDisposeValueListenableBuilderMixin` | Provides `watch` and disposes watched notifiers.                          |

## Example

See the [`example`](example/) directory for complete synchronous and
asynchronous examples.

## License

This project is licensed under the terms in [MIT](LICENSE).
