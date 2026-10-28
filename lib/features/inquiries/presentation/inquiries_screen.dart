import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/inquiry_repository.dart';
import '../domain/inquiry_model.dart';
import 'widgets/inquiry_card.dart';

class InquiriesScreen extends ConsumerWidget {
  const InquiriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inquiriesAsync = ref.watch(inquiriesStreamProvider);
    final selectedFilter = ref.watch(inquiryStatusFilterProvider);
    final repository = ref.read(inquiryRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inquiries & Lead Management'),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => _showAddInquiryDialog(context, repository),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('New Inquiry'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // High-visibility status filter bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All Leads'),
                    selected: selectedFilter == null,
                    onSelected: (_) => ref
                        .read(inquiryStatusFilterProvider.notifier)
                        .state = null,
                  ),
                  const SizedBox(width: 10),
                  ...InquiryStatus.values.map((status) {
                    final isSelected = selectedFilter == status;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        label: Text(status.label),
                        selected: isSelected,
                        selectedColor: status.backgroundColor,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? status.foregroundColor
                              : const Color(0xFF334155),
                        ),
                        onSelected: (selected) {
                          ref.read(inquiryStatusFilterProvider.notifier).state =
                              selected ? status : null;
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Inquiries List / Responsive Tablet Grid
            Expanded(
              child: inquiriesAsync.when(
                data: (inquiries) {
                  final filtered = selectedFilter == null
                      ? inquiries
                      : inquiries
                          .where((item) => item.status == selectedFilter)
                          .toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text(
                        'No inquiries found for this filter.',
                        style: TextStyle(fontSize: 17, color: Color(0xFF64748B)),
                      ),
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 900;
                      if (isWide) {
                        return GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 8,
                            mainAxisExtent: 265,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final inquiry = filtered[index];
                            return InquiryCard(
                              inquiry: inquiry,
                              onStatusChanged: (newStatus) =>
                                  repository.updateStatus(inquiry.id, newStatus),
                              onRemarksSaved: (remarks) =>
                                  repository.updateRemarks(inquiry.id, remarks),
                            );
                          },
                        );
                      }

                      return ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final inquiry = filtered[index];
                          return InquiryCard(
                            inquiry: inquiry,
                            onStatusChanged: (newStatus) =>
                                repository.updateStatus(inquiry.id, newStatus),
                            onRemarksSaved: (remarks) =>
                                repository.updateRemarks(inquiry.id, remarks),
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Text('Error loading inquiries: $err'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddInquiryDialog(
    BuildContext context,
    InquiryRepository repository,
  ) async {
    final nameCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final remarksCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add New Inquiry'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name *'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: areaCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Area / City *'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration:
                        const InputDecoration(labelText: 'Phone / WhatsApp *'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: remarksCtrl,
                    maxLines: 2,
                    decoration:
                        const InputDecoration(labelText: 'Initial Remarks'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                await repository.addInquiry(
                  Inquiry(
                    id: '',
                    name: nameCtrl.text.trim(),
                    areaCity: areaCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    status: InquiryStatus.newLead,
                    remarks: remarksCtrl.text.trim(),
                    createdAt: DateTime.now(),
                  ),
                );
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Save Lead'),
            ),
          ],
        );
      },
    );
  }
}
