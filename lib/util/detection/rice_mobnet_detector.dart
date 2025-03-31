import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class RiceMobnetDetector {
  Interpreter? _interpreter;
  List<String> _labels = [];

  Future<void> loadModel() async {
   //  _interpreter = await Interpreter.fromAsset(
     //    'assets/models/rice_model/rice_mobnetv2_model.tflite');
   // _interpreter = await Interpreter.fromAsset(
    //    'assets/models/rice_model/rice_inception_model.tflite');
   //  _interpreter = await Interpreter.fromAsset(
   //      'assets/models/rice_model/rice_cnn_model.tflite');
   //  _interpreter = await Interpreter.fromAsset(
    //     'assets/models/rice_model/rice_dense_net_model.tflite');
    // _interpreter = await Interpreter.fromAsset(
    //     'assets/models/rice_model/rice_vgg_model.tflite');
   //  _interpreter = await Interpreter.fromAsset(
    //     'assets/models/rice_model/rice_Xception_model.tflite');

    final labelsData =
        await rootBundle.loadString('assets/models/rice_model/rice_label.txt');
    _labels =
        labelsData.split('\n').where((label) => label.isNotEmpty).toList();
    _labels.map(
      (result) {
        print("Rice Label: ${result}");
      },
    ).toList();
  }

  List<Map<String, dynamic>> detectObjects(img.Image image) {
    if (_interpreter == null) {
      throw Exception("Model not loaded!");
    }

    img.Image resizedImage = img.copyResize(image, width: 224, height: 224);
    var input = _imageToByteList(resizedImage, 224);

    var output = List.filled(1, 0.0).reshape([1, 1]);

    _interpreter!.run(input, output);

    double confidence = output[0][0];
    print("Confidence: $confidence");

    List<Map<String, dynamic>> results = [];
    String label = confidence > 0.2 ? _labels[1] : _labels[0];

    results.add({
      "label": label,
      "confidence": confidence,
    });

    print("Rice Detected: $label with Confidence: $confidence");
    return results;
  }

  Uint8List _imageToByteList(img.Image image, int inputSize) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        var pixel = image.getPixel(x, y);
        buffer[pixelIndex++] = (pixel.r / 255.0) * 2.0 - 1.0;
        buffer[pixelIndex++] = (pixel.g / 255.0) * 2.0 - 1.0;
        buffer[pixelIndex++] = (pixel.b / 255.0) * 2.0 - 1.0;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }
}
