import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:academy_crm/features/inquiries/domain/inquiry_model.dart';
import 'package:academy_crm/features/inquiries/presentation/widgets/inquiry_card.dart';

void main() {
  testWidgets('Test InquiryCard on mobile screen (360x800)', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final testInquiry = Inquiry(
      id: '1',
      name: 'Aditya Narendra Ambekar',
      areaCity: 'Shivajinagar, Pune',
      phone: '+91 98765 43210',
      email: 'aditya@example.com',
      status: InquiryStatus.followUp,
      followUpDate: DateTime.now(),
      remarks: 'Interested in evening batch, requested syllabus copy.',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: InquiryCard(
              inquiry: testInquiry,
              onStatusChanged: (_) {},
              onRemarksSaved: (_) {},
              onFollowUpDateChanged: (_) {},
              onDelete: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
