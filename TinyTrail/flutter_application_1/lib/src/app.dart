import 'package:flutter/material.dart';

import 'auth.dart';
import 'bootstrap.dart';
import 'shared.dart';
import 'splash.dart';

class TinyTrailApp extends StatefulWidget {
  const TinyTrailApp({
    super.key,
    required this.bootstrapState,
  });

  final BootstrapState bootstrapState;

  @override
  State<TinyTrailApp> createState() => _TinyTrailAppState();
}

class _TinyTrailAppState extends State<TinyTrailApp> {
  AppMode mode = AppMode.customer;
  bool showSplash = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TinyTrail',
      theme: buildTheme(mode),
      home: !widget.bootstrapState.firebaseReady
          ? FirebaseSetupScreen(error: widget.bootstrapState.firebaseError)
          : showSplash
              ? TinyTrailSplash(
                  onComplete: () => setState(() => showSplash = false),
                )
              : AuthGate(
                  mode: mode,
                  onModeChanged: (value) => setState(() => mode = value),
                ),
    );
  }
}
