import 'package:flutter/material.dart';
import 'package:state_controller/state_controller.dart';
import 'counter_controller.dart';

class CounterWidget extends StatefulWidget {
  final Color? color;
  final int initialValue;
  const CounterWidget({required this.initialValue, this.color, super.key});

  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState
    extends StateWithController<CounterWidget, CounterController> {
  @override
  CounterController createController() => CounterController(widget);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        watch<int>(
          valueListenable: controller.counter,
          builder: (_, value, _) =>
              Text(value.toString(), style: TextStyle(color: widget.color)),
        ),
        FilledButton(
          onPressed: controller.onAddPressed,
          child: Icon(Icons.add),
        ),
      ],
    );
  }
}
