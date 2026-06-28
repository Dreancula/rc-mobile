import 'package:flutter/material.dart';
import 'package:rc_mobile_v2/core/database/hive_db.dart';
import 'package:rc_mobile_v2/core/theme/app_colors.dart';
import 'package:rc_mobile_v2/features/home/domain/models/chat_message_model.dart';

class AdminChatScreen extends StatefulWidget {
  final HiveDb db;
  const AdminChatScreen({super.key, required this.db});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  String? _selectedEmail;

  @override
  Widget build(BuildContext context) {
    final users = widget.db.getAllConversationUsers();
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(
        children: [
          Container(
            color: AppColors.pureWhite,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(gradient: AppColors.softBlackGradient, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.chat_rounded, color: AppColors.pureWhite, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  _selectedEmail == null ? 'Pesan Pembeli' : 'Chat',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.pitchBlack),
                ),
                const Spacer(),
                if (_selectedEmail != null)
                  GestureDetector(
                    onTap: () => setState(() => _selectedEmail = null),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.lightGrey, borderRadius: BorderRadius.circular(20)),
                      child: const Text('Kembali', style: TextStyle(fontSize: 12, color: AppColors.pitchBlack)),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _selectedEmail == null
                ? _buildConversationList(users)
                : _ChatDetail(email: _selectedEmail!, db: widget.db, onBack: () => setState(() => _selectedEmail = null)),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationList(List<String> users) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.softGrey),
            const SizedBox(height: 12),
            const Text('Belum ada percakapan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.pitchBlack)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final email = users[index];
        final msgs = widget.db.getMessages(email);
        final unread = widget.db.getUnreadCount(email);
        final last = msgs.isNotEmpty ? msgs.last : null;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.pureWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.5)),
          ),
          child: InkWell(
            onTap: () => setState(() => _selectedEmail = email),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(gradient: AppColors.softBlackGradient, borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Text(email[0].toUpperCase(), style: const TextStyle(color: AppColors.pureWhite, fontWeight: FontWeight.w700, fontSize: 18))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(email, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.pitchBlack), overflow: TextOverflow.ellipsis)),
                            if (unread > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.pitchBlack, borderRadius: BorderRadius.circular(10)),
                                child: Text('$unread', style: const TextStyle(fontSize: 11, color: AppColors.pureWhite, fontWeight: FontWeight.w600)),
                              ),
                          ],
                        ),
                        if (last != null) ...[
                          const SizedBox(height: 4),
                          Text(last.message, style: const TextStyle(fontSize: 13, color: AppColors.softGrey), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ChatDetail extends StatefulWidget {
  final String email;
  final HiveDb db;
  final VoidCallback onBack;
  const _ChatDetail({required this.email, required this.db, required this.onBack});

  @override
  State<_ChatDetail> createState() => _ChatDetailState();
}

class _ChatDetailState extends State<_ChatDetail> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.db.markMessagesRead(widget.email);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  List<ChatMessageModel> get _messages => widget.db.getMessages(widget.email);

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    widget.db.sendMessage(ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderEmail: 'admin@admin.com',
      senderName: 'Admin',
      senderRole: 'admin',
      message: text,
      timestamp: DateTime.now(),
    ));
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? const Center(child: Text('Belum ada pesan', style: TextStyle(color: AppColors.softGrey)))
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isAdmin = msg.senderRole == 'admin';
                    return Align(
                      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isAdmin ? AppColors.pitchBlack : AppColors.lightGrey,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isAdmin ? const Radius.circular(16) : Radius.zero,
                            bottomRight: isAdmin ? Radius.zero : const Radius.circular(16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isAdmin)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(msg.senderName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.darkGrey)),
                              ),
                            Text(msg.message, style: TextStyle(fontSize: 14, color: isAdmin ? AppColors.pureWhite : AppColors.pitchBlack)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
          decoration: BoxDecoration(
            color: AppColors.pureWhite,
            boxShadow: [BoxShadow(color: AppColors.shadowColor, blurRadius: 8, offset: const Offset(0, -2))],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: 'Balas pesan...',
                    hintStyle: const TextStyle(fontSize: 14, color: AppColors.softGrey),
                    filled: true,
                    fillColor: AppColors.lightGrey,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _send,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(gradient: AppColors.blackGradient, borderRadius: BorderRadius.circular(22)),
                  child: const Icon(Icons.send_rounded, color: AppColors.pureWhite, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
