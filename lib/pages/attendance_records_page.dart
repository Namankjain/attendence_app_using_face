import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Local imports
// Ensure this import path is correct for your project structure.

import '../local_database_helper.dart';

class AttendanceRecordsPage extends StatelessWidget {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  AttendanceRecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Records'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 4,
      ),
      body: FutureBuilder<List<AttendanceRecordWithFacultyName>>(
        // ====================================================================
        // THIS IS THE CRITICAL FIX for "The argument type 'Future<List<AttendanceRecord>>'
        // can't be assigned to the parameter type 'Future<List<AttendanceRecordWithFacultyName>>?'."
        // We are now calling the correct method that returns the expected type.
        // ====================================================================
        future: _dbHelper.getAttendanceRecordsWithFacultyNames(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // Log the error for debugging
            debugPrint('Error loading attendance records: ${snapshot.error}');
            return Center(child: Text('Failed to load records: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No attendance records found.'));
          }

          final records = snapshot.data!;

          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final formattedDate = DateFormat.yMMMd().add_jms().format(record.timestamp);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.facultyName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Faculty ID: ${record.facultyId}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Attendance Time: $formattedDate",
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          record.status.toUpperCase(),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: record.status.toLowerCase() == 'present'
                                ? Colors.green[700]
                                : Colors.red[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}