import 'package:flutter/material.dart';
import 'dart:io';
import 'package:tflite/tflite.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WingScan',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        fontFamily: 'Montserrat',
        scaffoldBackgroundColor: Colors.blueGrey[900], // Changed the background color to dark grey
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueGrey,
        scaffoldBackgroundColor: Colors.black,
      ),
      themeMode: ThemeMode.system,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _loading = false;
  File? _image;
  List? _outputs;
  final _imagePicker = ImagePicker();
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loading = true;

    loadModel().then((value) {
      setState(() {
        _loading = false;
      });
    });
  }

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/model_unquant.tflite",
      labels: "assets/labels.txt",
    );
  }

  pickImage(ImageSource source) async {
    var image = await _imagePicker.pickImage(source: source);
    if (image == null) return null;
    setState(() {
      _loading = true;
      _image = File(image.path);
    });
    classifyImage(_image!);
  }

  classifyImage(File image) async {
    var output = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 2,
      threshold: 0.5,
      imageMean: 127.5,
      imageStd: 127.5,
    );

    setState(() {
      _loading = false;
      _outputs = output;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "WingScan",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? Center(
        child: CircularProgressIndicator(),
      )
          : Container(
        width: MediaQuery.of(context).size.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image == null
                ? Container()
                : Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _darkMode ? Colors.white : Colors.black,
                  width: 2.0,
                ),
              ),
              child: Image.file(
                _image!,
                height: 300,
                width: 300,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            _outputs != null
                ? Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _darkMode ? Colors.white : Colors.black,
                  width: 2.0,
                ),
              ),
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "${_outputs![0]["label"]}"
                    .replaceAll(RegExp(r'[0-9]'), ''),
                style: TextStyle(
                  color: _darkMode ? Colors.white : Colors.black,
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
                : Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _darkMode ? Colors.white : Colors.black,
                  width: 2.0,
                ),
              ),
              padding: const EdgeInsets.all(8.0),
              child: const Text(
                "Classification Waiting",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => pickImage(ImageSource.gallery),
                  child: const Text('Pick from Gallery'),
                ),
                ElevatedButton(
                  onPressed: () => pickImage(ImageSource.camera),
                  child: const Text('Take a Picture'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Dark Mode',
                  style: TextStyle(
                    color: _darkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: _darkMode,
                  onChanged: (value) {
                    setState(() {
                      _darkMode = value;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
