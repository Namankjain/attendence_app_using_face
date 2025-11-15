# Face Attendance System

A modern, on-device Face Attendance System built with Flutter. This application provides a robust and privacy-focused solution for faculty registration, automatic attendance marking, and administrative oversight, all powered by a sleek, customizable user interface.

## Core Features

This application is designed to be a complete, self-contained attendance solution.

*   **Secure, On-Device Face Recognition:** All facial recognition processes, including detection and embedding comparison, happen directly on the user's device. No data is sent to external servers, ensuring user privacy and offline functionality.
*   **Robust Faculty Registration:**
    *   New faculty members are registered by capturing three distinct facial images.
    *   The app generates a unique 192-dimension facial embedding for each image.
    *   These three embeddings are then averaged to create a single, more generalized, and accurate facial signature for the faculty member, making recognition more resilient to variations in lighting and expression.
*   **Automatic & Swift Attendance Marking:**
    *   The camera opens directly to capture an image of the attendees.
    *   The system can detect multiple faces within a single image.
    *   For each detected face, it generates an embedding and compares it against the entire database of registered faculty using a highly efficient Euclidean distance algorithm.
    *   Recognized faculty members are automatically marked as 'present' for the current day, preventing duplicate entries.
*   **Comprehensive Management Tools:**
    *   **Attendance Records:** A detailed list of all attendance records, showing who was present/absent and when.
    *   **Faculty Management:** A complete list of all registered faculty members, with options for viewing details or managing their data (future scope).
    *   **Admin Login:** A dedicated admin login page, laying the groundwork for future role-based access and administrative functionalities.
*   **Customizable User Experience:**
    *   **Light & Dark Modes:** The app supports both light and dark themes, with a simple toggle option in the app bar. The theme is managed efficiently using the Provider state management solution.
    *   **Dynamic Backgrounds:** The home screen features dynamic background images (`assets/bg_light.png` for light theme, `assets/bg_dark.png` for dark theme) to create an immersive feel.
    *   **Gradient Buttons:** To enhance the visual appeal, the dark theme utilizes elegant, eye-catching gradient-styled buttons.
    *   **Consistent & Modern Typography:** The app uses the Google Fonts `Poppins` typeface throughout for a clean, modern, and highly readable user interface.
*   **Background Service Integration:** The app integrates `workmanager` to schedule and run background tasks. This is used to automatically mark any un-marked faculty as 'absent' at the end of each day, ensuring complete daily records.

## How It Works: The Technology Behind the Magic

1.  **Face Detection:** When an image is captured, Google's ML Kit Face Detection API is used to quickly and accurately identify the location and contours of all faces present in the image.
2.  **Face Cropping & Preprocessing:** The portion of the image containing each detected face is cropped. This cropped image is then resized to the model's required input size (112x112 pixels) and preprocessed into the correct format.
3.  **Embedding Generation (The "Face Signature"):** The preprocessed face image is fed into a pre-trained FaceNet TFLite model (`mobile_face_net.tflite`). This model outputs a 192-dimension vector (an "embedding"). This vector is a highly compressed, numerical representation of the unique features of that face.
4.  **Recognition & Comparison:** To recognize a face, its newly generated embedding is compared to the stored embeddings in the local database. This comparison is done by calculating the **Euclidean distance** between the two vectors. If the distance is below a predefined threshold, the faces are considered a match.

## Technologies Used

*   **Flutter:** A cross-platform UI toolkit for building beautiful, natively compiled applications for mobile, web, and desktop from a single codebase.
*   **Google ML Kit Face Detection:** Provides a high-performance, on-device API for robust face detection capabilities.
*   **TFLite Flutter:** A plugin for running TensorFlow Lite models on-device, enabling efficient machine learning inference (used here for the FaceNet model).
*   **Image Picker:** A plugin for capturing images from the device's camera.
*   **Image Package:** A powerful library for image manipulation, used here for cropping and resizing facial images before processing.
*   **Provider:** A simple and efficient solution for state management, used for toggling between light and dark themes.
*   **Google Fonts:** A library of high-quality, open-source fonts, used here for the `Poppins` typeface.
*   **Workmanager:** A plugin for scheduling and running deferrable, asynchronous background tasks on Android.
*   **SQFlite:** A robust plugin for local database storage using SQLite, used for storing all faculty data and attendance records.

## Getting Started

To get a local copy up and running, follow these steps.

### Prerequisites

*   An up-to-date Flutter SDK.
*   Android Studio or VS Code with the Flutter and Dart plugins installed.
*   An Android device or emulator to run the app. A physical device is recommended as facial recognition can be slow on emulators.

### Installation

1.  Clone the repository (replace `[repository_url]` with the actual URL):
    ```bash
    git clone [repository_url]
    cd attendence
    ```
2.  Install all the required Flutter dependencies:
    ```bash
    flutter pub get
    ```
3.  Ensure your `assets/` folder is correctly configured in your `pubspec.yaml` file:
    ```yaml
    flutter:
      uses-material-design: true
      assets:
        - assets/
    ```
    *(Make sure `bg_dark.png`, `bg_light.png`, `logo.png`, and `mobile_face_net.tflite` are present in the `assets/` folder.)*

4.  If you've made changes to the app icon (`assets/logo.png`), regenerate the launcher icons:
    ```bash
    flutter pub run flutter_launcher_icons:main
    ```

### Running the App

```bash
flutter run
```
Ensure you have a device or emulator running and selected.

## Project Structure

*   `lib/main.dart`: The main application entry point. This file configures the `MaterialApp`, defines the light and dark themes, sets up the `ThemeNotifier` with Provider, and contains the `HomePage` widget.
*   `lib/pages/`: This directory contains all the distinct UI pages (screens) of the application, such as `register_page.dart`, `attendance_page.dart`, `admin_login_page.dart`, `faculty_list_page.dart`, and `attendance_records_page.dart`.
*   `lib/face_recognition_service.dart`: The core of the facial recognition logic. This service class encapsulates model loading, face detection, embedding generation, and the embedding comparison algorithm.
*   `lib/local_database_helper.dart`: The single source of truth for all database operations. It manages table creation, migrations, and all CRUD (Create, Read, Update, Delete) operations for faculty and attendance records.
*   `lib/background_service.dart`: Contains the background task definitions using the `workmanager` package.
*   `assets/`: Stores all static assets, including images (`bg_dark.png`, `bg_light.png`, `logo.png`) and the TFLite model (`mobile_face_net.tflite`).

## Future Scope

*   **Cloud Synchronization:** Syncing faculty and attendance data with a cloud backend (like Firebase) to allow data persistence across multiple devices.
*   **Real-time Admin Dashboard:** A web-based dashboard for administrators to view attendance in real-time.
*   **Export Reports:** Functionality for admins to export attendance records to formats like CSV or PDF.
*   **Liveness Detection:** Integrating liveness detection to prevent spoofing attacks using photos or videos.
*   **Enhanced Analytics:** Providing more detailed analytics and visual reports on attendance trends.
