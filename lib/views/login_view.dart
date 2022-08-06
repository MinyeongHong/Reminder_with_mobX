import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../state/app_state.dart';
import 'package:provider/provider.dart';

class LoginView extends HookWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();


    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),

      ),
      body: Column(
        children: [
          TextField(
            controller: emailController,
            decoration: const InputDecoration(
              hintText: 'Enter your email here...',
            ),
            keyboardType: TextInputType.emailAddress,
            keyboardAppearance: Brightness.dark,
          ),
          TextField(
            controller: passwordController,
            decoration: const InputDecoration(
              hintText: 'Enter your password here...',
            ),
            keyboardAppearance: Brightness.dark,
            obscureText: true,
            obscuringCharacter: '◉',
          ),
          TextButton(
            onPressed: () {
              final email = emailController.text;
              final password = passwordController.text;
              context.read<AppState>().login(
                email: email,
                password: password,
              );
            },
            child: const Text(
              'Log in',
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<AppState>().goTo(
                AppScreen.register,
              );
            },
            child: const Text(
              'Not registered yet? Register here!',
            ),
          )
        ],
      ),
    );
  }
}
