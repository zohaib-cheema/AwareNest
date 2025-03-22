import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
String first = 'Good day! How can I help you today?';
  void _handleSubmitted(String text) async {
    _controller.clear();

    // Define the URL
    final url = Uri.parse('https://ajstyles.site/chatbot');

    // Define the request body
    final Map<String, dynamic> data = {
      'input': text,
    };

    try {
      // Make the POST request
      final response = await http.post(
        url,
        body: jsonEncode(data),
        headers: {'Content-Type': 'application/json'},
      );

      // Check the response status code
      if (response.statusCode == 200) {
        // Request was successful, handle the response
        final responseData = jsonDecode(response.body);
        final botMessage = responseData['response'];
        setState(() {
          _messages.insert(0, ChatMessage(text: text, isUser: true));
          _messages.insert(0, ChatMessage(text: botMessage, isUser: false));
          _messages.insert(0, ChatMessage(text: 'Ask more', isUser: false));
        });
      } else {
        print('Request failed with status: ${response.statusCode}');
      }
    } catch (error) {
      // Handle any errors that occurred during the request
      print('Error: $error');
    }
  }

 @override
  void initState() {
    // TODO: implement initState
   setState(() {
     _messages.insert(0, ChatMessage(text: first, isUser: false));
   });
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ChatBot'),
      ),
      body: Column(
        children: <Widget>[
          Flexible(
            child: ListView.builder(
              padding: EdgeInsets.all(8.0),
              reverse: true,
              itemBuilder: (_, int index) => _messages[index],
              itemCount: _messages.length,
            ),
          ),
          Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).canvasColor),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: <Widget>[
            Flexible(
              child: TextField(
                controller: _controller,
                onSubmitted: _handleSubmitted,
                decoration: InputDecoration.collapsed(hintText: 'Send a message'),
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                icon: Icon(Icons.send,color: Colors.black,),
                onPressed: () => _handleSubmitted(_controller.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({Key? key, required this.text, required this.isUser}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          isUser ? SizedBox() : CircleAvatar(child: Icon(Icons.account_circle)),
          Expanded(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  isUser ? 'You' : 'Bot',
                  style: Theme.of(context).textTheme.subtitle2,
                ),
                Container(
                  margin: EdgeInsets.only(top: 5.0),
                  child: Text(text),
                ),
              ],
            ),
          ),
          isUser ? CircleAvatar(child: Icon(Icons.account_circle)) : SizedBox(),
        ],
      ),
    );
  }
}
