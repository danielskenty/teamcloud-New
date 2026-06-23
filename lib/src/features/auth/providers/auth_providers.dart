import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<User?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

class AuthStateListenable extends ChangeNotifier {
  AuthStateListenable(Stream<User?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<User?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final authStateListenableProvider = Provider<AuthStateListenable>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final listenable = AuthStateListenable(repository.authStateChanges);
  ref.onDispose(() {
    listenable.dispose();
  });
  return listenable;
});
