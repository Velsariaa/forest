import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class RiceStatusMobnetDetector {
  Interpreter? _interpreter;
  List<String> _labels = [];

  Future<void> loadModel() async {
     _interpreter = await Interpreter.fromAsset(
         'assets/models/rice_status_model/rice_status_mobnetv2.tflite');
   // _interpreter = await Interpreter.fromAsset(
    //    'assets/models/rice_status_model/rice_status_vgg.tflite');
     // _interpreter = await Interpreter.fromAsset(
     //    'assets/models/rice_status_model/rice_status_cnn_model.tflite');
  //  _interpreter = await Interpreter.fromAsset(
     //    'assets/models/rice_status_model/rice_status_dense_net_model.tflite');
     // _interpreter = await Interpreter.fromAsset(
     //   'assets/models/rice_status_model/rice_status_inception.tflite');
     // _interpreter = await Interpreter.fromAsset(
     //    'assets/models/rice_status_model/rice_status_NASNetMobile_model.tflite');

    final labelsData = await rootBundle
        .loadString('assets/models/rice_status_model/status_rice.txt');
    _labels =
        labelsData.split('\n').where((label) => label.isNotEmpty).toList();
    _labels.map(
      (result) {
        print("Rice Status Label: ${result}");
      },
    ).toList();
  }

  List<Map<String, dynamic>> detectObjects(img.Image image) {
    if (_interpreter == null) {
      throw Exception("Model not loaded!");
    }

    img.Image resizedImage = img.copyResize(image, width: 224, height: 224);
    var input = _imageToByteList(resizedImage, 224);

    var output = List.filled(_labels.length, 0.0).reshape([1, _labels.length]);

    _interpreter!.run(input, output);

    List<Map<String, dynamic>> results = [];
    for (int i = 0; i < _labels.length; i++) {
      if (output[0][i] > 0.5) {
        results.add({
          "label": _labels[i],
          "confidence": output[0][i],
        });
      }
    }

    print("Output: ${output[0]}");
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
