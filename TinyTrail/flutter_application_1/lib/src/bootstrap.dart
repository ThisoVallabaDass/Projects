import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

class BootstrapState {
  const BootstrapState({
    required this.firebaseReady,
    this.firebaseError,
  });

  final bool firebaseReady;
  final String? firebaseError;
}

Future<BootstrapState> initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return const BootstrapState(firebaseReady: true);
  } catch (error) {
    return BootstrapState(
      firebaseReady: false,
      firebaseError: error.toString(),
    );
  }
}
