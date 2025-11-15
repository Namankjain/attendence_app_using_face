import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

// Local imports
import 'package:ati2/local_database_helper.dart';
import 'package:ati2/face_recognition_service.dart';

// Widget Imports
import 'package:ati2/widgets/gradient_elevated_button.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});
  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  XFile? _image;
  bool _working = false;
  final ImagePicker _picker = ImagePicker();
  String? _recognizedFacultyId;
  List<Faculty> _registeredFaculty = [];

  final FaceRecognitionService _faceRecognitionService =
  FaceRecognitionService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final FaceDetector _faceDetector = FaceDetector(options: FaceDetectorOptions());

  @override
  void initState() {
    super.initState();
    _faceRecognitionService.loadModel();
    _loadRegisteredFaculty();
  }

  Future<void> _loadRegisteredFaculty() async {
    _registeredFaculty = await _dbHelper.getAllFacultyWithEmbeddings();
  }

  @override
  void dispose() {
    _faceRecognitionService.dispose();
    _faceDetector.close();
    super.dispose();
  }

  Future<void> _captureAndRecognize() async {
    final XFile? picked =
    await _picker.pickImage(source: ImageSource.camera, imageQuality: 80, maxWidth: 600);
    if (picked == null) return;
    setState(() {
      _image = picked;
      _working = true;
      _recognizedFacultyId = null;
    });

    try {
      final inputImage = InputImage.fromFilePath(picked.path);
      final List<Face> faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        _showResultDialog('No Face Detected', 'Could not detect any face in the image.');
        setState(() => _working = false);
        return;
      }

      final imageBytes = await picked.readAsBytes();
      final img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        _showResultDialog('Error', 'Failed to process image.');
        setState(() => _working = false);
        return;
      }

      final Face face = faces.first;
      final Rect boundingBox = face.boundingBox;
      final croppedImage = img.copyCrop(
        image,
        x: boundingBox.left.toInt(),
        y: boundingBox.top.toInt(),
        width: boundingBox.width.toInt(),
        height: boundingBox.height.toInt(),
      );

      List<double> capturedEmbeddings =
      _faceRecognitionService.getEmbeddings(croppedImage);

      String? bestMatchFacultyId;
      double lowestDistance = double.infinity;
      const double recognitionThreshold = 0.6;

      for (var faculty in _registeredFaculty) {
        double distance = _faceRecognitionService.compareEmbeddings(
            capturedEmbeddings, faculty.embeddings);

        if (distance < lowestDistance) {
          lowestDistance = distance;
          bestMatchFacultyId = faculty.facultyId;
        }
      }

      if (lowestDistance <= recognitionThreshold && bestMatchFacultyId != null) {
        final AttendanceRecord record = AttendanceRecord(
          facultyId: bestMatchFacultyId,
          timestamp: DateTime.now(),
          status: 'present',
        );
        await _dbHelper.insertAttendance(record);
        setState(() => _recognizedFacultyId = bestMatchFacultyId);
        _showResultDialog(
            'Attendance Marked',
            'Successfully marked present for faculty ID: $bestMatchFacultyId. (Distance: ${lowestDistance.toStringAsFixed(2)})');
      } else {
        _showResultDialog('Not Recognized',
            'Could not recognize the faculty member. Best match distance: ${lowestDistance.toStringAsFixed(2)}');
      }
    } catch (e) {
      _showResultDialog('Error', 'An error occurred during recognition: $e');
    } finally {
      setState(() => _working = false);
    }
  }

  void _showResultDialog(String title, String content) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  Widget _preview() {
    if (_image == null) {
      return Container(
        height: 240,
        decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(12)),
        child: const Center(
            child: Text('No photo yet')),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: kIsWeb
          ? Image.network(_image!.path,
          height: 240, width: double.infinity, fit: BoxFit.cover)
          : Image.file(File(_image!.path),
          height: 240, width: double.infinity, fit: BoxFit.cover),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Take Attendance'),
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(18)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _preview(),
              const SizedBox(height: 16),
              if (_recognizedFacultyId != null)
                Text(
                  'Recognized Faculty ID: $_recognizedFacultyId',
                  style: const TextStyle(color: Colors.green, fontSize: 16),
                ),
              const SizedBox(height: 16),
              GradientElevatedButton(
                icon: Icons.camera,
                label: _working ? 'Working...' : 'Capture & Recognize',
                onPressed: _captureAndRecognize,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
