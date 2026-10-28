import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/inquiry_repository.dart';
import '../domain/inquiry_model.dart';
import 'widgets/inquiry_card.dart';

class InquiriesScreen extends ConsumerStatefulWidget {
  const InquiriesScreen({super.key});

  @override
  ConsumerState<InquiriesScreen> createState() => _InquiriesScreenState();
}

class _InquiriesScreenState extends ConsumerState<InquiriesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inquiriesAsync = ref.watch(inquiriesStreamProvider);
    final selectedFilter = ref.watch(inquiryStatusFilterProvider);
    final searchQuery = ref.watch(inquirySearchQueryProvider);
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
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
              label: const Text('New Inquiry'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar at Top (Search by name, phone, area)
            TextField(
              controller: _searchCtrl,
              onChanged: (val) {
                ref.read(inquirySearchQueryProvider.notifier).state = val;
              },
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search leads by name, area, or phone number...',
                prefixIcon: const Icon(Icons.search_rounded, size: 22),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        tooltip: 'Clear Search',
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(inquirySearchQueryProvider.notifier).state =
                              '';
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
            const SizedBox(height: 10),

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
                  const SizedBox(width: 8),
                  ...InquiryStatus.values.map((status) {
                    final isSelected = selectedFilter == status;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(status.label),
                        selected: isSelected,
                        selectedColor: status.backgroundColor,
                        labelStyle: TextStyle(
                          fontSize: 13,
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
            const SizedBox(height: 10),

            // Inquiries List / Responsive Tablet Grid with zero overlap
            Expanded(
              child: inquiriesAsync.when(
                data: (inquiries) {
                  final trimmedQuery = searchQuery.trim().toLowerCase();

                  final filtered = inquiries.where((item) {
                    final matchesStatus =
                        selectedFilter == null || item.status == selectedFilter;
                    final matchesSearch = trimmedQuery.isEmpty ||
                        item.name.toLowerCase().contains(trimmedQuery) ||
                        item.phone.toLowerCase().contains(trimmedQuery) ||
                        item.areaCity.toLowerCase().contains(trimmedQuery);
                    return matchesStatus && matchesSearch;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            trimmedQuery.isNotEmpty
                                ? 'No leads match "$searchQuery"'
                                : 'No inquiries found for this filter.',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          if (trimmedQuery.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () {
                                _searchCtrl.clear();
                                ref
                                    .read(inquirySearchQueryProvider.notifier)
                                    .state = '';
                              },
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Clear Search Filter'),
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 720;
                      final isVeryWide = constraints.maxWidth >= 1200;

                      if (isWide) {
                        return GridView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isVeryWide ? 3 : 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 8,
                            mainAxisExtent: 240, // Fits 2-line remarks with safe margin
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final inquiry = filtered[index];
                            return InquiryCard(
                              key: ValueKey(inquiry.id),
                              inquiry: inquiry,
                              onStatusChanged: (newStatus) =>
                                  repository.updateStatus(inquiry.id, newStatus),
                              onRemarksSaved: (remarks) =>
                                  repository.updateRemarks(inquiry.id, remarks),
                            );
                          },
                        );
                      }

                      // Mobile view: ListView with naturally adaptive card heights (never overlaps)
                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final inquiry = filtered[index];
                          return InquiryCard(
                            key: ValueKey(inquiry.id),
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
