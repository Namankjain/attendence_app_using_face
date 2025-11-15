// file: lib/face_recognition_service.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart'; // For PlatformException
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'local_database_helper.dart'; // To access the Faculty class definition

class FaceRecognitionService {
  Interpreter? _interpreter;
  final FaceDetector _faceDetector;

  // --- Model and Image Configuration ---
  static const String _modelFile = 'assets/mobile_face_net.tflite'; // Correct model name with asset path
  static const int _inputSize = 112;
  static const int _outputSize = 192;
  static const double _recognitionThreshold = 1.0;

  FaceRecognitionService()
      : _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  /// Loads the TFLite model from assets. Must be called and awaited before use.
  Future<void> loadModel() async {
    try {
      if (_interpreter != null) {
        print('Model already loaded. Skipping.');
        return; // Don't load if already loaded
      }

      print('Attempting to load model: $_modelFile');
      // Check if the asset exists before trying to load it
      final ByteData data = await rootBundle.load(_modelFile);
      if (data == null) {
        throw Exception('Asset $_modelFile not found in assets. Check pubspec.yaml and file path.');
      }

      _interpreter = await Interpreter.fromAsset(_modelFile);

      if (_interpreter == null) {
        throw Exception('Interpreter.fromAsset returned null. Model loading failed.');
      }
      print('✅ FaceNet model loaded successfully.');
    } on PlatformException catch(e) {
      print('❌ FAILED TO LOAD MODEL ($_modelFile): PlatformException: ${e.message}');
      print('❌ CHECK: 1. Is the file name "$_modelFile" exactly correct?');
      print('❌ CHECK: 2. Is the file in your assets folder?');
      print('❌ CHECK: 3. Is the asset declared in pubspec.yaml?');
      print('❌ CHECK: 4. Did you run "flutter pub get" and do a clean rebuild?');
      rethrow;
    } catch (e) {
      print('❌ FAILED TO LOAD MODEL ($_modelFile): $e');
      rethrow;
    }
  }

  /// Detects faces in an image.
  Future<List<Face>> detectFaces(InputImage image) async {
    return await _faceDetector.processImage(image);
  }

  /// Loads an image from a file path.
  Future<img.Image?> loadImage(String path) async {
    final imageBytes = await File(path).readAsBytes();
    return img.decodeImage(imageBytes);
  }

  /// Crops the detected face from the full image.
  img.Image? getFaceData(img.Image originalImage, Face face) {
    final x = face.boundingBox.left.toInt();
    final y = face.boundingBox.top.toInt();
    final w = face.boundingBox.width.toInt();
    final h = face.boundingBox.height.toInt();
    if (x < 0 || y < 0 || w <= 0 || h <= 0 || (x + w) > originalImage.width || (y + h) > originalImage.height) {
      print("Warning: Face bounding box is out of image bounds. Skipping crop.");
      return null;
    }
    return img.copyCrop(originalImage, x: x, y: y, width: w, height: h);
  }

  /// Generates a 192-dimensional embedding vector from a face image.

  List<double> getEmbeddings(img.Image faceImage) {
    if (_interpreter == null) {
      throw StateError("FATAL: Interpreter is null. The model likely failed to load at startup.");
    }

    img.Image resizedImage = img.copyResize(faceImage, width: _inputSize, height: _inputSize);
    Float32List imageAsList = _imageToFloat32List(resizedImage);
    final input = imageAsList.reshape([1, _inputSize, _inputSize, 3]);
    final output = List.filled(1 * _outputSize, 0.0).reshape([1, _outputSize]);

    _interpreter!.run(input, output);
    return List.from(output[0]);
  }

  /// Recognizes faces in an image against a list of known faculty.
  Future<List<Faculty>> recognizeFacesInImage(String imagePath, List<Faculty> allFaculty) async {
    if (_interpreter == null) throw StateError("Interpreter not ready. Ensure loadModel() was awaited.");

    final inputImage = InputImage.fromFilePath(imagePath);
    final detectedFaces = await detectFaces(inputImage);
    final originalImage = await loadImage(imagePath);
    if (detectedFaces.isEmpty || originalImage == null) return [];

    List<Faculty> recognizedFacultyList = [];
    for (var face in detectedFaces) {
      final faceData = getFaceData(originalImage, face);
      if (faceData == null) continue;

      final newEmbedding = getEmbeddings(faceData);
      Faculty? bestMatch;
      double minDistance = double.infinity;

      for (var faculty in allFaculty) {
        final distance = compareEmbeddings(faculty.embeddings, newEmbedding);
        if (distance < minDistance && distance <= _recognitionThreshold) {
          minDistance = distance;
          bestMatch = faculty;
        }
      }
      if (bestMatch != null && !recognizedFacultyList.any((f) => f.facultyId == bestMatch!.facultyId)) {
        recognizedFacultyList.add(bestMatch);
      }
    }
    return recognizedFacultyList;
  }

  /// Calculates the Euclidean distance between two embedding vectors.
  double compareEmbeddings(List<double> e1, List<double> e2) {
    double sum = 0.0;
    for (int i = 0; i < e1.length; i++) {
      sum += pow(e1[i] - e2[i], 2);
    }
    return sqrt(sum);
  }

  /// Internal helper to convert an `img.Image` to a `Float32List`.
  Float32List _imageToFloat32List(img.Image image) {
    var buffer = Float32List(_inputSize * _inputSize * 3);
    var bufferIndex = 0;
    for (var y = 0; y < _inputSize; y++) {
      for (var x = 0; x < _inputSize; x++) {
        var pixel = image.getPixel(x, y);
        buffer[bufferIndex++] = (pixel.r - 127.5) / 127.5;
        buffer[bufferIndex++] = (pixel.g - 127.5) / 127.5;
        buffer[bufferIndex++] = (pixel.b - 127.5) / 127.5;
      }
    }
    return buffer;
  }

  /// Releases resources.
  void dispose() {
    _faceDetector.close();
    _interpreter?.close();
    _interpreter = null;
  }
}