import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:lsd/screens/incidentReoprting.dart';
import 'package:lsd/screens/notification.dart';
import 'package:lsd/screens/realtimeMonitoring.dart';
import 'package:lsd/screens/schedule.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.sizeOf(context);
    var Width = screenSize.width;
    var Height = screenSize.height;
    return Scaffold(
        backgroundColor: const Color.fromRGBO(246, 246, 246, 10),
        body: Column(children: [
          const SizedBox(
            height: 70,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // SizedBox(
              //   width: Width * 0.08,
              // ),
              SizedBox(
                width: 170,
                height: 40,
                child: ElevatedButton(
                  onPressed: () {
                    //add route to profile
                  },
                  style: const ButtonStyle(
                    elevation: MaterialStatePropertyAll(0),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundImage:
                            AssetImage("assets/images/dProfile.jpg"),
                      ),
                      Text(
                        "My Profile",
                        style: TextStyle(
                          fontFamily: 'Nunito Sans',
                          color: Color.fromRGBO(187, 187, 187, 1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ElevatedButton(
                  style: ButtonStyle(
                    elevation: const MaterialStatePropertyAll(0),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                  ),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Notifications()));
                  },
                  child: const SizedBox(
                    height: 40,
                    width: 15,
                    child: Image(
                      image: AssetImage("assets/images/notifProfile.png"),
                    ),
                  ))
            ],
          ),
          const SizedBox(
            height: 15,
          ),
          Text(
            "Hello! ${/*add backend for username @ritika*/ ""}",
            style: TextStyle(
              fontSize: 28,
              fontFamily: 'Nunito Sans',
              color: Colors.grey[700],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28.0),
            child: InkWell(
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ChatScreen()));
              },
              child: Container(
                  height: Height * 0.2,
                  width: Width,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color.fromRGBO(68, 118, 126, 1),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(68, 118, 126, 1),
                          blurRadius: 10.0,
                          spreadRadius: 2.0,
                          offset: Offset(0.0, 5.0),
                        )
                      ]),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        "Detail Incident \nReport",
                        style: TextStyle(
                          fontFamily: 'Nunito Sans',
                          fontSize: 25,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(
                        height: 40,
                        width: 40,
                        child: Image(
                          image: AssetImage("assets/images/iconNext.png"),
                        ),
                      ),
                    ],
                  )),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
            child: InkWell(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ScheduledCheckInPage()));
              },
              child: Container(
                  height: Height * 0.15,
                  width: Width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color.fromRGBO(144, 177, 183, 1),
                    // boxShadow: const [
                    //   BoxShadow(
                    //     color: Color.fromRGBO(68, 118, 126, 1),
                    //     blurRadius: 10.0,
                    //     spreadRadius: 2.0,
                    //     offset: Offset(0.0, 5.0),
                    //   )]
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        "Scheduled check \ninstruction",
                        style: TextStyle(
                          fontFamily: 'Nunito Sans',
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(
                        height: 40,
                        width: 40,
                        child: Image(
                          image: AssetImage("assets/images/report.png"),
                        ),
                      ),
                    ],
                  )),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28.0),
            child: InkWell(
              onTap: () {},
              child: Container(
                  height: Height * 0.1,
                  width: Width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color.fromRGBO(112, 146, 163, 1),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        "Emotional \nJournaling",
                        style: TextStyle(
                          fontFamily: 'Nunito Sans',
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(
                        height: 40,
                        width: 40,
                        child: Image(
                          image: AssetImage("assets/images/journaling.png"),
                        ),
                      ),
                    ],
                  )),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
            child: InkWell(
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => RealTimeMonitor()));
              },
              child: InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => RealTimeMonitor()));
                },
                child: Container(
                    height: Height * 0.1,
                    width: Width,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color.fromRGBO(140, 186, 193, 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(right: Width * 0.4),
                          child: const Text(
                            "Real time \nMonitoring",
                            style: TextStyle(
                              fontFamily: 'Nunito Sans',
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    )),
              ),
            ),
          ),
        ]));
  }
}
