import 'package:flutter/material.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/services/auth/auth_exceptions.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/utilities/dialogs/error_dialog.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterView();
}

class _RegisterView extends State<RegisterView> {
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
      appBar: AppBar(title: const Text('Register View')),
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
                      await AuthService.firebase().createUser(
                        email: email, 
                        password: password
                      );
                      
                      final user = AuthService.firebase().currentUser;
                      AuthService.firebase().sendEmailVerification();

                      Navigator.of(context).pushNamed(verifyEmailRoute); 
 
                    } on UserNotLoggedInAuthException {
                      showErrorDialog(context, 'User not logged in');
                    } on WeakPasswordAuthException {
                      showErrorDialog(context, 'Use a stronger password');
                    } on EmailAlreadyExistsAuthException {
                      showErrorDialog(context, 'An account already exists with that email');
                    } on InvalidEmailAuthException {
                      showErrorDialog(context, 'Please enter a valid email');
                    } on GenericAuthException {
                      showErrorDialog(context, 'Something bad happened');
                    } catch (e) {
                      showErrorDialog(context, 'Error: ${e.toString()}');
                    }
                    
                    
                  }, 
                  child: const Text('Register')
                ),
                TextButton(
                  onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    loginRoute,
                    (route) => false
                  );
                }, 
                  child: const Text('Already registed? Login here'))
            ],
          ),
    );
  }
}