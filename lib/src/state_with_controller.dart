import 'package:flutter/widgets.dart';
import 'package:state_controllers/src/disposable.dart';

import 'auto_dispose_value_listenable_builder_mixin.dart';

/// [StatefulWidget] [State] that will use a controller.
/// The controller could be used by the [State] via [controller] property.
abstract class StateWithController<T extends StatefulWidget, U> extends State<T>
    with AutoDisposeValueListenableBuilderMixin {
  U? _controller;
  U get controller => _controller!;

  /// Return the controller.
  U createController();

  /// Allow to register a callback for mocking the controller
  /// creation.
  static dynamic Function(
    // ignore: avoid_annotating_with_dynamic
    dynamic params,
  )?
  onMockingController;

  @override
  @mustCallSuper
  void initState() {
    _controller = onMockingController?.call(widget) as U? ?? createController();
    super.initState();
  }

  /// Determine if the controller is created.
  bool isControllerCreated() => _controller != null;

  @override
  @mustCallSuper
  void dispose() {
    if (isControllerCreated() && (_controller is Disposable)) {
      (_controller! as Disposable).dispose();
    }
    super.dispose();
  }
}
