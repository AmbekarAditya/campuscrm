import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/services/activity_logger.dart';

class ActivityFeedView extends ConsumerWidget {
  const ActivityFeedView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestore = ref.watch(firestoreProvider);
    final localLogs = ref.watch(localActivityLogsProvider);

    if (firestore == null) {
      return Card(
        child: ListView.separated(
          itemCount: localLogs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = localLogs[index];
            return ListTile(
              leading: const Icon(Icons.history_rounded, color: Color(0xFF1E40AF)),
              title: Text(
                '${item.actorName} — ${item.action}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(item.category),
            );
          },
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: firestore
          .collection('activity_logs')
          .orderBy('timestamp', descending: true)
          .limit(25)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Card(
            child: Center(
              child: Text('No activity logs recorded yet.'),
            ),
          );
        }

        return Card(
          child: ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final actor = data['actorName'] as String? ?? 'Staff';
              final action = data['action'] as String? ?? '';
              return ListTile(
                leading: const Icon(Icons.history_rounded),
                title: Text('$actor — $action'),
              );
            },
          ),
        );
      },
    );
  }
}
