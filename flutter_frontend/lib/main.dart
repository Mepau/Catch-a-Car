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

class AppThemeValues {
  final ThemeData themeData;

  AppThemeValues({required this.themeData});
}

AppThemeValues ligthTheme = AppThemeValues(themeData: ThemeData());

AppThemeValues darkTheme = AppThemeValues(
    themeData: ThemeData(
// UI
  brightness: Brightness.dark,
  primaryColor: Colors.lightBlue[800],
  accentColor: Colors.cyan[600],
// font
  fontFamily: 'Georgia',
//text style
  textTheme: const TextTheme(
    headline1: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
    headline6: TextStyle(fontSize: 36.0, fontStyle: FontStyle.italic),
    bodyText2: TextStyle(fontSize: 14.0, fontFamily: 'Hind'),
  ),
  buttonTheme: const ButtonThemeData(
    buttonColor: Colors.redAccent,
    shape: RoundedRectangleBorder(),
    textTheme: ButtonTextTheme.accent,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
      style: TextButton.styleFrom(
          backgroundColor: Colors.deepOrangeAccent,
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: TextStyle(color: Colors.white, fontSize: 20))),
));

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
        title: 'Catch a Car',
        theme: ThemeData(
// UI
          brightness: Brightness.dark,
          primaryColor: Colors.lightBlue[800],
          accentColor: Colors.cyan[600],
// font
          fontFamily: 'Georgia',
//text style
          textTheme: const TextTheme(
            headline1: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
            headline6: TextStyle(fontSize: 36.0, fontStyle: FontStyle.italic),
            bodyText2: TextStyle(fontSize: 14.0, fontFamily: 'Hind'),
          ),
          buttonTheme: const ButtonThemeData(
            buttonColor: Colors.redAccent,
            shape: RoundedRectangleBorder(),
            textTheme: ButtonTextTheme.accent,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
              style: TextButton.styleFrom(
                  backgroundColor: Colors.deepOrangeAccent,
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  textStyle: TextStyle(color: Colors.white, fontSize: 15))),
        ),
        home: const UploadScreen());
  }
}
