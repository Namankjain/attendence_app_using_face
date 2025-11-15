import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class MultiCapturePage extends StatefulWidget {
  const MultiCapturePage({super.key});

  @override
  State<MultiCapturePage> createState() => _MultiCapturePageState();
}

class _MultiCapturePageState extends State<MultiCapturePage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  final List<XFile> _images = [];
  final int _requiredShots = 3;
  bool _isInitializing = true;
  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 2.0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      final camera = _cameras!.firstWhere(
            (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _controller!.initialize();
      _minZoom = await _controller!.getMinZoomLevel();
      _maxZoom = await _controller!.getMaxZoomLevel();
      setState(() => _isInitializing = false);
    }
  }

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }
    try {
      final XFile image = await _controller!.takePicture();
      setState(() {
        _images.add(image);
      });
      if (_images.length == _requiredShots) {
        if (!mounted) return;
        Navigator.pop(context, _images);
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Capture $_requiredShots Shots'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CameraPreview(_controller!),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text(
                  '${_images.length} / $_requiredShots shots taken',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.zoom_out, size: 36),
                      onPressed: () async {
                        final newZoom = (_currentZoom - 0.1).clamp(_minZoom, _maxZoom);
                        await _controller!.setZoomLevel(newZoom);
                        setState(() {
                          _currentZoom = newZoom;
                        });
                      },
                    ),
                    FloatingActionButton.large(
                      onPressed: _capture,
                      child: const Icon(Icons.camera_alt),
                    ),
                    IconButton(
                      icon: const Icon(Icons.zoom_in, size: 36),
                      onPressed: () async {
                        final newZoom = (_currentZoom + 0.1).clamp(_minZoom, _maxZoom);
                        await _controller!.setZoomLevel(newZoom);
                        setState(() {
                          _currentZoom = newZoom;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
