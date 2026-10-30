import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:academy_crm/features/inquiries/domain/inquiry_model.dart';
import 'package:academy_crm/features/inquiries/presentation/inquiries_screen.dart';
import 'package:academy_crm/features/inquiries/data/inquiry_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MockInquiryRepo extends Fake implements InquiryRepository {
  @override
  Future<void> updateStatus(String id, InquiryStatus newStatus, {DateTime? followUpDate}) async {}
  @override
  Future<void> updateFollowUpDate(String id, DateTime? date) async {}
  @override
  Future<void> updateRemarks(String id, String remarks) async {}
  @override
  Future<void> deleteInquiry(String id, String name) async {}
}

void main() {
  final testInquiries = [
    Inquiry(
      id: '1',
      name: 'Aditya Narendra Ambekar With Long Name',
      areaCity: 'Shivajinagar Deccan Gymkhana, Pune',
      phone: '+91 98765 43210',
      email: 'aditya.ambekar@example.com',
      status: InquiryStatus.followUp,
      followUpDate: DateTime.now(),
      remarks: 'Interested in evening advanced batch, requested complete fee syllabus brochure.',
      createdAt: DateTime.now(),
    ),
    Inquiry(
      id: '2',
      name: 'Priya Sharma',
      areaCity: 'Kothrud, Pune Maharashtra',
      phone: '+91 91234 56789',
      email: 'priya@example.com',
      status: InquiryStatus.trialScheduled,
      followUpDate: DateTime.now().add(const Duration(days: 2)),
      remarks: 'Trial class scheduled for Monday 5 PM.',
      createdAt: DateTime.now(),
    ),
    Inquiry(
      id: '3',
      name: 'Rohan Deshmukh',
      areaCity: 'Aundh',
      phone: '+91 99999 88888',
      email: 'rohan@example.com',
      status: InquiryStatus.notInterested,
      remarks: 'Looking for morning online batch.',
      createdAt: DateTime.now(),
    ),
  ];

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        inquiriesStreamProvider.overrideWith((ref) => Stream.value(testInquiries)),
        inquiryRepositoryProvider.overrideWithValue(MockInquiryRepo()),
      ],
      child: const MaterialApp(
        home: InquiriesScreen(),
      ),
    );
  }

  testWidgets('Renders properly on small mobile (320x640)', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Renders properly on standard mobile (360x800)', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Renders properly on large mobile (414x896)', (tester) async {
    tester.view.physicalSize = const Size(414, 896);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Renders properly on tablet portrait (768x1024)', (tester) async {
    tester.view.physicalSize = const Size(768, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Renders properly on desktop widescreen (1440x900)', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
