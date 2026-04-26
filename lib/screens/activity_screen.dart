import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/empty_state_widget.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'ride_created':
        return Icons.add_circle_outline;
      case 'ride_joined':
        return Icons.person_add_outlined;
      case 'seat_update':
        return Icons.event_seat_outlined;
      case 'ride_cancelled':
        return Icons.cancel_outlined;
      case 'sos':
        return Icons.sos_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'ride_created':
        return const Color(0xFF2563EB);
      case 'ride_joined':
        return const Color(0xFF10B981);
      case 'seat_update':
        return const Color(0xFFF59E0B);
      case 'ride_cancelled':
        return const Color(0xFFEF4444);
      case 'sos':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    DateTime time;
    if (timestamp is Timestamp) {
      time = timestamp.toDate();
    } else {
      return 'Just now';
    }

    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day}/${time.month}';
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService.isLoggedIn) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF1A1D26)),
          title: Text('Activity',
              style: GoogleFonts.inter(
                  color: const Color(0xFF1A1D26),
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          centerTitle: true,
        ),
        body: const EmptyStateWidget(
          icon: Icons.notifications_off_outlined,
          title: 'Sign in to view activity',
          subtitle: 'Your ride notifications and updates will appear here',
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1D26)),
        title: Text('Activity',
            style: GoogleFonts.inter(
                color: const Color(0xFF1A1D26),
                fontSize: 20,
                fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.getActivities(AuthService.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF2563EB)));
          }

          final activities = snapshot.data ?? [];

          if (activities.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.notifications_none_rounded,
              title: 'No activity yet',
              subtitle:
                  'When you create or join rides, your updates will show here',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: activities.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final activity = activities[index];
              final type = activity['type'] ?? '';
              final isRead = activity['read'] ?? false;
              final color = _getTypeColor(type);

              return GestureDetector(
                onTap: () {
                  if (!isRead) {
                    _firestoreService.markActivityRead(
                        AuthService.userId, activity['id']);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isRead
                        ? Colors.white
                        : color.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isRead
                          ? const Color(0xFFF1F5F9)
                          : color.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_getTypeIcon(type),
                            color: color, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    activity['title'] ?? 'Update',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: isRead
                                          ? FontWeight.w600
                                          : FontWeight.w800,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatTime(activity['created_at']),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              activity['body'] ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF64748B),
                                height: 1.4,
                              ),
                            ),
                            if (!isRead) ...[
                              const SizedBox(height: 4),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
