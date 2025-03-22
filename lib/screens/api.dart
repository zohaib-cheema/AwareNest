import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Api {
  final storage = FlutterSecureStorage();

  Future<void> signUp(BuildContext context, String username, String password,
      String email, String phone) async {
    final response = await http.post(
      Uri.parse('http://localhost:3000/signup'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'username': username,
        'password': password,
        'email': email,
        'phone': phone,
      }),
    );

    if (response.statusCode == 201) {
      print('User created successfully');
      // Navigate to next screen or show success message
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      print('Failed to create user. Error: ${response.body}');
      // Show error message to user
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Failed to create user. Please try again later.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> login(
      BuildContext context, String username, String password) async {
    final response = await http.post(
      Uri.parse('http://localhost:3000/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      print('Login successful');
      // Extract token from response
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      final String token = responseData['token'];
      saveToken(token);
      // Navigate to home screen or perform further actions with token
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      print('Failed to login. Error: ${response.body}');
      // Show error message to user
      showErrorDialog(
          context, 'Failed to login. Please check your credentials.');
    }
  }

  Future<void> getProtectedData(BuildContext context, String token) async {
    final response = await http.get(
      Uri.parse('http://localhost:3000/protected'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      print('Protected data received: ${response.body}');
      // Process protected data
    } else {
      print('Failed to get protected data. Error: ${response.body}');
      showErrorDialog(
          context, 'Failed to get protected data. Unauthorized access.');
      // Handle unauthorized access or other errors
    }
  }

  void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void saveToken(String token) async {
    await storage.write(key: 'token', value: token);
  }
}
