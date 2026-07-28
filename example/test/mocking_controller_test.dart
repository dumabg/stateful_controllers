import 'package:flutter_test/flutter_test.dart';
import 'package:stateful_controllers_sample/main.dart';
import 'package:stateful_controllers/src/async_state_with_controller.dart';
import 'package:stateful_controllers_sample/users_controller.dart';

class MockUsersController implements UsersController {
  @override
  List<String> get users => ['Solo 1'];

  @override
  void dispose() {}
}

void main() {
  tearDown(() {
    AsyncStateWithControllerParams.onMockingControllerParamsFactory = null;
  });
  testWidgets('not mocking', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    await tester.runAsync(() async {
      await Future.delayed(const Duration(seconds: 5));
    });
    await tester.pumpAndSettle();
    expect(find.text('user1'), findsOneWidget);
    expect(find.text('user2'), findsOneWidget);
    expect(find.text('user3'), findsOneWidget);
  });

  testWidgets('onMockingControllerParamsFactory', (WidgetTester tester) async {
    AsyncStateWithControllerParams.onMockingControllerParamsFactory =
        (controllerFactory, params) {
          return switch (controllerFactory) {
            UsersControllerFactory() => MockUsersController(),
            _ => null,
          };
        };
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();
    expect(find.text('Solo 1'), findsOneWidget);
  });
}
