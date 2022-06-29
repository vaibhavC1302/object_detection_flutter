import 'dart:io';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late File _image;
  final _picker = ImagePicker();
  bool _loading = true;

  /////////////////////////////////////////////////////////////////////

  late ObjectDetector _objectDetector;

  String _text = "";

  void _initializeDetector(DetectionMode mode) async {
    const path =
        "assets/lite-model_object_detection_mobile_object_labeler_v1_1.tflite";
    final modelPath = await _getModel(path);
    final options = LocalObjectDetectorOptions(
        mode: mode,
        modelPath: modelPath,
        classifyObjects: true,
        multipleObjects: true);
    _objectDetector = ObjectDetector(options: options);
  }

  @override
  void initState() {
    super.initState();
    _initializeDetector(DetectionMode.single);
  }

  @override
  void dispose() {
    _objectDetector.close();
    super.dispose();
  }

  Future<String> _getModel(String assetPath) async {
    if (Platform.isAndroid) {
      return 'flutter_assets/$assetPath';
    }
    final path = '${(await getApplicationSupportDirectory()).path}/$assetPath';
    await Directory(dirname(path)).create(recursive: true);
    final file = File(path);
    if (!await file.exists()) {
      final byteData = await rootBundle.load(assetPath);
      await file.writeAsBytes(byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    }
    return file.path;
  }

  Future<void> processimage(InputImage inputImage) async {
    var objects = await _objectDetector.processImage(inputImage);

    String text = 'Objects found: ${objects.length}\n\n';
    for (final object in objects) {
      text += 'Object: ${object.labels.map((e) => e.text)}\n\n';
    }
    setState(() {
      _text = text;
      _loading = false;
    });
  }

  /////////////////////////////////////////////////////////////////////
  cameraImage() async {
    var image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return;
    setState(() {
      _image = File(image.path);
    });
    processimage(InputImage.fromFilePath(image.path));
  }

  galleryImage() async {
    var image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() {
      _image = File(image.path);
    });
    processimage(InputImage.fromFilePath(image.path));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Object Detection"),
      ),
      body: Container(
        alignment: Alignment.topCenter,
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.5,
                width: MediaQuery.of(context).size.width * 0.5,
                color: Colors.grey.shade400,
                child: _loading == true
                    ? null
                    : Image.file(
                        _image,
                        fit: BoxFit.fill,
                      ),
              ),
              const SizedBox(
                height: 10,
              ),
              GestureDetector(
                onTap: cameraImage,
                child: const Text(
                  "Camera",
                  style: TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                      fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              GestureDetector(
                onTap: galleryImage,
                child: const Text("Gallery",
                    style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(
                height: 10,
              ),
              _text == "" ? const Text("No Object") : Text(_text)
            ],
          ),
        ),
      ),
    );
  }
}
