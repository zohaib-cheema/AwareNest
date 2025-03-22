import 'package:background_sms/background_sms.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class Emergency extends StatefulWidget {
  const Emergency({super.key});

  @override
  State<Emergency> createState() => _EmergencyState();
}

class _EmergencyState extends State<Emergency> {
  bool notify = true;

  String? _currentAddress;

  Position? _currentPosition;

  Future<void> _getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      setState(() => _currentPosition = position);
    }).catchError((e) {
      debugPrint(e);
    });
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getCurrentPosition();
    _handleLocationPermission();
  }

  @override
  Widget build(BuildContext context) {
    List<String> number = ['9729574967', '7206629681'];
    var screenSize = MediaQuery.sizeOf(context);
    var Width = screenSize.width;
    var Height = screenSize.height;

    return Scaffold(
        backgroundColor: const Color.fromRGBO(246, 246, 246, 10),
        body: Column(
          children: [
            const SizedBox(
              height: 50,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const CircleAvatar(
                  backgroundImage: AssetImage("assets/images/dProfile.jpg"),
                ),
                const Text("Friend Alert",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                      fontFamily: 'Poppins',
                    )),
                ElevatedButton(
                    style: ButtonStyle(
                      elevation: const MaterialStatePropertyAll(0),
                      foregroundColor: MaterialStateProperty.all(Colors.white),
                    ),
                    onPressed: () {},
                    child: const SizedBox(
                      height: 40,
                      width: 20,
                      child: Image(
                        image: AssetImage("assets/images/notifProfile.png"),
                      ),
                    ))
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Text("Close Friends ",
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    )),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    "Edit",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[400],
                      fontFamily: 'Poppins',
                    ),
                  ),
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                    height: Height * 0.2,
                    width: Height * 0.2,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text("Friend 1",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[400],
                                fontFamily: 'Poppins',
                              )),
                        ),
                        SizedBox(
                          height: Height * 0.1,
                          width: Height * 0.1,
                          child: const CircleAvatar(
                            backgroundImage:
                                AssetImage("assets/images/dProfile.jpg"),
                          ),
                        )
                      ],
                    )),
                Container(
                    height: Height * 0.2,
                    width: Height * 0.2,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text("Friend 2",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[400],
                                fontFamily: 'Poppins',
                              )),
                        ),
                        SizedBox(
                          height: Height * 0.1,
                          width: Height * 0.1,
                          child: const CircleAvatar(
                            backgroundImage:
                                AssetImage("assets/images/dProfile.jpg"),
                          ),
                        )
                      ],
                    )),
              ],
            ),
            SizedBox(
              height: Height * 0.04,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                    height: Height * 0.2,
                    width: Height * 0.2,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text("Friend 3",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[400],
                                fontFamily: 'Poppins',
                              )),
                        ),
                        SizedBox(
                          height: Height * 0.1,
                          width: Height * 0.1,
                          child: const CircleAvatar(
                            backgroundImage:
                                AssetImage("assets/images/dProfile.jpg"),
                          ),
                        )
                      ],
                    )),
                Container(
                    height: Height * 0.2,
                    width: Height * 0.2,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text("Friend 4",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[400],
                                fontFamily: 'Poppins',
                              )),
                        ),
                        SizedBox(
                          height: Height * 0.1,
                          width: Height * 0.1,
                          child: const CircleAvatar(
                            backgroundImage:
                                AssetImage("assets/images/dProfile.jpg"),
                          ),
                        )
                      ],
                    )),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Expanded(
              child: Container(
                  width: Width * 0.90,
                  height: Height * 0.25,
                  decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      color: Color.fromRGBO(173, 209, 215, 1)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.only(left: 8.0, top: 8.0),
                                child: Text("Allow SOS Alerts",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                    )),
                              ),
                              Text("For your emergencies ",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'Poppins',
                                  ))
                            ],
                          ),
                          Switch(
                            value: notify,
                            activeColor: Colors.red,
                            onChanged: (bool value) {
                              setState(() {
                                notify = value;
                              });
                            },
                          ),

                          // SwitchListTile(value: notify, onChanged: (value) {})
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(150),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.white,
                                blurRadius: 10.0,
                                spreadRadius: 5.0,
                                offset: Offset(0.0, 5.0),
                              )
                            ]),
                        child: ElevatedButton(
                          onPressed: () async {
                            for (int i = 0; i < number.length; i++) {
                              SmsStatus res = await BackgroundSms.sendMessage(
                                  phoneNumber: number[i],
                                  message:
                                      'Hii  \nEmergency! I need help urgently. My current location is https://www.google.com/maps?q=${_currentPosition?.latitude},${_currentPosition?.longitude}');
                              print(res);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            shadowColor: Colors.white,
                            elevation: 50,
                            backgroundColor: Colors.red,
                            shape:
                                const CircleBorder(), // make the button circular
                            padding: EdgeInsets.all(Height * 0.07),
                            // set the text color to white
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("SOS",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 25,
                                    color: Colors.white,
                                    fontFamily: 'Poppins',
                                  )),
                              Text("press volume down \n    button 3 times",
                                  style: TextStyle(
                                    fontSize: 7,
                                    color: Colors.white,
                                    fontFamily: 'Poppins',
                                  ))
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: Height * 0.001,
                      )
                    ],
                  )),
            )
          ],
        ));
  }
}
