import 'package:flutter/material.dart';

/// Support for tracking ValueNotifiers using the [watch] method.
/// All the ValueNotifiers tracked are disposed when the widget
/// is disposed.
mixin AutoDisposeValueListenableBuilderMixin<T extends StatefulWidget>
    on State<T> {
  final Set<ChangeNotifier> _trackedNotifiers = {};

  /// Creates a ValueListenableBuilder for auto disposing.
  Widget watch<V>({
    required ValueNotifier<V> valueListenable,
    required Widget Function(BuildContext context, V value, Widget? child)
    builder,
    Widget? child,
  }) {
    _trackedNotifiers.add(valueListenable);

    return ValueListenableBuilder<V>(
      valueListenable: valueListenable,
      builder: builder,
      child: child,
    );
  }

  @override
  void dispose() {
    for (final notifier in _trackedNotifiers) {
      notifier.dispose();
    }
    _trackedNotifiers.clear();
    super.dispose();
  }
}
