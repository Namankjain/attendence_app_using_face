// file: C:/Users/doshi/AndroidStudioProjects/attendence/lib/pages/admin_home_page.dart
import 'package:flutter/material.dart';
import '../main.dart'; // For SimpleElevatedButton and RegisterPage
import 'faculty_list_page.dart'; // We'll pass an isAdmin flag to this
import 'attendance_management_page.dart'; // The new attendance management page // The new attendance management page

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome, Admin!',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              SimpleElevatedButton(
                icon: Icons.person_add,
                label: 'Register New Faculty',
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const RegisterPage())),
              ),
              const SizedBox(height: 12),
              SimpleElevatedButton(
                icon: Icons.people,
                label: 'Manage Faculty',
                // Pass isAdmin: true to FacultyListPage
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const FacultyListPage(isAdmin: true))),
              ),
              const SizedBox(height: 12),
              SimpleElevatedButton(
                icon: Icons.list_alt,
                label: 'Manage Attendance',
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AttendanceManagementPage())),
              ),
            ],
          ),
        ),
      ),
    );
  }
}