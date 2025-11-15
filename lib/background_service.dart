import 'package:workmanager/workmanager.dart';
// Ensure this import path is correct for your project structure

import 'package:flutter/foundation.dart';

import 'local_database_helper.dart'; // For debugPrint

const markAbsentTask = "markAbsentTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == markAbsentTask) {
      try {
        debugPrint('Workmanager task "$markAbsentTask" started.');
        final dbHelper = DatabaseHelper();
        // ====================================================================
        // THIS IS THE FIX: Call the correctly named method
        // ====================================================================
        await dbHelper.markAbsentForUnmarkedFaculty();
        debugPrint('Workmanager task "$markAbsentTask" completed successfully.');
        return Future.value(true);
      } catch (e) {
        debugPrint('Workmanager task "$markAbsentTask" failed: $e');
        return Future.value(false);
      }
    }
    debugPrint('Workmanager task "$task" received, but not handled.');
    return Future.value(true);
  });
}