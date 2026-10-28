import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/inquiry_model.dart';

class InquiryCard extends StatefulWidget {
  final Inquiry inquiry;
  final ValueChanged<InquiryStatus> onStatusChanged;
  final ValueChanged<String> onRemarksSaved;

  const InquiryCard({
    super.key,
    required this.inquiry,
    required this.onStatusChanged,
    required this.onRemarksSaved,
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Lead Name, Area/City, and Color-Coded Status Dropdown
            Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inquiry.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          inquiry.areaCity.isEmpty
                              ? 'Location not specified'
                              : inquiry.areaCity,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),

                // Color-Coded Status Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: status.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: status.foregroundColor.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<InquiryStatus>(
                      value: status,
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: status.foregroundColor,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: status.foregroundColor,
                      ),
                      onChanged: (InquiryStatus? newStatus) {
                        if (newStatus != null && newStatus != status) {
                          widget.onStatusChanged(newStatus);
                        }
                      },
                      items: InquiryStatus.values.map((itemStatus) {
                        return DropdownMenuItem<InquiryStatus>(
                          value: itemStatus,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: itemStatus.foregroundColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                itemStatus.label,
                                style: TextStyle(
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

            const SizedBox(height: 16),

            // Remarks TextField with quick-save action
            TextField(
              controller: _remarksController,
              maxLines: 2,
              minLines: 1,
              textInputAction: TextInputAction.done,
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
                labelText: 'Remarks / Follow-up Notes',
                hintText: 'E.g. Wants weekend batch, asked for demo class...',
                suffixIcon: _isRemarksDirty
                    ? Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: TextButton.icon(
                          onPressed: () {
                            widget.onRemarksSaved(_remarksController.text.trim());
                            setState(() => _isRemarksDirty = false);
                            FocusScope.of(context).unfocus();
                          },
                          icon: const Icon(Icons.check_circle_outline, size: 20),
                          label: const Text('Save'),
                        ),
                      )
                    : null,
              ),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 12),

            // Row of 4 1-Click Action Icon Buttons (Call, WhatsApp, Email, Map Pin)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ActionIconButton(
                  icon: Icons.phone_in_talk_rounded,
                  label: 'Call',
                  color: const Color(0xFF2563EB),
                  backgroundColor: const Color(0xFFEFF6FF),
                  onPressed: () => _launchActionUrl(
                    context,
                    Uri.parse('tel:${inquiry.phone}'),
                  ),
                ),
                _ActionIconButton(
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
                _ActionIconButton(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  color: const Color(0xFF9333EA),
                  backgroundColor: const Color(0xFFFAF5FF),
                  onPressed: () => _launchActionUrl(
                    context,
                    Uri.parse('mailto:${inquiry.email}'),
                  ),
                ),
                _ActionIconButton(
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
              ],
            ),
          ],
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
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minWidth: 76, minHeight: 54),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
