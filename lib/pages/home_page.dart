import 'package:flutter/material.dart';

// Widget Imports
import 'package:ati2/widgets/gradient_elevated_button.dart';

// Page Imports
import 'package:ati2/pages/register_page.dart';
import 'package:ati2/pages/attendance_page.dart';
import 'package:ati2/pages/attendance_records_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C2B),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 20)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Face Attendance',
                style: TextStyle(
                    color: Color(0xFF7B61FF),
                    fontSize: 28,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              const Text(
                'Smart facial recognition attendance system',
                style: TextStyle(color: Color(0xFFA0A0B2)),
              ),
              const SizedBox(height: 24),
              GradientElevatedButton(
                icon: Icons.person_add,
                label: 'Register Student',
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const RegisterPage())),
              ),
              const SizedBox(height: 12),
              GradientElevatedButton(
                icon: Icons.how_to_reg,
                label: 'Take Attendance',
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const AttendancePage())),
              ),
              const SizedBox(height: 12),
              GradientElevatedButton(
                icon: Icons.list_alt,
                label: 'View Attendance',
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => AttendanceRecordsPage())),
              ),
              const SizedBox(height: 18),
              const Text(
                'Made with ❤️ by Gen Z Devs',
                style: TextStyle(color: Color(0xFFA0A0B2), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
