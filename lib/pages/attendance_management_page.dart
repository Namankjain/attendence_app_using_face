// file: C:/Users/doshi/AndroidStudioProjects/attendence/lib/pages/attendance_management_page.dart
import 'package:flutter/material.dart';
import '../local_database_helper.dart'; // For Faculty and AttendanceRecord models
import 'package:intl/intl.dart'; // For date formatting

class AttendanceManagementPage extends StatefulWidget {
  const AttendanceManagementPage({super.key});

  @override
  State<AttendanceManagementPage> createState() =>
      _AttendanceManagementPageState();
}

class _AttendanceManagementPageState extends State<AttendanceManagementPage> {
  DateTime _selectedDate = DateTime.now();
  List<Faculty> _facultyList = [];
  Map<String, String> _attendanceStatus = {}; // facultyId -> status ('present', 'absent', 'not_recorded')
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    await _loadFaculty();
    await _loadAttendanceForDate();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadFaculty() async {
    _facultyList = await DatabaseHelper().getAllFacultyWithEmbeddings();
  }

  Future<void> _loadAttendanceForDate() async {
    final records = await DatabaseHelper().getAttendanceForDate(_selectedDate);
    _attendanceStatus.clear();
    for (var faculty in _facultyList) {
      final record = records.firstWhere(
            (rec) => rec.facultyId == faculty.facultyId,
        orElse: () => AttendanceRecord(
          facultyId: faculty.facultyId,
          timestamp: _selectedDate,
          status: 'not_recorded',
        ),
      );
      _attendanceStatus[faculty.facultyId] = record.status;
    }
  }

  Future<void> _updateAttendance(String facultyId, String status) async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });
    try {
      await DatabaseHelper().markAttendance(facultyId, _selectedDate, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Attendance for $facultyId updated to $status on ${DateFormat('yyyy-MM-dd').format(_selectedDate)}')),
      );
      await _loadAttendanceForDate(); // Reload attendance for the selected date
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update attendance: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _isLoading = true;
      });
      await _loadAttendanceForDate();
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'present':
        return 'Present';
      case 'absent':
        return 'Absent';
      default:
        return 'Not Recorded';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Attendance'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: Center(
        child: Container(
          width: 600, // Wider container for attendance management
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Attendance for: ${DateFormat('EEE, MMM d, yyyy').format(_selectedDate)}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : _facultyList.isEmpty
                  ? const Text('No faculty registered to manage attendance.')
                  : Expanded(
                child: ListView.builder(
                  itemCount: _facultyList.length,
                  itemBuilder: (context, index) {
                    final faculty = _facultyList[index];
                    final currentStatus =
                        _attendanceStatus[faculty.facultyId] ?? 'not_recorded';
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    faculty.name,
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    'ID: ${faculty.facultyId}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(currentStatus).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _getStatusText(currentStatus),
                                style: TextStyle(
                                  color: _getStatusColor(currentStatus),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            DropdownButton<String>(
                              value: currentStatus,
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  _updateAttendance(faculty.facultyId, newValue);
                                }
                              },
                              items: const <DropdownMenuItem<String>>[
                                DropdownMenuItem(
                                    value: 'present', child: Text('Mark Present')),
                                DropdownMenuItem(
                                    value: 'absent', child: Text('Mark Absent')),
                                DropdownMenuItem(
                                    value: 'not_recorded', child: Text('Clear Status')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}