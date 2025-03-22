import 'package:flutter/material.dart';

class Notifications extends StatefulWidget {
  const Notifications({Key? key}) : super(key: key);

  @override
  _NotificationsState createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  bool notification1Selected = false;
  bool notification2Selected = false;
  bool notification3Selected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: Column(
        children: [
          _buildNotificationContainer(
            'How are you feeling today?',
            notification1Selected,
            (value) {
              setState(() {
                notification1Selected = value ?? false;
              });
            },
          ),
          _buildNotificationContainer(
            "Time for a quick check-in. How's your mood right now?",
            notification2Selected,
            (value) {
              setState(() {
                notification2Selected = value ?? false;
              });
            },
          ),
          _buildNotificationContainer(
            "It's time for your scheduled check-in. Any incident you'd like to report?",
            notification3Selected,
            (value) {
              setState(() {
                notification3Selected = value ?? false;
              });
            },
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: Center(
                child: Image.asset(
                  'assets/images/img2.png',
                  height: MediaQuery.of(context).size.height *
                      0.5, // 50% of screen height
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationContainer(
      String text, bool selected, ValueChanged<bool?> onChanged) {
    return Container(
      color: Colors.white,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(
          text,
          style: TextStyle(
            color: Color(0xFF1B515D),
          ),
        ),
        trailing: Checkbox(
          value: selected,
          onChanged: onChanged,
        ),
        leading: Icon(Icons.notifications),
      ),
    );
  }
}
