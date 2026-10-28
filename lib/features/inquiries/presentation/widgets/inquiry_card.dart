import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/inquiry_model.dart';

class InquiryCard extends StatefulWidget {
  final Inquiry inquiry;
  final ValueChanged<InquiryStatus> onStatusChanged;
  final ValueChanged<String> onRemarksSaved;
  final ValueChanged<DateTime>? onFollowUpDateChanged;

  const InquiryCard({
    super.key,
    required this.inquiry,
    required this.onStatusChanged,
    required this.onRemarksSaved,
    this.onFollowUpDateChanged,
  });

  @override
  State<InquiryCard> createState() => _InquiryCardState();
}

class _InquiryCardState extends State<InquiryCard> {
  late final TextEditingController _remarksController;
  bool _isRemarksDirty = false;

  @override
  void initState() {
    super.initState();
    _remarksController = TextEditingController(text: widget.inquiry.remarks);
  }

  @override
  void didUpdateWidget(covariant InquiryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.inquiry.remarks != widget.inquiry.remarks && !_isRemarksDirty) {
      _remarksController.text = widget.inquiry.remarks;
    }
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  Future<void> _pickFollowUpDate(BuildContext context) async {
    final initial = widget.inquiry.followUpDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2032),
    );
    if (picked != null && widget.onFollowUpDateChanged != null) {
      widget.onFollowUpDateChanged!(picked);
    }
  }

  Future<void> _handleStatusChange(InquiryStatus newStatus) async {
    if (newStatus == InquiryStatus.followUp && widget.inquiry.followUpDate == null) {
      // Prompt for follow-up date when switching to Follow-Up status
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now().subtract(const Duration(days: 30)),
        lastDate: DateTime(2032),
      );
      if (picked != null && widget.onFollowUpDateChanged != null) {
        widget.onFollowUpDateChanged!(picked);
      }
    }
    widget.onStatusChanged(newStatus);
  }

  Future<void> _launchActionUrl(BuildContext context, Uri uri) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open ${uri.scheme} link.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $e')),
        );
      }
    }
  }

  /// Strips spaces and special characters so `https://wa.me/<number>` works reliably.
  String _sanitizeWhatsAppNumber(String rawPhone) {
    return rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
  }

  @override
  Widget build(BuildContext context) {
    final inquiry = widget.inquiry;
    final status = inquiry.status;
    final isFollowUp = status == InquiryStatus.followUp;
    final followUpDate = inquiry.followUpDate ?? DateTime.now();
    final isDueToday = isFollowUp && _isToday(followUpDate);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isBounded = constraints.hasBoundedHeight;
            return Column(
              mainAxisSize: isBounded ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: isBounded
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar + Name + Phone/Location + Status Dropdown
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Student Initials Avatar
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: status.backgroundColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: status.foregroundColor.withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _getInitials(inquiry.name),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: status.foregroundColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Name, Phone & Location
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inquiry.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Wrap(
                            spacing: 8,
                            runSpacing: 2,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (inquiry.phone.isNotEmpty)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.phone_outlined,
                                      size: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      inquiry.phone,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ],
                                ),
                              if (inquiry.areaCity.isNotEmpty)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      inquiry.areaCity,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF64748B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Compact Color-Coded Status Dropdown
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: status.backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: status.foregroundColor.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<InquiryStatus>(
                          value: status,
                          isDense: true,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: status.foregroundColor,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: status.foregroundColor,
                          ),
                          onChanged: (InquiryStatus? newStatus) {
                            if (newStatus != null && newStatus != status) {
                              _handleStatusChange(newStatus);
                            }
                          },
                          items: InquiryStatus.values.map((itemStatus) {
                            return DropdownMenuItem<InquiryStatus>(
                              value: itemStatus,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: itemStatus.foregroundColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    itemStatus.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: itemStatus.foregroundColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),

                // Follow-Up Date Tag on Card (if status is Follow-Up)
                if (isFollowUp) ...[
                  if (!isBounded) const SizedBox(height: 6),
                  InkWell(
                    onTap: () => _pickFollowUpDate(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDueToday
                            ? const Color(0xFFFEF3C7)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDueToday
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFCBD5E1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.event_repeat_rounded,
                            size: 13,
                            color: isDueToday
                                ? const Color(0xFFB45309)
                                : const Color(0xFF475569),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isDueToday
                                ? 'Follow-Up: Today (${_formatDate(followUpDate)})'
                                : 'Follow-Up Date: ${_formatDate(followUpDate)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDueToday
                                  ? const Color(0xFF92400E)
                                  : const Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.edit_calendar_rounded,
                            size: 12,
                            color: isDueToday
                                ? const Color(0xFFB45309)
                                : const Color(0xFF64748B),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                if (!isBounded) const SizedBox(height: 6),

                // Compact Remarks TextField with inline Save button
                TextField(
                  controller: _remarksController,
                  maxLines: 1,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E293B)),
                  onChanged: (value) {
                    setState(() {
                      _isRemarksDirty = value != inquiry.remarks;
                    });
                  },
                  onSubmitted: (value) {
                    widget.onRemarksSaved(value.trim());
                    setState(() => _isRemarksDirty = false);
                  },
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: inquiry.remarks.isEmpty
                        ? 'Add follow-up notes...'
                        : inquiry.remarks,
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: inquiry.remarks.isEmpty
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF334155),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    suffixIcon: _isRemarksDirty
                        ? IconButton(
                            iconSize: 18,
                            padding: EdgeInsets.zero,
                            constraints:
                                const BoxConstraints(minWidth: 28, minHeight: 28),
                            tooltip: 'Save Remarks',
                            onPressed: () {
                              widget.onRemarksSaved(_remarksController.text.trim());
                              setState(() => _isRemarksDirty = false);
                              FocusScope.of(context).unfocus();
                            },
                            icon: const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF16A34A),
                            ),
                          )
                        : null,
                  ),
                ),

                if (!isBounded) const SizedBox(height: 6),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                if (!isBounded) const SizedBox(height: 6),

                // Row of 4 1-Click Action Icon Buttons
                Row(
                  children: [
                    Expanded(
                      child: _ActionIconButton(
                        icon: Icons.phone_in_talk_rounded,
                        label: 'Call',
                        color: const Color(0xFF2563EB),
                        backgroundColor: const Color(0xFFEFF6FF),
                        onPressed: () => _launchActionUrl(
                          context,
                          Uri.parse('tel:${inquiry.phone}'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _ActionIconButton(
                        icon: Icons.chat_bubble_rounded,
                        label: 'WhatsApp',
                        color: const Color(0xFF16A34A),
                        backgroundColor: const Color(0xFFF0FDF4),
                        onPressed: () {
                          final cleanPhone = _sanitizeWhatsAppNumber(inquiry.phone);
                          _launchActionUrl(
                            context,
                            Uri.parse('https://wa.me/$cleanPhone'),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _ActionIconButton(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        color: const Color(0xFF9333EA),
                        backgroundColor: const Color(0xFFFAF5FF),
                        onPressed: () => _launchActionUrl(
                          context,
                          Uri.parse('mailto:${inquiry.email}'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _ActionIconButton(
                        icon: Icons.location_pin,
                        label: 'Map',
                        color: const Color(0xFFEA580C),
                        backgroundColor: const Color(0xFFFFF7ED),
                        onPressed: () {
                          final encodedLocation =
                              Uri.encodeComponent(inquiry.areaCity);
                          _launchActionUrl(
                            context,
                            Uri.parse('https://maps.google.com/?q=$encodedLocation'),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onPressed;

  const _ActionIconButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
