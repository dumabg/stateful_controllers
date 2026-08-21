# `stateful_controllers`

`stateful_controllers` separates Flutter UI from mutable application logic:

- Keep widgets and their `State` classes focused on rendering and immutable widget configuration.
- Put actions, mutable state, and resource ownership in a controller.
- Every `StatefulWidget` with state must have a controller.
- Do not use `setState` in application widget states. Use `ValueNotifier` fields on the controller and rebuild the affected UI with `watch`.
- Do not create `Dialog`s, `SnackBar`s, or other UI in a controller. The state owns the UI; the controller may request an action through a widget-exposed method.
- A controller must not import presentation-only Flutter APIs such as `material.dart` unless it needs. Prefer `foundation.dart` for `ValueNotifier`.
- Import the library through its public entrypoint:

```dart
import 'package:stateful_controllers/stateful_controllers.dart';
```

Do not import files from `package:stateful_controllers/src/...`; they are internal implementation details.

- The controller must be ALWAYS in another file.

## How to use it
- Determine if the widget needs async data to be ready. For example, the widget shows a list of products that needs to load from server. The widget is only ready when the products are loaded.

- If needs async data, do the 'async controller steps' else do the 'controller steps'.

### Async controller steps
- Create a file that contains the controller and the controller factory.
    - Create the file in the same directory than the widget file.
    - Naming rules:
      - Get the name of the widget without Widget. Example: UsersWidget resolves to Users. UsersView resolves to usersView.
      - Controller name = resolved name + "Controller". Example: UsersController, UsersViewController.
      - Controller factory name = resolved name + "Factory". Example: UsersFactory, UsersViewFactory.
      - File name = controller name. Example: users_controller.dart, users_views_controller.dart.
    
- Create the controller factory:
  - implements AsyncFactory<Controller, Widget>
  - override Future<Controller> create(Widget widget) async.
    - Load the data needed for the controller to be ready.
    - return the controller.
    
- Create the controller:
  - The constructor receives the data needed to be ready.
  
- Create the State of the widget:
  - extends the State with AsyncStateWithController<Widget, Controller>.
  - override AsyncFactory<Controller, Widget> get controllerFactory.
  - override Widget buildWhenDone(BuildContext context).
  - DOESN'T override buildWhenLoading nor buildWhenError. Only if it is explicity named.
  - use controller field to access controller data.
  
Example:
   
users_controller.dart:
 
```dart
class UsersFactory implements AsyncFactory<UsersController, UsersWidget> {
  Future<UsersController> create(UsersWidget widget) async {
  @override
    final users = await loadUsers(widget.limit);
    return UsersController(users);
  }
}

class UsersController {
  final List<String> users;
  
  UsersController(this.users);
}

```

users_widget.dart:

```dart
class UsersWidget extends StatefulWidget {
  final int limit;
  const UsersWidget({required this.limit, super.key});

  @override
  State<UsersWidget> createState() => _UsersWidgetState();
}

class _UsersWidgetState
    extends AsyncStateWithController<UsersWidget, UsersController> {
  @override
  AsyncFactory<UsersController, UsersWidget> get controllerFactory =>
      UsersFactory();

  @override
  Widget buildWhenDone(BuildContext context) => Text('${controller.users}');
}
```

#### Cancellation and isolate work

- Implement `AsyncFactoryIsCancellable` on factory when initialization can be canceled. Its `cancel()` method is called if the widget is disposed before the controller is ready.

- Implement `AsyncFactoryIsIsolated` when `create()` should run in a separate Dart isolate. The factory, parameter, result, and captured data must all be sendable across isolates.

### Controller steps
- Create a file that contains the controller. 
    - Create the file in the same directory than the widget file.
    - Naming rules:
      - Get the name of the widget without Widget. Example: UsersWidget resolves to Users. UsersView resolves to usersView.
      - Controller name = resolved name + "Controller". Example: UsersController, UsersViewController.
      - File name = controller name. Example: users_controller.dart, users_views_controller.dart.
        
- Create the State of the widget:
  - extends the State with StateWithController<Widget, Controller>.
  - override Controller createController().
  - use controller field to access controller data.

Example:

counter_controller.dart:

```dart
class CounterController {
  CounterController(int initialValue) : count = ValueNotifier(initialValue);

  final ValueNotifier<int> count;

  void increment() => count.value++;
}

```

counter_widget.dart:

```dart
class CounterWidget extends StatefulWidget {
  final int initialValue;
  
  const CounterWidget({required this.initialValue, super.key});

  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState
    extends StateWithController<CounterWidget, CounterController> {
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
