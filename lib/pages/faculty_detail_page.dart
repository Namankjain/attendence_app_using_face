import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../local_database_helper.dart';

class FacultyDetailPage extends StatelessWidget {
  final Faculty faculty;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  FacultyDetailPage({super.key, required this.faculty});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(faculty.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Faculty Name: ${faculty.name}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Faculty ID: ${faculty.facultyId}',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Registered On: ${DateFormat.yMMMd().format(faculty.registrationDate)}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            const Text(
              'Attendance History:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<AttendanceRecordWithFacultyName>>(
                future: _dbHelper.getAttendanceRecordsForFaculty(faculty.facultyId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No attendance records for this faculty.'));
                  }

                  final records = snapshot.data!;
                  return ListView.builder(
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final record = records[index];
                      final formattedDate = DateFormat.yMMMd().add_jms().format(record.timestamp);
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text('Date: $formattedDate'),
                          trailing: Text(
                            record.status.toUpperCase(),
                            style: TextStyle(
                              color: record.status == 'present' ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
