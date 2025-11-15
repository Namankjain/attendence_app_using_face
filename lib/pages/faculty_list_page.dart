// file: C:/Users/doshi/AndroidStudioProjects/attendence/lib/pages/faculty_list_page.dart
import 'package:flutter/material.dart';
import '../local_database_helper.dart'; // Make sure this is imported
import 'edit_faculty_page.dart'; // NEW IMPORT

class FacultyListPage extends StatefulWidget {
  final bool isAdmin; // NEW: Flag to indicate admin access
  const FacultyListPage({super.key, this.isAdmin = false}); // NEW: Default to false

  @override
  State<FacultyListPage> createState() => _FacultyListPageState();
}

class _FacultyListPageState extends State<FacultyListPage> {
  List<Faculty> _facultyList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFaculty();
  }

  Future<void> _loadFaculty() async {
    setState(() {
      _isLoading = true;
    });
    final faculty = await DatabaseHelper().getAllFacultyWithEmbeddings();
    setState(() {
      _facultyList = faculty;
      _isLoading = false;
    });
  }

  // NEW: Method to confirm and delete faculty
  Future<void> _confirmDeleteFaculty(Faculty faculty) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Faculty'),
        content: Text('Are you sure you want to delete ${faculty.name} (ID: ${faculty.facultyId})? This action cannot be undone and will delete all associated attendance records.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await DatabaseHelper().deleteFaculty(faculty.facultyId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${faculty.name} deleted successfully!')),
        );
        _loadFaculty(); // Reload the list
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete faculty: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdmin ? 'Manage Faculty' : 'Registered Faculty'), // NEW
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _facultyList.isEmpty
          ? const Center(child: Text('No faculty registered yet.'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _facultyList.length,
        itemBuilder: (context, index) {
          final faculty = _facultyList[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row( // Changed to Row for actions
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          faculty.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text('ID: ${faculty.facultyId}'),
                        Text('Registered: ${faculty.registrationDate.toLocal().toString().split(' ')[0]}'),
                      ],
                    ),
                  ),
                  if (widget.isAdmin) ...[ // NEW: Admin actions
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditFacultyPage(faculty: faculty),
                          ),
                        );
                        _loadFaculty(); // Reload after editing
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDeleteFaculty(faculty),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}