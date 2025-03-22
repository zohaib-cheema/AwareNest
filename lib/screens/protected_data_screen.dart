import 'package:flutter/material.dart';
import 'package:lsd/screens/api.dart';

class ProtectedDataScreen extends StatelessWidget {
  final String token; // Assuming token is passed to this screen

  final Api api = Api();

  ProtectedDataScreen(this.token);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Protected Data'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            api.getProtectedData(context, token);
          },
          child: Text('Get Protected Data'),
        ),
      ),
    );
  }
}
