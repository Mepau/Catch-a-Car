import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'widgets/StatusTable.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class UploadScreen extends StatefulWidget {
  const UploadScreen({Key? key}) : super(key: key);

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  String _fileName = "";
  var _fileBytes;
  var _filePath;
  List<Map<String, dynamic>> status = [];

  void _setFile() async {
    var picked = await FilePicker.platform.pickFiles();

    if (picked != null) {
      if (kIsWeb) {
        setState(() {
          _fileBytes = picked.files.first.bytes;
          _fileName = picked.files.first.name;
        });
      } else {
        print(picked.files);
        setState(() {
          _filePath = picked.files.first.path;
          _fileName = picked.files.first.name;
        });
      }
    }

    print(_filePath);
  }

// This widget is the root of your application.
  Future<String> buttonPressed() async {
    String taskId = status[0]["id"];

    String url =
        'http://localhost:8000/api/v1/object_detection/Status?id=$taskId';
    print(url);
    var dio = Dio();
    await dio
        .get(
          url,
        )
        .then((response) => print(response.data));
    //print(returnedResult.body);
    return "null";
  }

  @override
  void initState() {
    Timer.periodic(const Duration(seconds: 10), (Timer timer) async {
      List<Map<String, dynamic>> newStatus = [];

      for (var element in status) {
        String taskId = element["id"];
        String url =
            'http://localhost:8000/api/v1/object_detection/Status?id=$taskId';
        await Dio()
            .get(
              url,
            )
            .then((response) => {
                  if (response.data["status"].toString() !=
                      element["status"].toString())
                    {newStatus.insert(0, response.data)}
                  else
                    {newStatus.insert(0, element)}
                });
        setState(() {
          status = newStatus;
        });
      }
    });
    super.initState();
  }

  // This widget is the root of your application.
  /*Future<http.Response> detectButtonPressed() async {
    http.Response returnedResult = await http.post(
        Uri.parse("http://127.0.0.1:8000/api/v1/object_detection/predict"),
        headers: <String, String>{
          "Content-Type":
              "multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW"
        },
        body: _fileBytes);
    print(returnedResult.body);
    return returnedResult;
  }*/

  Future<Map<String, dynamic>> detectButtonPressed() async {
    Map<String, dynamic> jsonResponse = {};
    var dio = Dio();
    if (kIsWeb) {
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromBytes(_fileBytes, filename: _fileName),
      });
      await dio
          .post("http://127.0.0.1:8000/api/v1/object_detection/predict",
              data: formData)
          .then((response) => jsonResponse = response.data);

      print(jsonResponse["id"]);
      print(jsonResponse["status"]);
      setState(() {
        status.insert(0, jsonResponse);
      });
    } else {
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(_filePath, filename: _fileName),
      });
      await dio
          .post("http://127.0.0.1:8000/api/v1/object_detection/predict",
              data: formData)
          .then((response) => jsonResponse = response.data);

      print(jsonResponse["id"]);
      print(jsonResponse["status"]);
      setState(() {
        status.insert(0, jsonResponse);
      });
    }

    return jsonResponse;
  }

  @override
  Widget build(BuildContext context) {
    bool isScreenWide = MediaQuery.of(context).size.width >= 415;
    return Scaffold(
        appBar: AppBar(
          title: const Text('Catch a Car'),
        ),
        body: SingleChildScrollView(
            child: Flex(
          mainAxisAlignment:
              MainAxisAlignment.center, //Center Row contents horizontally,
          crossAxisAlignment:
              CrossAxisAlignment.center, //Center Row contents vertically
          direction: isScreenWide ? Axis.horizontal : Axis.vertical,
          children: [
            Padding(
              padding: const EdgeInsets.all(100.0),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
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
                            onPressed: detectButtonPressed,
                            child: Text("Detect"))),
                  ]),
            ),
            Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [StatusTable(statusList: status)]),
          ],
        )));
  }
}
