import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Indicates whether a live Firebase project is configured and initialized.
/// When false (e.g., before `flutterfire configure`), the app seamlessly uses
/// offline-first local state so all features can be tested immediately.
final isFirebaseInitializedProvider = StateProvider<bool>((ref) => false);

/// Provides the root [FirebaseFirestore] instance when Firebase is initialized.
final firestoreProvider = Provider<FirebaseFirestore?>((ref) {
  final isReady = ref.watch(isFirebaseInitializedProvider);
  if (!isReady) return null;
  return FirebaseFirestore.instance;
});

/// Initializes Firebase and configures Cloud Firestore for offline persistence
/// across Mobile and Web. Falls back gracefully if FirebaseOptions are not yet configured.
Future<bool> initOfflineFirebase() async {
  try {
    await Firebase.initializeApp();
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    return true;
  } catch (_) {
    // Firebase options not provided yet; app runs in local offline-first mode.
    return false;
  }
}
