// file: C:/Users/doshi/AndroidStudioProjects/attendence/lib/pages/edit_faculty_page.dart
import 'package:flutter/material.dart';
import '../local_database_helper.dart'; // For Faculty model and DatabaseHelper
import '../main.dart'; // For SimpleElevatedButton

class EditFacultyPage extends StatefulWidget {
  final Faculty faculty; // The faculty to be edited

  const EditFacultyPage({super.key, required this.faculty});

  @override
  State<EditFacultyPage> createState() => _EditFacultyPageState();
}

class _EditFacultyPageState extends State<EditFacultyPage> {
  late TextEditingController _nameCtrl;
  late TextEditingController _facultyIdCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.faculty.name);
    _facultyIdCtrl = TextEditingController(text: widget.faculty.facultyId);
  }

  Future<void> _updateFaculty() async {
    final newName = _nameCtrl.text.trim();
    final newFacultyId = _facultyIdCtrl.text.trim();

    if (newName.isEmpty || newFacultyId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and Faculty ID cannot be empty.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final updatedFaculty = Faculty(
        id: widget.faculty.id, // Keep the original ID
        name: newName,
        facultyId: newFacultyId,
        embeddings: widget.faculty.embeddings, // Keep original embeddings
        registrationDate: widget.faculty.registrationDate, // Keep original date
      );

      await DatabaseHelper().updateFaculty(updatedFaculty);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Faculty Updated Successfully!')));
      Navigator.pop(context); // Go back to faculty list
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error updating faculty: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _facultyIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Faculty'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    filled: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _facultyIdCtrl,
                  decoration: InputDecoration(
                    labelText: 'Faculty ID',
                    filled: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                SimpleElevatedButton(
                  icon: Icons.save,
                  label: _loading ? 'Saving...' : 'Update Faculty',
                  onPressed: _loading ? null : _updateFaculty,
                ),
                // Note: Re-capturing faces for editing embeddings is a complex task
                // and would require similar logic to RegisterPage's image capture.
                // For simplicity, this page only allows editing name and ID.
                // If embeddings need to be changed, the admin might delete and re-register.
              ],
            ),
          ),
        ),
      ),
    );
  }
}