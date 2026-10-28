import 'package:flutter/material.dart';
import 'student_profile_screen.dart';

class BatchListView extends StatelessWidget {
  const BatchListView({super.key});

  @override
  Widget build(BuildContext context) {
    final batches = [
      (
        name: 'Morning Foundation Batch A',
        schedule: 'Mon, Wed, Fri • 09:30 AM',
        activeStudents: 18,
        status: 'Active',
      ),
      (
        name: 'Advanced Practical Batch B',
        schedule: 'Tue, Thu, Sat • 11:30 AM',
        activeStudents: 12,
        status: 'Active',
      ),
      (
        name: 'Weekend Masterclass Cohort',
        schedule: 'Sat, Sun • 02:00 PM',
        activeStudents: 22,
        status: 'Filling Fast',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Students & Active Batches'),
        centerTitle: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: batches.length,
        itemBuilder: (context, index) {
          final batch = batches[index];
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(20),
              title: Text(
                batch.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${batch.schedule}  •  ${batch.activeStudents} Enrolled Students',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              trailing: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StudentProfileScreen(
                        studentName: 'Aarav Sharma',
                        phone: '+91 98765 43210',
                        email: 'aarav.sharma@example.com',
                        assignedBatch: batch.name,
                        attendanceDaysPresent: 26,
                        attendanceTotalDays: 28,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.people_alt_outlined),
                label: const Text('Sample Student'),
              ),
            ),
          );
        },
      ),
    );
  }
}
