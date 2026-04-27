import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class ChatScreen extends StatefulWidget {
  final String rideId;
  final String rideDriverId;
  final bool readOnly;

  const ChatScreen({
    super.key,
    required this.rideId,
    required this.rideDriverId,
    this.readOnly = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isSending = false;

  String get _currentUserId => AuthService.userId;
  String get _currentUserName => AuthService.fullName;
  bool get _isDriver => _currentUserId == widget.rideDriverId;

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    _controller.clear();
    setState(() => _isSending = true);

    try {
      await _firestoreService.sendMessage(
        rideId: widget.rideId,
        senderId: _currentUserId,
        senderName: _currentUserName,
        text: text,
        isDriver: _isDriver,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        surfaceTintColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ride Chat', style: GoogleFonts.inter(color: const Color(0xFF1A1D26), fontSize: 18, fontWeight: FontWeight.w800)),
            Text(
              widget.readOnly ? 'Chat history' : 'Group conversation',
              style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A1D26)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFF1F5F9)),
        ),
      ),
      body: Column(
        children: [
          // Safety Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              border: Border(bottom: BorderSide(color: const Color(0xFF2563EB).withValues(alpha: 0.1))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.privacy_tip_rounded, color: Color(0xFF2563EB), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Phone numbers are kept private. Communicate here safely.',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1D4ED8), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.getMessages(widget.rideId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chat_bubble_outline_rounded, size: 40, color: Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 16),
                        Text('No messages yet', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
                        const SizedBox(height: 4),
                        Text('Start the conversation!', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8))),
                      ],
                    ),
                  );
                }

                // Auto-scroll when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['sender_id'] == _currentUserId;
                    final isDriverMsg = msg['is_driver'] == true;
                    final timestamp = msg['timestamp'] as Timestamp?;
                    String timeStr = '';
                    if (timestamp != null) {
                      final dt = timestamp.toDate();
                      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
                      final period = dt.hour >= 12 ? 'PM' : 'AM';
                      timeStr = '$hour:${dt.minute.toString().padLeft(2, '0')} $period';
                    }

                    return _buildChatBubble(
                      text: msg['text'],
                      senderName: isMe ? 'You' : msg['sender_name'],
                      isMe: isMe,
                      isDriver: isDriverMsg,
                      time: timeStr,
                    );
                  },
                );
              },
            ),
          ),

          // Input field or chat ended banner
          if (widget.readOnly)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                border: Border(top: BorderSide(color: const Color(0xFFE2E8F0))),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 8),
                    Text(
                      'This chat has ended with the trip',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
          Container(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -3))],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _controller,
                        textCapitalization: TextCapitalization.sentences,
                        style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF1A1D26)),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 15),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isSending ? Icons.hourglass_top_rounded : Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble({
    required String text,
    required String senderName,
    required bool isMe,
    required bool isDriver,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Sender name + driver badge
          Padding(
            padding: EdgeInsets.only(left: isMe ? 0 : 12, right: isMe ? 12 : 0, bottom: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  senderName,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isMe ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                  ),
                ),
                if (isDriver && !isMe) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'HOST',
                      style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: const Color(0xFF059669), letterSpacing: 0.5),
                    ),
                  ),
                ],
                if (time.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    time,
                    style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFBFC5CF)),
                  ),
                ],
              ],
            ),
          ),

          // Bubble
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe
                  ? const Color(0xFF2563EB)
                  : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 20),
              ),
              border: isMe ? null : Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: isMe
                      ? const Color(0xFF2563EB).withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: isMe ? Colors.white : const Color(0xFF1A1D26),
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
