import "package:flutter/material.dart";
import "package:mynotes/constants/routes.dart";
import "package:mynotes/services/auth/auth_exceptions.dart";
import "package:mynotes/services/auth/auth_service.dart";
import "package:mynotes/utilities/error_dialog.dart";


class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _email;
  late final TextEditingController _password;

  
  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
            children: [
              TextField(
                controller: _email,
                enableSuggestions: false,
                autocorrect: false,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Enter your email here',
                ),
              ),
              TextField(
                controller: _password,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                decoration: const InputDecoration(
                  hintText: 'Enter your password here',
                )
              ),
              TextButton(
                  onPressed: () async {
                    final email = _email.text;
                    final password = _password.text;
                  try {
                    await AuthService.firebase().logIn(email: email, password: password);
                    
                    final user = AuthService.firebase().currentUser;
                    if (user?.isEmailVerified ?? false) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                      notesRoute, 
                      (route) => false);
                    } else {
                      Navigator.of(context).pushNamed(verifyEmailRoute);
                    }
                    
                  } on UserNotFoundAuthException {
                    await showErrorDialog(context, 'User not found');
                  } on InvalidCredentialsAuthException {
                    await showErrorDialog(context, 'Invalid credentials');
                  } on GenericAuthException {
                    await showErrorDialog(context, 'Something weird happened');
                  } catch (e) {
                    await showErrorDialog(context, 'Something weird happened');
                  }
                  }, 
                  child: const Text('Login')
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      registerRoute,
                      (route) => false
                    );
                  }, 
                  child: const Text('Not registered yet?'),
                )
            ],
          ),
    );

  }
}

Future<bool> showLogOutDialog(BuildContext context) {
  return showDialog(
    context: context, 
    builder: (context) {
      return AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () {Navigator.of(context).pop(false);}, child: const Text('Cancel')),
          TextButton(onPressed: () {Navigator.of(context).pop(true);}, child: const Text('Logout')),
        ]
      );
    },
  ).then((value) => value ?? false);
}

