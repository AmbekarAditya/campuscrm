import 'package:flutter/material.dart';
import 'widgets/booking_card.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final List<({String timeSlot, String student, String purpose})> _bookings = [
    (
      timeSlot: '10:00 AM',
      student: 'Ananya Verma',
      purpose: '1-on-1 Doubt Clearing Session • Room B',
    ),
    (
      timeSlot: '12:00 PM',
      student: 'Karan Patel',
      purpose: 'Practice Lab / Model Booking • Station 3',
    ),
    (
      timeSlot: '03:00 PM',
      student: 'Meera Joshi',
      purpose: 'Shared Practice Room • Assessment Prep',
    ),
  ];

  Future<void> _showBookSlotDialog() async {
    final timeCtrl = TextEditingController(text: '05:00 PM');
    final studentCtrl = TextEditingController();
    final purposeCtrl =
        TextEditingController(text: '1-on-1 Session • Shared Room A');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Book Time Slot / Room'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: timeCtrl,
                  decoration: const InputDecoration(labelText: 'Time Slot'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: studentCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Student Assigned *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: purposeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Service / Purpose (1-on-1, Room, Model)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (studentCtrl.text.trim().isEmpty) return;
                setState(() {
                  _bookings.add((
                    timeSlot: timeCtrl.text.trim(),
                    student: studentCtrl.text.trim(),
                    purpose: purposeCtrl.text.trim(),
                  ));
                });
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Book Slot'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings & Appointments'),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _showBookSlotDialog,
              icon: const Icon(Icons.add_alarm_rounded),
              label: const Text('Book Slot'),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _bookings.length,
        itemBuilder: (context, index) {
          final item = _bookings[index];
          return BookingCard(
            timeSlot: item.timeSlot,
            studentAssigned: item.student,
            servicePurpose: item.purpose,
          );
        },
      ),
    );
  }
}
