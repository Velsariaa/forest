import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:paddy_scan/util/detection/rice_status_mobnet_detector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import '../appstate.dart';
import 'package:image/image.dart' as img;

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  File? _image;
  final picker = ImagePicker();
  String? _imagePath;
  RiceStatusMobnetDetector riceStatusDetector = RiceStatusMobnetDetector();
  List<Map<String, dynamic>> _rice_status_detections = [];
  bool _isLoading = false;
  String _current_rice_classification = '';

  Future<void> getImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera),
                title: const Text("Take a Photo"),
                onTap: () async {
                  Navigator.pop(context);
                  final pickedFile =
                  await picker.pickImage(source: ImageSource.camera);
                  _handleImageSelection(pickedFile);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Choose from Gallery"),
                onTap: () async {
                  Navigator.pop(context);
                  final pickedFile =
                  await picker.pickImage(source: ImageSource.gallery);
                  _handleImageSelection(pickedFile);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleImageSelection(XFile? pickedFile) {
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _imagePath = pickedFile.path;
        _saveImagePath(_imagePath!);
      });
    } else {
      print('No image selected.');
    }
  }

  Future<void> _saveImagePath(String imagePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = path.join(directory.path, 'last_image_path.txt');
    final file = File(filePath);
    await file.writeAsString(imagePath);
  }

  Future<String?> _getLastImagePath() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = path.join(directory.path, 'last_image_path.txt');
      final file = File(filePath);
      return await file.readAsString();
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadLastImagePath();
    _loadModel();
  }

  Future<void> _loadModel() async {
    await riceStatusDetector.loadModel();
  }

  Future<void> _loadLastImagePath() async {
    final savedPath = await _getLastImagePath();
    if (savedPath != null) {
      setState(() {
        _image = File(savedPath);
        _imagePath = savedPath;
      });
    }
  }

  Future<void> _processRiceStatusImage() async {
    print('Rice Classification Detection');
    if (_image == null) return;

    final bytes = await _image!.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) {
      print("Could not decode image");
      _setLoading();
      return;
    }

    final riceStatusDetections = riceStatusDetector.detectObjects(image);
    setState(() {
      _rice_status_detections = riceStatusDetections;
    });

    if (_rice_status_detections.isNotEmpty) {
      _rice_status_detections.forEach((result) {
        setState(() {
          _current_rice_classification = result['label'];
        });

        print('Rice Status Detection: ${result['label']}');
        print(
            'Rice Status Detection Confidence: ${(result['confidence'] * 100).toStringAsFixed(2)}%');
      });
    } else {
      print('Rice Status Detection is Empty');
    }
  }

  void _resetImage() {
    setState(() {
      _image = null;
      _imagePath = null;
      _saveImagePath('');
    });
  }

  void _setLoading() {
    setState(() {
      _isLoading = !_isLoading;
      print('Set Loading to: $_isLoading');
      if (_isLoading) {
        _showLoadingDialog();
      } else {
        _dismissLoadingDialog();
      }
    });
  }

  void _showLoadingDialog() {
    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
                SizedBox(height: 20),
                Text("Processing, please wait..."),
              ],
            ),
          );
        },
      );
    });
  }

  void _dismissLoadingDialog() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5DC),
        title: const Text('Scan', style: TextStyle(color: Colors.green)),
        elevation: 0.0,
      ),
      body: Container(
        color: Colors.grey[300],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              GestureDetector(
                onTap: _image != null ? _resetImage : getImage,
                child: _image == null
                    ? Image.asset('assets/images/TapToOpenCam.png',
                    height: 500)
                    : Image.file(_image!, height: 500, fit: BoxFit.fitHeight),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _image != null
                    ? () async {
                  if (_isLoading) return;
                  _setLoading();
                  appState.currentImagePath = _imagePath!;

                  Future.delayed(Duration(milliseconds: 1000), () async {
                    await _processRiceStatusImage();

                    if (_current_rice_classification.isNotEmpty) {
                      appState.currentImageClassification =
                          _current_rice_classification;
                    } else {
                      print("No classification detected.");
                      appState.currentImageClassification = "Unknown";
                    }

                    _setLoading();
                    Navigator.pushNamed(context, '/scan_result');
                  });
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  textStyle: const TextStyle(fontSize: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child:
                const Text('Scan', style: TextStyle(color: Colors.white)),
              ),
              if (_imagePath != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    'Image Path: $_imagePath',
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}