import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lsd/screens/dashboard.dart';
import 'package:permission_handler/permission_handler.dart';
import './screens/login.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await setupFlutterNotifications();
  showFlutterNotification(message);
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  print('Handling a background message ${message.messageId}');
}

/// Create a [AndroidNotificationChannel] for heads up notifications
late AndroidNotificationChannel channel;

bool isFlutterLocalNotificationsInitialized = false;

Future<void> setupFlutterNotifications() async {
  if (isFlutterLocalNotificationsInitialized) {
    return;
  }
  channel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.high,
  );

  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Create an Android Notification Channel.
  ///
  /// We use this channel in the `AndroidManifest.xml` file to override the
  /// default FCM channel to enable heads up notifications.
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  /// Update the iOS foreground notification presentation options to allow
  /// heads up notifications.
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  isFlutterLocalNotificationsInitialized = true;
}

void showFlutterNotification(RemoteMessage message) {
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;
  if (notification != null && android != null && !kIsWeb) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          // TODO add a proper drawable resource to android, for now using
          //      one that already exists in example app.
          icon: 'launch_background',
        ),
      ),
    );
  }
}

/// Initialize the [FlutterLocalNotificationsPlugin] package.
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  if (!kIsWeb) {
    await setupFlutterNotifications();
  }

  // ... (in your main function or a suitable initialization method)
  // const AndroidNotificationDetails channel = AndroidNotificationDetails(
  //   channelDescription: ,
  //   // id: 'emergency_channel',
  //   // name: 'Emergency Notifications',
  //   importance: Importance.high,
  //   priority: Priority.high,
  //   enableLights: true, // Enable LED light for emergencies (optional)
  //   playSound: true, // Play sound (optional)
  //   enableVibration: true, // Enable vibration (optional)
  //   // sticky: true, // Set sticky for remaining on screen
  //
  //   category: AndroidNotificationCategory.alarm,
  // );
  // // await flutterLocalNotificationsPlugin
  // //     .createNotificationChannels([channel]);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<void> _requestPermission() async {
    if (!await Permission.notification.isGranted) {
      final status = await Permission.notification.request();
      if (status != PermissionStatus.granted) {
        print('Unable to get permission for notifications');
      }
    }
  }

  void initState() {
    super.initState();
    _requestPermission(); // Request notification permission upon app launch
    _getDeviceToken();
    // ... other initialization code
  }

  Future<void> _getDeviceToken() async {
    var token1 = await FirebaseMessaging.instance.getToken().then((token) {
      if (token != null) {
        print('Device Token: $token');
      }
    });
    print('Token ================= $token1');
  }

  @override
  Widget build(BuildContext context) {
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        _handleNotification(message);
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle notification tap event (optional)
    });
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      print('Device Token Refreshed: $token'); // Handle token refresh events
    });

    return MaterialApp(
      theme: ThemeData(
        primaryColor: const Color.fromARGB(0, 234, 10, 204),
      ),
      home: FirebaseAuth.instance.currentUser == null
          ? LoginScreen()
          : const Dashboard(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/login': (context) =>
            const LoginScreen(), // Route for the login screen
      },
    );
  }

  void _handleNotification(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;
    showFlutterNotification(message);
  }
}
