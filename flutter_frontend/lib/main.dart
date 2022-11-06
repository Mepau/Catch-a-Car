import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

void main() {
  runApp(const MyApp());
}

class FileUploadButton extends StatefulWidget {
  const FileUploadButton({super.key});

  @override
  State<FileUploadButton> createState() => _FileUploadButtonState();
}

class _FileUploadButtonState extends State<FileUploadButton> {
  String _fileName = "";
  var _fileBytes;

  void _setFile() async {
    var picked = await FilePicker.platform.pickFiles();

    if (picked != null) {
      setState(() {
        _fileBytes = picked.files.first.bytes;
        _fileName = picked.files.first.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
      children: [
        Padding(
            padding: const EdgeInsets.all(0),
            child: TextButton(
              child: Text('UPLOAD FILE'),
              onPressed: _setFile,
            )),
        Text(_fileName),
      ],
    ));
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _fileName = "";
  var _fileBytes;

  void _setFile() async {
    var picked = await FilePicker.platform.pickFiles();

    if (picked != null) {
      setState(() {
        _fileBytes = picked.files.first.bytes;
        _fileName = picked.files.first.name;
      });
    }
  }

// This widget is the root of your application.
  Future<http.Response> buttonPressed() async {
    http.Response returnedResult = await http.get(
        Uri.parse("http://localhost:8000/app/hellodjango"),
        headers: <String, String>{
          "Content-Type": "application/json, charset-UTF-8"
        });
    print(returnedResult.body);
    return returnedResult;
  }

  // This widget is the root of your application.
  Future<http.Response> detectButtonPressed() async {
    http.Response returnedResult = await http.post(
        Uri.parse("http://127.0.0.1:8000/api/v1/object_detection/predict"),
        headers: <String, String>{
          "Content-Type":
              "multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW"
        },
        body: _fileBytes);
    print(returnedResult.body);
    return returnedResult;
  }

  @override
  Widget build(BuildContext context) {
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
            body: Center(
                child: Column(
              children: [
                Padding(
                    padding: const EdgeInsets.all(0.0),
                    child: const Text("Welcome")),
                Padding(
                    padding: const EdgeInsets.all(0.0),
                    child: ElevatedButton(
                        onPressed: buttonPressed, child: Text("Click"))),
                Padding(
                    padding: const EdgeInsets.all(0),
                    child: TextButton(
                      child: Text('UPLOAD FILE'),
                      onPressed: _setFile,
                    )),
                Text(_fileName),
                Padding(
                    padding: const EdgeInsets.all(0.0),
                    child: ElevatedButton(
                        onPressed: detectButtonPressed, child: Text("Detect")))
              ],
            ))));
  }
}
