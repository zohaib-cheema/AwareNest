import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lsd/screens/dashboard.dart';
import 'package:lsd/screens/signUp.dart' show SignUpScreen;
import 'package:lsd/screens/temp.dart';

import 'home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  void togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void navigateToForgetPassword() {
    // navigation logic here
  }

  void navigateToSignUp() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SignUp(),
      ),
    );
  }

  void _loginUser(String email, String password) async {
    try {
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Handle successful login (optional)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login successful!'),
          duration: Duration(seconds: 3),
        ),
      );

      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      )); // Example navigation
    } on FirebaseAuthException catch (error) {
      String message = 'An error occurred during login. $error';
      switch (error.code) {
        case 'user-not-found':
          message = 'The email address is not associated with an account.';
          break;
        case 'wrong-password':
          message = 'The password is invalid.';
          break;
        case 'invalid-email':
          message = 'The email address is invalid.';
          break;
        default:
          // Handle other potential errors gracefully
          break;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (error) {
      // Handle unexpected errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred. Please try again.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(246, 246, 246, 10),
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            _ImageWidget(),
            _EmailInputWidget(
              controller: _emailController,
            ),
            _PasswordInputWidget(
              controller: _passwordController,
              isPasswordVisible: _isPasswordVisible,
              onTogglePasswordVisibility: togglePasswordVisibility,
            ),
            _ForgetPasswordButton(
              onPressed: navigateToForgetPassword,
            ),
            _LoginButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  _loginUser(_emailController.text, _passwordController.text);
                }
              },
            ),
            // _OrSeparator(),
            // _GoogleButton(),
            // _CustomDivider(),
            _SignUpButton(),
          ],
        ),
      ),
    );
  }
}

class _ImageWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      "assets/images/image.png",
      height: MediaQuery.of(context).size.height * 0.5,
      width: MediaQuery.of(context).size.width * 0.8,
      fit: BoxFit.fitHeight,
    );
  }
}

class _EmailInputWidget extends StatelessWidget {
  final TextEditingController controller;

  _EmailInputWidget({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          icon: const Icon(
            Icons.face,
            color: Color.fromRGBO(187, 187, 187, 1),
          ),
          labelStyle: const TextStyle(
            fontFamily: 'Nunito Sans',
            color: Color.fromRGBO(187, 187, 187, 1),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: const BorderSide(),
          ),
          labelText: "Username / Phone number / Email Address",
        ),
        validator: (value) {
          if (value!.isEmpty ||
              !RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                  .hasMatch(value)) {
            return 'Enter a valid email!';
          }
          return null;
        },
      ),
    );
  }
}

class _PasswordInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final bool isPasswordVisible;
  final VoidCallback onTogglePasswordVisibility;

  _PasswordInputWidget({
    required this.controller,
    required this.isPasswordVisible,
    required this.onTogglePasswordVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: TextFormField(
        controller: controller,
        obscureText: !isPasswordVisible,
        decoration: InputDecoration(
          labelText: "Password",
          icon: const Icon(Icons.lock),
          suffixIcon: IconButton(
            onPressed: onTogglePasswordVisibility,
            icon: Icon(
              isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            ),
          ),
          labelStyle: const TextStyle(
            fontFamily: 'Nunito Sans',
            color: Color.fromRGBO(187, 187, 187, 1),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: const BorderSide(),
          ),
        ),
      ),
    );
  }
}

class _ForgetPasswordButton extends StatelessWidget {
  final VoidCallback onPressed;

  _ForgetPasswordButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Container(
        alignment: Alignment.topRight,
        child: const Text(
          "Forget Password",
          style: TextStyle(
            color: Color.fromRGBO(165, 165, 165, 1),
            // decoration: TextDecoration.underline
          ),
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  final VoidCallback onPressed;

  _LoginButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: SizedBox(
        height: size.height * 0.05,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(36, 92, 102, 1),
            textStyle: const TextStyle(
              fontSize: 10,
              fontFamily: 'Nunito Sans',
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text(
            "Login",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color.fromRGBO(255, 255, 255, 1),
              fontSize: 16.0,
              fontStyle: FontStyle.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrSeparator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _CustomDivider(),
        const Text(
          "Or",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color.fromRGBO(172, 172, 172, 1),
            fontSize: 12,
            fontFamily: 'Nunito Sans',
            height: 0.14,
          ),
        ),
        _CustomDivider(),
      ],
    );
  }
}

class _CustomDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Row(children: [
      Expanded(
          child: Divider(
        indent: 15.0,
        endIndent: 10.0,
        thickness: 1,
      )),
      Text(
        "Don't have an account yet ?",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color.fromRGBO(172, 172, 172, 1),
          fontSize: 12,
          fontFamily: 'Nunito Sans',
          height: 0.14,
        ),
      ),
      Expanded(
          child: Divider(
        indent: 10.0,
        endIndent: 28.0,
        thickness: 1,
      )),
    ]);
  }
}

class _GoogleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Padding(
      padding: EdgeInsets.fromLTRB(size.width * 0.3, 0, size.width * 0.3, 0),
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          backgroundColor: const Color.fromRGBO(255, 255, 255, 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Row(
          children: [
            Icon(
              FontAwesomeIcons.google,
              color: Color.fromRGBO(105, 105, 105, 1),
            ),
            SizedBox(
              width: 10,
            ),
            Text(
              "Google",
              style: TextStyle(
                color: Color.fromRGBO(105, 105, 105, 1),
                fontFamily: "Nunito Sans",
                fontSize: 16.0,
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _SignUpButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => Dashboard(),
          ),
        );
      },
      child: const Text(
        "Sign up",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: "Nunito Sans",
          color: Color.fromRGBO(100, 100, 100, 1),
        ),
      ),
    );
  }
}
