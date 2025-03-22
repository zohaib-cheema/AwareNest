import 'dart:io';

import 'package:face_emotion_detector/face_emotion_detector.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class RealTimeMonitor extends StatefulWidget {
  const RealTimeMonitor({super.key});

  @override
  State<RealTimeMonitor> createState() => _RealTimeMonitorState();
}

class _RealTimeMonitorState extends State<RealTimeMonitor> {



  int counter = 1;

  String emotion = '';
  Future<void> imotion() async {

    // print(counter);
    // switch (counter) {
    //   case 1:
    //     setState(() {
    //       emotion = 'Happy';
    //     });
    //     break; // Add break statements to exit the switch statement after each case
    //   case 2:
    //     setState(() {
    //       emotion = 'Sad';
    //     });
    //     break;
    //   case 3:
    //     setState(() {
    //       emotion = 'Angry';
    //     });
    //     break;
    // }
    // Increment the counter after each switch statement execution
    // if(counter<3){
    //   counter++;
    // }else{
    //   counter=1;
    // }
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    setState((){
      _imageFile = image;
    });

    final emotionDetector = EmotionDetector();
    final file = File(image!.path);
    final label = await emotionDetector.detectEmotionFromImage(image: file);
    setState(() {
      emotion=label!;
    });
    print(emotion+label.toString());
  }
  XFile? _imageFile;



  Future<void> _takePicture() async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Emotion  $emotion'),
            ElevatedButton(onPressed: () => imotion(), child: Text("Monitor")),
            Center(
              child: _imageFile == null
                  ? Text('No image selected.')
                  : Image.file(
                      File(_imageFile!.path),
                      height: 300,
                      width: 300,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}