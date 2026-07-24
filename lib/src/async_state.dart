import 'dart:async';
import 'package:flutter/material.dart';

import 'auto_dispose_value_listenable_builder_mixin.dart';

/// Define the [StatefulWidget] [State] like async. Build phase is done with a
/// FutureBuilder than calls the method asyncInitState for launch all Futures
/// needs for this State. In this phase the build is doing in the
/// buildWhenLoading method. By default, it shows a LoadingIndicator.
///
/// When asyncInitState is done, it examines the Future result. If all is ok,
/// the buildWhenDone is called. If an error occurs, buildWhenError is called.
/// By default, buildWhenError shows in the middle a red replay icon, that can
/// touch to retry.
abstract class AsyncState<T extends StatefulWidget> extends State<T>
    with AutoDisposeValueListenableBuilderMixin {
  bool _futureDone = false;

  /// Allows initialize the [State] with async calls.
  Future<void> asyncInitState();

  /// Build method when the [State] are initialized correctly with
  /// [asyncInitState]
  Widget buildWhenDone(BuildContext context);

  /// Register onError callback when error occurs in async calls.
  static void Function(Object error, StackTrace? stack)? onError;

  /// Register the default buildWhenError.
  static Widget Function(BuildContext context)? defaultBuildWhenError;

  /// Register the default buildWhenLoading.
  static Widget Function(BuildContext context)? defaultBuildWhenLoading;

  Completer<void>? _asyncInitStateCompleter;

  @override
  void initState() {
    _asyncInitState();
    super.initState();
  }

  void _asyncInitState() {
    _asyncInitStateCompleter = Completer<void>();
    unawaited(
      asyncInitState().then(
        (_) => _asyncInitStateCompleter!.complete(),
        onError: (Object err, StackTrace? stack) =>
            _asyncInitStateCompleter!.completeError(err, stack),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _futureDone
      ? buildWhenDone(context)
      : FutureBuilder(
          future: _asyncInitStateCompleter?.future,
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.done:
                _asyncInitStateCompleter = null;
                if (snapshot.hasError) {
                  _futureDone = false;
                  onError?.call(snapshot.error!, snapshot.stackTrace);
                  return buildWhenError(context);
                } else {
                  _futureDone = true;
                  return buildWhenDone(context);
                }
              default:
                return buildWhenLoading(context);
            }
          },
        );

  /// Build method when are waiting for the end of [asyncInitState].
  Widget buildWhenLoading(BuildContext context) =>
      defaultBuildWhenLoading?.call(context) ??
      Center(
        child: SizedBox(
          width: 50,
          height: 50,
          child: const CircularProgressIndicator(),
        ),
      );

  /// Retry asyncInitState only if the previous call to asyncInitState is
  /// completed. This method is called after pressing retry button on default
  /// [buildWhenError].
  void retryAsyncInitState() {
    if (_asyncInitStateCompleter == null) {
      setState(_asyncInitState);
    }
  }

  /// Build method when [asyncInitState] ends with and error. It shows in
  /// the middle a red replay icon, that can touch to retry.
  Widget buildWhenError(BuildContext context) {
    return defaultBuildWhenError?.call(context) ??
        SizedBox.expand(
          child: Center(
            child: IconButton(
              icon: const Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Icon(Icons.replay, color: Colors.white, size: 42),
                  ),
                ],
              ),
              onPressed: retryAsyncInitState,
            ),
          ),
        );
  }
}
