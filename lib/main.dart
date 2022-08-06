import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:mobx_state_management/state/app_state.dart';
import 'package:mobx_state_management/views/login_view.dart';
import 'package:mobx_state_management/views/register_view.dart';
import 'package:mobx_state_management/views/reminders_view.dart';
import 'package:provider/provider.dart';

import 'dialogs/show_auth_error.dart';
import 'firebase_options.dart';
import 'loading/loading_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    Provider(
      create: (_) => AppState(
       // authService: FirebaseAuthService(),
       // remindersService: FirestoreRemindersService(),
       // imageUploadService: FirebaseImageUploadService(),
      )..initialize(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ReactionBuilder(
        builder: (context) {
          return autorun(
            (_) {
              // handle loading screen
              final isLoading = context.read<AppState>().isLoading;
              if (isLoading) {
                LoadingScreen.instance().show(
                  context: context,
                  text: 'Loading...',
                );
              } else {
                LoadingScreen.instance().hide();
              }

              final authError = context.read<AppState>().authError;
              if (authError != null) {
                showAuthError(
                  authError: authError,
                  context: context,
                );
              }
            },
          );
        },
        child: Observer(
          name: "CurrentScreen",
          builder: (context) {
            switch (context.read<AppState>().currentScreen) {
              case AppScreen.login:
                return const LoginView();
              case AppScreen.register:
                return const RegisterView();
              case AppScreen.reminder:
                return const RemindersView();
            }
          },
        ),
      ),
    );
  }
}
