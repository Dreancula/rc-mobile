import 'package:flutter/material.dart';
import '../../../../core/database/hive_db.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/chat_message_model.dart';

class ChatScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const ChatScreen({super.key, this.onBack});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _db = HiveDb.instance;
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late String _email;
  late String _name;

  @override
  void initState() {
    super.initState();
    final session = _db.getUserSession();
    _email = session?['email'] as String? ?? '';
    _name = session?['name'] as String? ?? 'User';
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _markRead() {
    _db.markMessagesRead(_email);
    setState(() {});
  }

  List<ChatMessageModel> get _messages => _db.getMessages(_email);

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    _db.sendMessage(ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderEmail: _email,
      senderName: _name,
      senderRole: 'user',
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
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      appBar: AppBar(
        backgroundColor: AppColors.pureWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.pitchBlack, size: 20),
          onPressed: () {
            _markRead();
            if (widget.onBack != null) widget.onBack!();
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.blackGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(child: Icon(Icons.headset_mic_rounded, color: AppColors.pureWhite, size: 20)),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer Service', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.pitchBlack)),
                Text('Republik Casual', style: TextStyle(fontSize: 11, color: AppColors.softGrey)),
              ],
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg.senderRole == 'user';
                      return _buildBubble(msg, isMe);
                    },
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: AppColors.lightGrey, shape: BoxShape.circle),
            child: const Icon(Icons.chat_outlined, size: 36, color: AppColors.softGrey),
          ),
          const SizedBox(height: 16),
          const Text('Belum ada pesan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.pitchBlack)),
          const SizedBox(height: 8),
          const Text('Kirim pesan untuk bertanya\natau menghubungi admin', style: TextStyle(fontSize: 13, color: AppColors.softGrey), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildBubble(ChatMessageModel msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? AppColors.pitchBlack : AppColors.lightGrey,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(msg.senderName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.darkGrey)),
              ),
            Text(msg.message, style: TextStyle(fontSize: 14, color: isMe ? AppColors.pureWhite : AppColors.pitchBlack)),
            const SizedBox(height: 4),
            Text(_formatTime(msg.timestamp), style: TextStyle(fontSize: 10, color: isMe ? AppColors.pureWhite.withValues(alpha: 0.6) : AppColors.softGrey)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
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
                hintText: 'Tulis pesan...',
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
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
