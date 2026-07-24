import 'package:flutter/foundation.dart';
import 'package:state_controller_sample/counter_widget.dart';

class CounterController {
  final ValueNotifier<int> counter;

  CounterController(CounterWidget widget)
    : counter = ValueNotifier<int>(widget.initialValue);

  void onAddPressed() {
    counter.value = counter.value + 1;
  }
}
