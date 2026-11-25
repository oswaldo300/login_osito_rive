import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rive/rive.dart';

import 'firebase_options.dart';
import 'screens/LoginScreen.dart';
import 'screens/products_screen.dart';

final ValueNotifier<bool> isPlayingLoginSuccess = ValueNotifier(false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await RiveFile.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Osito Firebase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isPlayingLoginSuccess,
      builder: (context, playingAnim, _) {
        return StreamBuilder<User?>(
          initialData: FirebaseAuth.instance.currentUser,
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            // Después del login, la app muestra los productos de Spring
            // Boot. Al cerrar sesión, el stream emite null y se vuelve
            // a la pantalla de login automáticamente.
            if (snapshot.hasData && !playingAnim) {
              return const ProductsScreen();
            }
            return const LoginScreen();
          },
        );
      },
    );
  }
}
