import 'package:flutter/material.dart';

class StudentProfileScreen extends StatelessWidget {
  final String studentName;
  final String phone;
  final String email;
  final String assignedBatch;
  final int attendanceDaysPresent;
  final int attendanceTotalDays;

  const StudentProfileScreen({
    super.key,
    required this.studentName,
    required this.phone,
    required this.email,
    required this.assignedBatch,
    required this.attendanceDaysPresent,
    required this.attendanceTotalDays,
  });

  @override
  Widget build(BuildContext context) {
    final attendancePercent = attendanceTotalDays == 0
        ? 0
        : ((attendanceDaysPresent / attendanceTotalDays) * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    studentName,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(
                      assignedBatch,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4338CA),
                      ),
                    ),
                    backgroundColor: const Color(0xFFE0E7FF),
                  ),
                  const Divider(height: 32),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.phone_outlined),
                    title: const Text('Phone Number'),
                    subtitle: Text(phone),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('Email Address'),
                    subtitle: Text(email),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_available_outlined),
                    title: const Text('Attendance Record'),
                    subtitle: Text(
                      '$attendanceDaysPresent / $attendanceTotalDays classes attended ($attendancePercent%)',
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Certificate generator placeholder triggered.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.workspace_premium_outlined),
                      label: const Text('Generate Certificate'),
                    ),
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
