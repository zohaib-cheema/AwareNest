import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isPasswordVisible = false;

  void togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _signUpUser(String username, String email, String password) async {
    try {
      if (username.isEmpty || email.isEmpty || password.isEmpty) {
        throw Exception('Please fill in all fields.');
      }

      if (!RegExp(
              r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$")
          .hasMatch(email)) {
        throw Exception('Please enter a valid email address.');
      }
      final response =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print(response);
      // 4. Handle successful signup (optional)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign up successful!'),
          duration: Duration(seconds: 3),
        ),
      );

      // Navigator.of(context).pushReplacementNamed('/home');
    } on FirebaseAuthException catch (error) {
      print(error);
      String message = 'An error occurred during sign up.  $error';
      switch (error.code) {
        case 'weak-password':
          message = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          message = 'The email address is already in use by another account.';
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

// ElevatedButton(
//   onPressed: () {
//     if (_form.currentState!.validate()) {
//       _form.currentState!.save();
//       _signUpUser(
//         _fullname.text,
//         _emailaddress.text,
//         _password.text,
//       );
//     }
//   },
//   child: Text('SignUp'),
// ),

//   void navigateToForgetPassword() {
//     //navigation logic here
//   }
  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.sizeOf(context);
    var Width = screenSize.width;
    var Height = screenSize.height;
    return Scaffold(
      body: Form(
        key: _formKey,
        child: ListView(
          // padding: EdgeInsets.all(16.0), // Add padding if desired
          children: [
            Image.asset(
              "assets/images/image.png",
              height: Height * 0.5,
              width: Width * 0.8,
              fit: BoxFit.fitHeight,
            ),
            SizedBox(
              height: Height * 0.01,
            ),
            ListTile(
              title: TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(labelText: 'Full Name'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Full Name cannot be empty!';
                  }
                  return null;
                },
              ),
            ),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
              ),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
              obscureText: _isPasswordVisible,
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Password cannot be empty!';
                }
                return null;
              },
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
              obscureText: !_isPasswordVisible,
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Confirm Password cannot be empty!';
                } else if (value != _passwordController.text) {
                  return 'Passwords do not match!';
                }
                return null;
              },
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _signUpUser(
                    _fullNameController.text,
                    _emailController
                        .text, // Assuming you have an email controller
                    _passwordController.text,
                  );
                }
              },
              child: Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
//   @override
//   Widget build(BuildContext context) {
//     var screenSize = MediaQuery.sizeOf(context);
//     var Width = screenSize.width;
//     var Height = screenSize.height;
//     return Scaffold(
//       backgroundColor: const Color.fromRGBO(246, 246, 246, 10),
//       body: Form(
//         key: _form,
//         child: ListView(children: [
//           Image.asset(
//             "assets/images/image.png",
//             height: Height * 0.5,
//             width: Width * 0.8,
//             fit: BoxFit.fitHeight,
//           ),
//           SizedBox(
//             height: Height * 0.01,
//           ),
//           ListTile(
//             title: TextFormField(
//               keyboardType: TextInputType.emailAddress,
//               controller: _fullname,
//               decoration: InputDecoration(
//                 icon: const Icon(
//                   Icons.face,
//                   color: Color.fromRGBO(187, 187, 187, 1),
//                 ),
//                 labelStyle: const TextStyle(
//                   fontFamily: 'Nunito Sans',
//                   color: Color.fromRGBO(187, 187, 187, 1),
//                 ),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(30.0),
//                   borderSide: const BorderSide(),
//                 ),
//                 labelText: "Full Name",
//               ),
//               onSaved: (value) {
//                 setState(() {
//                   fullname = value!;
//                 });
//               },
//             ),
//           ),
//           SizedBox(
//             height: Height * 0.01,
//           ),
//           ListTile(
//             title: TextFormField(
//               keyboardType: TextInputType.emailAddress,
//               controller: _emailaddress,
//               decoration: InputDecoration(
//                 icon: const Icon(
//                   Icons.face,
//                   color: Color.fromRGBO(187, 187, 187, 1),
//                 ),
//                 labelStyle: const TextStyle(
//                   fontFamily: 'Nunito Sans',
//                   color: Color.fromRGBO(187, 187, 187, 1),
//                 ),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(30.0),
//                   borderSide: const BorderSide(),
//                 ),
//                 labelText: "Username / Phone number / Email Address",
//               ),
//               validator: (value) {
//                 if (value!.isEmpty ||
//                     !RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
//                         .hasMatch(value)) {
//                   return 'Enter a valid email!';
//                 }
//                 return null;
//               },
//               onSaved: (value) {
//                 setState(() {
//                   email = value!;
//                 });
//               },
//             ),
//           ),
//           // TextFormField(
//           //   decoration: const InputDecoration(
//           //     icon: Icon(
//           //       Icons.face,
//           //       color: Color.fromRGBO(187, 187, 187, 1),
//           //     ),
//           //     labelStyle: TextStyle(
//           //       fontFamily: 'Nunito Sans',
//           //       color: Color.fromRGBO(187, 187, 187, 1),
//           //     ),
//           //     border: InputBorder.none,
//           //     labelText: "Username / Phone number",
//           //   ),
//           // ),
//           SizedBox(
//             height: Height * 0.01,
//           ),
//           ListTile(
//             title: TextFormField(
//               keyboardType: TextInputType.emailAddress,
//               controller: _password,
//               obscureText: true,
//               decoration: InputDecoration(
//                 labelText: "Password",
//                 icon: const Icon(Icons.lock),
//                 suffixIcon: IconButton(
//                     onPressed: tooglePasswordVisibility,
//                     icon: Icon(_isPasswordVisible
//                         ? Icons.visibility
//                         : Icons.visibility_off)),
//                 labelStyle: const TextStyle(
//                   fontFamily: 'Nunito Sans',
//                   color: Color.fromRGBO(187, 187, 187, 1),
//                 ),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(30.0),
//                   borderSide: const BorderSide(),
//                 ),
//               ),
//               onSaved: (value) {
//                 setState(() {
//                   password = value!;
//                 });
//               },
//             ),
//           ),
//           // TextFormField(
//           //   decoration: InputDecoration(
//           //     icon: const Icon(Icons.lock),
//           //     suffixIcon: IconButton(
//           //         onPressed: tooglePasswordVisibility,
//           //         icon: Icon(_isPasswordVisible
//           //             ? Icons.visibility
//           //             : Icons.visibility_off)),
//           //     // suffixIcon: Row(
//           //     //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           //     //   mainAxisSize: MainAxisSize.min,
//           //     //   children: <Widget>[
//           //     //     IconButton(icon: Icon(Icons.clear)),
//           //     //     IconButton(onPressed: _authBloc.switchObscureTextMode, icon: Icon(snapshot.data ? Icons.visibility: Icons.visibility_off))

//           //     //   ],
//           //     // ) Icon(
//           //     //   Icons.password,

//           //     //   color: Color.fromRGBO(187, 187, 187, 1),
//           //     // ),
//           //     labelStyle: const TextStyle(
//           //       fontFamily: 'Nunito Sans',
//           //       color: Color.fromRGBO(187, 187, 187, 1),
//           //     ),
//           //     border: InputBorder.none,
//           //     labelText: "Password",
//           //   ),
//           // ),
//           SizedBox(
//             height: Height * 0.005,
//           ),
//           TextButton(
//             onPressed: () {
//               navigateToForgetPassword();
//             },
//             child: Container(
//               alignment: Alignment.topRight,
//               child: const Text(
//                 "Forget Password",
//                 style: TextStyle(
//                   color: Color.fromRGBO(165, 165, 165, 1),
//                   // decoration: TextDecoration.underline
//                 ),
//               ),
//             ),
//           ),
//           // GestureDetector(
//           //   onDoubleTap: navigateToForgetPassword,
//           //   child: Container(
//           //     width: Width * 0.8,
//           //     child: const Text(
//           //       "Forget Password",
//           //       style: TextStyle(
//           //         color: Color.fromRGBO(165, 165, 165, 1),
//           //         //decoration: TextDecoration.underline
//           //       ),
//           //     ),
//           //   ),
//           // ),
//           const SizedBox(
//             height: 5,
//           ),
//           /* 

//           ritika ye refence code for backend
          
//           */
//           // ElevatedButton(
//           //     onPressed: () async {
//           //       if (_form.currentState!.validate()) {
//           //         _form.currentState!.save();
//           //         login
//           //             ? AuthServices.signinUser(email, password, context)
//           //             : AuthServices.signupUser(
//           //                 email, password, fullname, context);
//           //       }
//           //     },
//           //     child: Text('Login')),

//           Padding(
//             padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
//             child: SizedBox(
//               height: Height * 0.05,
//               child: ElevatedButton(
//                 onPressed: () {
//                   //yaha aayega code
//                 },
//                 style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color.fromRGBO(36, 92, 102, 1),
//                     textStyle: const TextStyle(
//                       //backgroundColor: Color.fromARGB(255, 248, 245, 245),
//                       fontSize: 10,
//                       fontFamily: 'Nunito Sans',
//                     ),
//                     shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(20))),
//                 child: const Text(
//                   "SignUp",
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     color: Color.fromRGBO(255, 255, 255, 1),
//                     fontSize: 16.0,
//                     fontStyle: FontStyle.normal,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(
//             height: 5,
//           ),
//           const Row(children: [
//             Expanded(
//                 child: Divider(
//               indent: 15.0,
//               endIndent: 10.0,
//               thickness: 1,
//             )),
//             Text(
//               'Already have an account?',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: Color(0xFFACACAC),
//                 fontSize: 12,
//                 fontFamily: 'Nunito Sans',
//                 fontWeight: FontWeight.w600,
//                 height: 0.14,
//               ),
//             ),
//             Expanded(
//                 child: Divider(
//               indent: 10.0,
//               endIndent: 20.0,
//               thickness: 1,
//             )),
//           ]),
//           const SizedBox(
//             height: 5,
//           ),
//           TextButton(
//             onPressed: () => Navigator.of(context).push(
//               MaterialPageRoute(
//                 builder: (context) => LoginScreen(),
//               ),
//             ),
//             child: const Text(
//               "Log In",
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                   fontFamily: "Nunito Sans",
//                   color: Color.fromRGBO(100, 100, 100, 1)),
//             ),
//           ),

//           const SizedBox(
//             height: 8,
//           ),
//           const Row(children: <Widget>[
//             Expanded(
//                 child: Divider(
//               indent: 15.0,
//               endIndent: 10.0,
//               thickness: 1,
//             )),
//             Text(
//               "Or",
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: Color.fromRGBO(172, 172, 172, 1),
//                 fontSize: 12,
//                 fontFamily: 'Nunito Sans',
//                 height: 0.14,
//               ),
//             ),
//             Expanded(
//                 child: Divider(
//               indent: 10.0,
//               endIndent: 28.0,
//               thickness: 1,
//             )),
//           ]),
//           const SizedBox(
//             height: 4,
//           ),

//           Padding(
//             padding: EdgeInsets.fromLTRB(Width * 0.3, 0, Width * 0.3, 0),
//             child: ElevatedButton(
//                 onPressed: () {
//                   // add code for google account adition
//                 },
//                 style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
//                     backgroundColor: const Color.fromRGBO(255, 255, 255, 1),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(20),

//                       //side: BorderSide(color: Color.fromARGB(a, r, g, b))
//                     )),
//                 child: const Row(
//                   children: [
//                     Icon(
//                       FontAwesomeIcons.google,
//                       color: Color.fromRGBO(105, 105, 105, 1),
//                     ),
//                     SizedBox(
//                       width: 10,
//                     ),
//                     Text(
//                       "Google",
//                       style: TextStyle(
//                         color: Color.fromRGBO(105, 105, 105, 1),
//                         fontFamily: "Nunito Sans",
//                         fontSize: 16.0,
//                       ),
//                     )
//                   ],
//                 )),
//           ),
//           const SizedBox(
//             height: 4,
//           ),
//         ]),
//       ),
//     );
//   }
// }
// class SignUpScreen extends StatelessWidget {
//   final TextEditingController usernameController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController phoneController = TextEditingController();

//   final Api api = Api();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Sign Up'),
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: <Widget>[
//             TextField(
//               controller: usernameController,
//               decoration: InputDecoration(labelText: 'Username'),
//             ),
//             TextField(
//               controller: passwordController,
//               decoration: InputDecoration(labelText: 'Password'),
//               obscureText: true,
//             ),
//             TextField(
//               controller: emailController,
//               decoration: InputDecoration(labelText: 'Email'),
//             ),
//             TextField(
//               controller: phoneController,
//               decoration: InputDecoration(labelText: 'Phone'),
//             ),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () {
//                 api.signUp(
//                   context,
//                   usernameController.text,
//                   passwordController.text,
//                   emailController.text,
//                   phoneController.text,
//                 );
//               },
//               child: Text('Sign Up'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
