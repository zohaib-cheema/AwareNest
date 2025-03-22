import 'package:flutter/material.dart';

class ScheduledCheckInPage extends StatefulWidget {
  const ScheduledCheckInPage({Key? key}) : super(key: key);

  @override
  _ScheduledCheckInPageState createState() => _ScheduledCheckInPageState();
}

class _ScheduledCheckInPageState extends State<ScheduledCheckInPage> {
  TimeOfDay? _selectedTime;

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

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
            false,
          ),
          _buildNotificationContainer(
            "Time for a quick check-in. How's your mood right now?",
            false,
          ),
          _buildNotificationContainer(
            "It's time for your scheduled check-in. Any incident you'd like to report?",
            false,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _selectTime(context),
            child: Text(_selectedTime != null ? 'Change Time' : 'Set Time'),
          ),
          if (_selectedTime != null)
            Text(
              'Selected Time: ${_selectedTime!.format(context)}',
              style: TextStyle(fontSize: 20),
            ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: Center(
                child: Image.asset(
                  'assets/images/img2.png',
                  height: MediaQuery.of(context).size.height * 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationContainer(String text, bool selected) {
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
          onChanged: null,
        ),
        leading: Icon(Icons.notifications),
      ),
    );
  }
}
