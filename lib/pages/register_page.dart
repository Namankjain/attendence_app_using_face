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

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameCtrl = TextEditingController();
  final _facultyIdCtrl = TextEditingController();
  List<XFile> _images = [];
  bool _loading = false;
  final int requiredShots = 3;

  final FaceRecognitionService _faceRecognitionService =
      FaceRecognitionService();
  final FaceDetector _faceDetector =
      FaceDetector(options: FaceDetectorOptions());
  final ImagePicker _picker = ImagePicker();


  @override
  void initState() {
    super.initState();
    _faceRecognitionService.loadModel();
  }

  Future<void> _pickImageFromCamera() async {
    if (_images.length >= requiredShots) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('You have already captured $requiredShots shots.')),
      );
      return;
    }
    final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80, maxWidth: 600);
    if (image != null) {
      setState(() {
        _images.add(image);
      });
    }
  }

  void _showErrorDialog(String title, String content) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final facultyId = _facultyIdCtrl.text.trim();
    if (name.isEmpty || facultyId.isEmpty || _images.length < requiredShots) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Enter name, faculty ID and take $requiredShots photos.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      List<List<double>> allEmbeddings = [];

      for (XFile imageFile in _images) {
        final inputImage = InputImage.fromFilePath(imageFile.path);
        final List<Face> faces = await _faceDetector.processImage(inputImage);

        if (faces.isEmpty) {
          _showErrorDialog('Face Detection Failed',
              'No face detected in one of the images. Please retake the photos.');
          setState(() => _loading = false);
          return;
        }

        final imageBytes = await imageFile.readAsBytes();
        final img.Image? image = img.decodeImage(imageBytes);

        if (image != null) {
          final Face face = faces.first;
          final Rect boundingBox = face.boundingBox;
          final croppedImage = img.copyCrop(
            image,
            x: boundingBox.left.toInt(),
            y: boundingBox.top.toInt(),
            width: boundingBox.width.toInt(),
            height: boundingBox.height.toInt(),
          );
          List<double>? embeddings =
              _faceRecognitionService.getEmbeddings(croppedImage);
          allEmbeddings.add(embeddings!);
        }
      }

      if (allEmbeddings.isEmpty) {
        throw Exception("Could not generate face embeddings.");
      }

      List<double> averageEmbeddings =
          List.filled(allEmbeddings.first.length, 0.0);
      for (var embedding in allEmbeddings) {
        for (int i = 0; i < embedding.length; i++) {
          averageEmbeddings[i] += embedding[i];
        }
      }
      for (int i = 0; i < averageEmbeddings.length; i++) {
        averageEmbeddings[i] /= allEmbeddings.length;
      }

      final allFaculty = await DatabaseHelper().getAllFacultyWithEmbeddings();
      const double recognitionThreshold = 0.4;

      for (var faculty in allFaculty) {
        double distance = _faceRecognitionService.compareEmbeddings(
            averageEmbeddings, faculty.embeddings);
        if (distance < recognitionThreshold) {
          _showErrorDialog('Registration Failed',
              'This faculty seems to be already registered as ${faculty.name} (Faculty ID: ${faculty.facultyId}). Distance: ${distance.toStringAsFixed(2)}');
          setState(() => _loading = false);
          return;
        }
      }

      final faculty = Faculty(
          name: name,
          facultyId: facultyId,
          embeddings: averageEmbeddings,
          registrationDate: DateTime.now());

      await DatabaseHelper().registerFaculty(faculty);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration Successful!')));
      setState(() {
        _images = [];
        _nameCtrl.clear();
        _facultyIdCtrl.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  void _removeImage(XFile file) {
    setState(() {
      _images.remove(file);
    });
  }

  Widget _previewImage(XFile file) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: kIsWeb
              ? Image.network(file.path,
                  fit: BoxFit.cover, width: 80, height: 80)
              : Image.file(File(file.path),
                  fit: BoxFit.cover, width: 80, height: 80),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: () => _removeImage(file),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _faceRecognitionService.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Faculty'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF0F0F1A),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: const Color(0xFF1C1C2B),
                borderRadius: BorderRadius.circular(18)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Name',
                    hintStyle: const TextStyle(color: Color(0xFFA0A0B2)),
                    filled: true,
                    fillColor: const Color(0xFF2A2A3B),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _facultyIdCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Faculty ID',
                    hintStyle: const TextStyle(color: Color(0xFFA0A0B2)),
                    filled: true,
                    fillColor: const Color(0xFF2A2A3B),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                Text('${_images.length} / $requiredShots shots taken',
                    style: const TextStyle(color: Color(0xFFA0A0B2))),
                const SizedBox(height: 12),
                GradientElevatedButton(
                  icon: Icons.camera_alt,
                  label: 'Open Camera',
                  onPressed: _pickImageFromCamera,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _images.map((file) => _previewImage(file)).toList(),
                ),
                const SizedBox(height: 12),
                GradientElevatedButton(
                  icon: Icons.check,
                  label: _loading ? 'Registering...' : 'Register',
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
