import 'package:flutter/material.dart';
import 'package:state_controllers_sample/counter_widget.dart';
import 'package:state_controllers_sample/users_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'State Controller Demo',
      theme: ThemeData(),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('StateWithController'),
            CounterWidget(initialValue: 0),
            const SizedBox(height: 30),
            const Text('AsyncStateWithController'),
            SizedBox(
              height: 300,
              width: 100,
              child: UsersWidget(numUsers: 6, style: TextStyle(fontSize: 18)),
            ),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => _otherScreen()),
                );
              },
              child: Text('Go to another screen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _otherScreen() => Scaffold(
    body: Center(child: Text('Other screen', style: TextStyle(fontSize: 25))),
  );
}
