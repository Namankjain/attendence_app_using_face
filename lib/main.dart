import 'dart:io';
// import 'dart:math'; // Removed unused import
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

// Local imports
import 'local_database_helper.dart';
import 'face_recognition_service.dart';
import 'pages/attendance_records_page.dart';
import 'pages/faculty_list_page.dart';
import 'background_service.dart';

// NEW: Local imports for admin features
import 'pages/admin_login_page.dart';


// --- Theme Management ---
class ThemeNotifier with ChangeNotifier {
  ThemeMode _themeMode;

  ThemeNotifier(this._themeMode);

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode =
    _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

// Define a base text theme once to ensure consistent sizes/weights
final _baseTextTheme = GoogleFonts.poppinsTextTheme();

// MODIFIED: Refactored darkTheme for a deeper and more consistent dark mode look
final darkTheme = ThemeData(
  brightness: Brightness.dark,
  // Use a deep, almost black primary background
  scaffoldBackgroundColor: const Color(0xFF121212), // Solid dark background for pages without custom image
  primaryColor: Colors.limeAccent[400], // Keeps a vibrant accent color, aligning with gradient buttons
  colorScheme: ColorScheme.dark(
    primary: Colors.limeAccent[400]!, // Main accent color, aligning with gradient buttons
    secondary: Colors.lime[300]!,     // A slightly deeper lime for secondary elements
    surface: const Color(0xFF1E1E1E), // Card/dialog backgrounds - slightly lighter than scaffold
    error: Colors.redAccent,
    onPrimary: Colors.black,    // Text on limeAccent background
    onSecondary: Colors.white,  // Text on lime background
    onSurface: Colors.white70,  // Text on surface (cards, etc.)
    onError: Colors.black,
  ),
  textTheme: _baseTextTheme.apply(
    bodyColor: Colors.white70, // Apply a consistent light text color
    displayColor: Colors.white,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent, // AppBar is transparent to show background image
    foregroundColor: Colors.white, // Title and icons are white
    elevation: 0,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.limeAccent[400], // Use primary accent for button background
      foregroundColor: Colors.black,     // Text/icon on primary accent
      textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold), // Use Poppins for dark mode buttons
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      minimumSize: const Size(double.infinity, 50),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF2C2C2C), // Darker fill color for input fields
    labelStyle: GoogleFonts.poppins(color: Colors.white70),
    hintStyle: GoogleFonts.poppins(color: Colors.grey),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.limeAccent[400]!, width: 2),
    ),
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFF1E1E1E), // Match surface color
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
);

final lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Colors.indigo,
  scaffoldBackgroundColor: const Color(0xFFf0f2f5), // Solid light background for pages without custom image
  colorScheme: const ColorScheme.light(
    primary: Colors.indigo,
    secondary: Colors.indigoAccent,
    surface: Colors.white,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.black,
  ),
  textTheme: _baseTextTheme.apply(
    bodyColor: Colors.black, // Standard text color for light theme
    displayColor: Colors.black, // Standard display color for light theme
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: Colors.indigo,
      textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold), // Use Poppins for light mode buttons
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      minimumSize: const Size(double.infinity, 50),
    ),
  ),
);
// --------------------

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && Platform.isAndroid) {
    await Workmanager().initialize(
      callbackDispatcher,
      // isInDebugMode: false, // Deprecated, removed
    );
    await Workmanager().registerPeriodicTask(
      "1",
      "markAbsentTask",
      frequency: const Duration(days: 1),
      initialDelay: const Duration(hours: 23, minutes: 55),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
      ),
    );
  }
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(ThemeMode.system),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return MaterialApp(
      title: 'Face Attendance',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeNotifier.themeMode,
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDarkMode = themeNotifier.themeMode == ThemeMode.dark ||
        (themeNotifier.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent, // Explicitly transparent for HomePage to show image
      appBar: AppBar(
        title: const Text('Face Attendance'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeNotifier.toggleTheme(),
          )
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill( // Ensures the background image covers the entire screen
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                      isDarkMode ? 'assets/bg_dark.png' : 'assets/bg_light.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withAlpha((255 * 0.85).round()),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 20)
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Face Attendance',
                    style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 28,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Smart facial recognition attendance system',
                    style: Theme.of(context).textTheme.bodyMedium, // Use theme text style
                  ),
                  const SizedBox(height: 24),
                  SimpleElevatedButton(
                    icon: Icons.person_add,
                    label: 'Register Faculty',
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterPage())),
                  ),
                  const SizedBox(height: 12),
                  SimpleElevatedButton(
                    icon: Icons.how_to_reg,
                    label: 'Take Attendance',
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AttendancePage())),
                  ),
                  const SizedBox(height: 12),
                  SimpleElevatedButton(
                    icon: Icons.list_alt,
                    label: 'View Attendance',
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => AttendanceRecordsPage())),
                  ),
                  const SizedBox(height: 12),
                  SimpleElevatedButton(
                    icon: Icons.people,
                    label: 'View Faculty',
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const FacultyListPage())),
                  ),
                  const SizedBox(height: 24), // Add some space
                  // NEW: Admin Login Button
                  SimpleElevatedButton(
                    icon: Icons.admin_panel_settings,
                    label: 'Admin Login',
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AdminLoginPage())),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Custom Button Widget ---
class SimpleElevatedButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const SimpleElevatedButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDarkMode = themeNotifier.themeMode == ThemeMode.dark ||
        (themeNotifier.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    if (isDarkMode) {
      return Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFBFFF00), Color(0xFF7FFF00)], // Lime green gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.black), // Black icons for contrast
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      // Existing ElevatedButton style for light mode
      final ButtonStyle? defaultButtonStyle = Theme.of(context).elevatedButtonTheme.style;

      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: defaultButtonStyle,
      );
    }
  }
}


// --- Register Page ---
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _facultyIdController = TextEditingController();
  final _faceRecognitionService = FaceRecognitionService();
  final _dbHelper = DatabaseHelper();

  final List<File> _capturedImages = []; // Added 'final'
  final List<List<double>> _rawEmbeddings = []; // Added 'final'
  List<double>? _averagedEmbeddings;
  int _currentPhotoIndex = 0; // Tracks which photo (0, 1, or 2) is next

  bool _loading = false;
  String _status = 'Loading face recognition model...'; // Initial status while model loads
  bool _modelLoaded = false; // To track model loading status

  @override
  void initState() {
    super.initState();
    _initializeService(); // Call async init method
  }

  // Explicitly load the model and update UI
  Future<void> _initializeService() async {
    if (_modelLoaded && !_loading) return; // Already loaded and not loading

    setState(() {
      _loading = true;
      _status = 'Loading face recognition model...';
      _modelLoaded = false; // Reset in case of re-initialization attempt
    });
    try {
      await _faceRecognitionService.loadModel();
      if (mounted) {
        setState(() {
          _modelLoaded = true; // Set to true ONLY on success
          _loading = false;
          _status = 'Model loaded. Take your first photo (1/3)';
        });
      }
    }
    catch (e) {
      // print('Error loading model in RegisterPage: $e'); // Commented out print statement
      if (mounted) {
        setState(() {
          _modelLoaded = false; // Ensure it's false on failure
          _loading = false;
          _status = 'Failed to load face recognition model. Error: ${e.toString()}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load face recognition model. Check console for details.')),
        );
      }
    }
  }

  // Helper to average embeddings
  List<double> _averageEmbeddings(List<List<double>> embeddingsList) {
    if (embeddingsList.isEmpty) return [];
    if (embeddingsList.first.isEmpty) return [];

    int embeddingSize = embeddingsList.first.length;
    List<double> sumEmbeddings = List.filled(embeddingSize, 0.0);

    for (List<double> embeddings in embeddingsList) {
      for (int i = 0; i < embeddingSize; i++) {
        sumEmbeddings[i] += embeddings[i];
      }
    }

    return sumEmbeddings.map((sum) => sum / embeddingsList.length).toList();
  }


  Future<void> _pickImage() async {
    // Disable interaction if loading, model not loaded, or all photos taken
    if (_loading || !_modelLoaded || _currentPhotoIndex >= 3) {
      if (!_modelLoaded) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Face recognition model is not loaded.')),
        );
      } else if (_currentPhotoIndex >= 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All 3 photos already taken.')),
        );
      }
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile == null) {
      return; // User cancelled camera
    }

    setState(() {
      _loading = true;
      _status = 'Processing photo ${_currentPhotoIndex + 1}/3...';
      // Reset if starting fresh after some previous failures
      if (_currentPhotoIndex == 0 && _capturedImages.isNotEmpty) {
        _capturedImages.clear();
        _rawEmbeddings.clear();
        _averagedEmbeddings = null;
        // _currentPhotoIndex remains 0 to retake first photo
      }
    });

    try {
      final inputImage = InputImage.fromFilePath(pickedFile.path);
      final faces = await _faceRecognitionService.detectFaces(inputImage);

      if (faces.length == 1) { // Exactly one face required for registration
        final detectedFace = faces.first;
        final img.Image? originalImage = await _faceRecognitionService.loadImage(pickedFile.path);

        if (originalImage != null) {
          final faceData = _faceRecognitionService.getFaceData(originalImage, detectedFace);
          if (faceData != null) {
            final embeddings = _faceRecognitionService.getEmbeddings(faceData);

            if (mounted) {
              setState(() {
                _capturedImages.add(File(pickedFile.path));
                _rawEmbeddings.add(embeddings);
                _currentPhotoIndex++; // Only increment on successful processing

                if (_currentPhotoIndex < 3) {
                  _status = 'Photo $_currentPhotoIndex/3 taken. Take photo ${_currentPhotoIndex + 1}/3.'; // Fixed interpolation
                } else {
                  _status = 'All 3 photos taken. Calculating final embedding.';
                  _averagedEmbeddings = _averageEmbeddings(_rawEmbeddings);
                  _status = 'Ready to register.';
                }
                _loading = false;
              });
            }
          } else {
            throw Exception('Failed to crop face data. Ensure face is fully visible within the frame.');
          }
        } else {
          throw Exception('Failed to load image from file. The file might be corrupted or inaccessible.');
        }
      } else {
        // No face or multiple faces detected for the current photo
        throw Exception('Found ${faces.length} faces. Exactly one face is required for registration.');
      }

    } catch (e) { // Removed stack from catch block
      // print('Error during image processing for photo ${_currentPhotoIndex + 1}: $e'); // Commented out print statement
      if (mounted) {
        setState(() {
          _status = 'Error processing photo ${_currentPhotoIndex + 1}/3: ${e.toString()}. Please retry.';
          _loading = false;
          // Clear any partially collected data for this specific failed attempt
          if (_currentPhotoIndex > 0 && _rawEmbeddings.length == _currentPhotoIndex ) {
            _rawEmbeddings.removeLast(); // Remove potentially bad embedding
            _capturedImages.removeLast(); // Remove the image
            _currentPhotoIndex--; // Decrement to retry this photo index
          } else if (_currentPhotoIndex == 0) { // If first photo failed, reset completely
            _capturedImages.clear();
            _rawEmbeddings.clear();
            _averagedEmbeddings = null;
            _currentPhotoIndex = 0;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Processing Error: ${e.toString()}.')),
        );
      }
    }
  }

  Future<void> _registerFaculty() async {
    final name = _nameController.text.trim();
    final facultyId = _facultyIdController.text.trim();

    if (_loading || !_modelLoaded) return; // Prevent multiple submissions or submissions before model loads

    if (name.isEmpty || facultyId.isEmpty || _averagedEmbeddings == null || _capturedImages.length != 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please fill all fields and take 3 valid photos with one face each.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final newFaculty = Faculty(
        name: name,
        facultyId: facultyId,
        embeddings: _averagedEmbeddings!,
        registrationDate: DateTime.now(),
      );
      await _dbHelper.registerFaculty(newFaculty);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Faculty Registered Successfully!')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error registering faculty: $e')));
    }
    finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _facultyIdController.dispose();
    _faceRecognitionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Faculty'),
        // Use theme's AppBarTheme for consistent styling
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 20)
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(3, (index) {
                    return Container(
                      height: 100,
                      width: 100,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface, // Changed from background to surface
                          borderRadius: BorderRadius.circular(12),
                          border: _currentPhotoIndex == index && _currentPhotoIndex < 3
                              ? Border.all(color: Theme.of(context).primaryColor, width: 3)
                              : null
                      ),
                      child: _capturedImages.length > index
                          ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_capturedImages[index],
                              width: 100, height: 100, fit: BoxFit.cover))
                          : Icon(
                        Icons.camera_alt,
                        size: 40,
                        color: Theme.of(context).colorScheme.onSurface, // Changed from onBackground to onSurface
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Text(_status, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface, // Use theme text style and override color
                )),
                const SizedBox(height: 12),
                SimpleElevatedButton(
                  icon: Icons.camera,
                  label: _currentPhotoIndex < 3
                      ? (_loading ? 'Processing...' : 'Take Photo (${_currentPhotoIndex + 1}/3)')
                      : 'All photos taken',
                  onPressed: _loading || !_modelLoaded || _currentPhotoIndex >= 3 ? null : _pickImage,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    filled: true,
                    // Border styling moved to InputDecorationTheme in main.dart
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _facultyIdController,
                  decoration: InputDecoration(
                    labelText: 'Faculty ID',
                    filled: true,
                    // Border styling moved to InputDecorationTheme in main.dart
                  ),
                ),
                const SizedBox(height: 20),
                SimpleElevatedButton(
                  icon: Icons.app_registration,
                  label: _loading ? 'Registering...' : 'Register',
                  onPressed: _loading || _averagedEmbeddings == null ? null : _registerFaculty,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Attendance Page ---
class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final _faceRecognitionService = FaceRecognitionService();
  final _dbHelper = DatabaseHelper();
  String _status = 'Loading face recognition model...';
  bool _loading = false;
  File? _image;
  // Removed _detectedFaculty as it's no longer needed for display
  bool _modelLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    if (_modelLoaded && !_loading) return;

    setState(() {
      _loading = true;
      _status = 'Loading face recognition model...';
      _modelLoaded = false;
    });
    try {
      await _faceRecognitionService.loadModel();
      if (mounted) {
        setState(() {
          _modelLoaded = true;
          _loading = false;
          _status = 'Model loaded. Please capture an image for attendance';
        });
      }
    }
    catch (e) {
      // print('Error loading model in AttendancePage: $e'); // Commented out print statement
      if (mounted) {
        setState(() {
          _modelLoaded = false;
          _loading = false;
          _status = 'Failed to load face recognition model. Error: ${e.toString()}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load face recognition model. Check console for details.')),
        );
      }
    }
  }

  Future<void> _captureImage() async {
    if (_loading || !_modelLoaded) {
      if (!_modelLoaded) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Face recognition model is not loaded.')),
        );
      }
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile == null) {
      return;
    }

    setState(() {
      _loading = true;
      _image = File(pickedFile.path);
      _status = 'Analyzing image and marking attendance...';
      // _detectedFaculty = []; // Removed
    });

    try {
      final allFaculty = await _dbHelper.getAllFacultyWithEmbeddings();
      if (allFaculty.isEmpty) {
        setState(() {
          _status = 'No faculty registered. Please register first.';
          _loading = false;
        });
        return;
      }

      final recognizedFaculty = await _faceRecognitionService
          .recognizeFacesInImage(pickedFile.path, allFaculty);

      if (recognizedFaculty.isNotEmpty) {
        for (var faculty in recognizedFaculty) {
          await _markAttendance(faculty);
        }
        setState(() {
          _status = '${recognizedFaculty.length} faculty member(s) automatically marked present.';
          _loading = false;
        });
      } else {
        setState(() {
          _status = 'No registered faculty found in the image. Please try again.';
          _loading = false;
        });
      }
    }
    catch (e) {
      // print('Error during attendance capture: $e'); // Commented out print statement
      if (!mounted) return;
      setState(() {
        _status = 'An error occurred: ${e.toString()}. Please ensure model is loaded.';
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}. Please try again.')),
      );
    }
  }

  Future<void> _markAttendance(Faculty faculty) async {
    final record = AttendanceRecord(
      facultyId: faculty.facultyId,
      timestamp: DateTime.now(),
      status: 'present',
    );
    await _dbHelper.insertAttendance(record);
    if (!mounted) return;
  }

  @override
  void dispose() {
    _faceRecognitionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Take Attendance'),
        // Use theme's AppBarTheme for consistent styling
      ),
      body: Center(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(18)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _image == null
                  ? Container(
                height: 250,
                width: 250,
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface, // Changed from background to surface
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.camera_alt,
                    size: 100, color: Theme.of(context).colorScheme.onSurface), // Changed from onBackground to onSurface
              )
                  : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_image!,
                      width: 250, height: 250, fit: BoxFit.cover)),
              const SizedBox(height: 16),
              Text(_status,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface)), // Use theme text style and override color
              const SizedBox(height: 16),
              SimpleElevatedButton(
                icon: Icons.camera,
                label: 'Capture Image',
                onPressed: _loading || !_modelLoaded ? null : _captureImage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}