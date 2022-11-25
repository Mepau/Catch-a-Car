import 'package:flutter/material.dart';
import 'package:flutter_frontend/ResultScreen.dart';
import 'UploadScreen.dart';
import 'package:go_router/go_router.dart';

class Endpoints {
  Endpoints._();

  // base url
  static const String baseUrl = "http://localhost:8000";

  // receiveTimeout
  static const int receiveTimeout = 15000;

  // connectTimeout
  static const int connectionTimeout = 15000;

  static const String users = '/users';
}

void main() {
  runApp(const MyApp());
}

final GoRouter _router = GoRouter(
  routes: [
    GoRoute(
      path: "/",
      builder: (BuildContext context, GoRouterState state) =>
          const UploadScreen(),
    ),
    GoRoute(
      path: "/Results/:id",
      builder: (BuildContext context, GoRouterState state) =>
          ResultScreen(id: state.params["id"]!),
    )
  ],
);

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    //return MaterialApp.router(
    //  routeInformationProvider: _router.routeInformationProvider,
    //  routeInformationParser: _router.routeInformationParser,
    //  routerDelegate: _router.routerDelegate,
    //);

    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a blue toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or simply save your changes to "hot reload" in a Flutter IDE).
          // Notice that the counter didn't reset back to zero; the application
          // is not restarted.
          primarySwatch: Colors.blue,
        ),
        home: Scaffold(
            appBar: AppBar(centerTitle: true, title: const Text("Appbar")),
            body: const UploadScreen()));
  }
}
