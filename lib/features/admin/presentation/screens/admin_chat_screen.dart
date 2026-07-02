import 'package:flutter/material.dart';
import 'package:rc_mobile_v2/core/database/hive_db.dart';
import 'package:rc_mobile_v2/core/theme/app_colors.dart';
import 'package:rc_mobile_v2/features/home/domain/models/chat_message_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AdminChatScreen extends StatefulWidget {
  final HiveDb db;
  const AdminChatScreen({super.key, required this.db});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  String? _selectedEmail;
  String _filterType = 'all'; // 'all', 'private', 'order'

  @override
  Widget build(BuildContext context) {
    final allConversations = widget.db.getAllConversations();

    // Filter conversations based on type
    final filtered = allConversations.where((c) {
      if (_filterType == 'all') return true;
      if (_filterType == 'private') return c.type == ConversationType.private;
      if (_filterType == 'order') return c.type == ConversationType.order;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(
        children: [
          Container(
            color: AppColors.pureWhite,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(gradient: AppColors.softBlackGradient, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.chat_rounded, color: AppColors.pureWhite, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedEmail == null ? 'Pesan Pembeli' : 'Chat',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.pitchBlack),
                      ),
                    ),
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
                // Filter tabs
                if (_selectedEmail == null) ...[
                  const SizedBox(height: 12),
                  Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        _filterTab('Semua', 'all'),
                        _filterTab('Pribadi', 'private'),
                        _filterTab('Pesanan', 'order'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _selectedEmail == null
                ? _buildConversationList(filtered)
                : _ChatDetail(email: _selectedEmail!, db: widget.db, onBack: () => setState(() => _selectedEmail = null)),
          ),
        ],
      ),
    );
  }

  Widget _filterTab(String label, String value) {
    final isSelected = _filterType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filterType = value),
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.blackGradient : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.pureWhite : AppColors.softGrey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConversationList(List<ConversationInfo> conversations) {
    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.softGrey),
            const SizedBox(height: 12),
            const Text('Belum ada percakapan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.pitchBlack)),
            const SizedBox(height: 4),
            Text(
              _filterType == 'private'
                  ? 'Chat pribadi user akan muncul di sini'
                  : _filterType == 'order'
                      ? 'Chat tentang pesanan akan muncul di sini'
                      : 'Mulai percakapan dengan user',
              style: TextStyle(fontSize: 12, color: AppColors.softGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conv = conversations[index];
        final msgs = widget.db.getMessages(conv.email);
        final unread = widget.db.getUnreadCount(conv.email);
        final last = msgs.isNotEmpty ? msgs.last : null;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.pureWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.5)),
          ),
          child: InkWell(
            onTap: () => setState(() => _selectedEmail = conv.email),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          gradient: conv.type == ConversationType.order
                              ? const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF0D47A1)])
                              : AppColors.softBlackGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: conv.type == ConversationType.order
                              ? const Icon(Icons.receipt_long, color: AppColors.pureWhite, size: 20)
                              : Text(conv.email[0].toUpperCase(), style: const TextStyle(color: AppColors.pureWhite, fontWeight: FontWeight.w700, fontSize: 18)),
                        ),
                      ),
                      if (conv.type == ConversationType.order)
                        Positioned(
                          right: 0, bottom: 0,
                          child: Container(
                            width: 12, height: 12,
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.pureWhite, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(conv.email, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.pitchBlack), overflow: TextOverflow.ellipsis)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: conv.type == ConversationType.order
                                    ? const Color(0xFF1565C0).withValues(alpha: 0.1)
                                    : AppColors.lightGrey,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                conv.type == ConversationType.order ? 'Pesanan' : 'Pribadi',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: conv.type == ConversationType.order
                                      ? const Color(0xFF1565C0)
                                      : AppColors.softGrey,
                                ),
                              ),
                            ),
                            if (unread > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.pitchBlack, borderRadius: BorderRadius.circular(10)),
                                child: Text('$unread', style: const TextStyle(fontSize: 11, color: AppColors.pureWhite, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ],
                        ),
                        if (last != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (last.isImageMessage)
                                Row(
                                  children: [
                                    Icon(Icons.image, size: 14, color: AppColors.softGrey),
                                    const SizedBox(width: 4),
                                  ],
                                ),
                              Expanded(
                                child: Text(
                                  last.isImageMessage ? 'Mengirim foto' : last.message,
                                  style: const TextStyle(fontSize: 13, color: AppColors.softGrey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
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
  final _imagePicker = ImagePicker();

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
      receiverEmail: widget.email,
    ));
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.pitchBlack),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.pitchBlack),
              title: const Text('Galeri Foto'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        _sendImage(pickedFile.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memilih foto')),
        );
      }
    }
  }

  void _sendImage(String imagePath) {
    widget.db.sendMessage(ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderEmail: 'admin@admin.com',
      senderName: 'Admin',
      senderRole: 'admin',
      message: 'Mengirim foto',
      timestamp: DateTime.now(),
      receiverEmail: widget.email,
      imageUrl: imagePath,
    ));
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
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

                    // Image message
                    if (msg.isImageMessage) {
                      return Align(
                        alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.65,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.pitchBlack.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.file(
                                  File(msg.imageUrl!),
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    height: 150,
                                    color: AppColors.lightGrey,
                                    child: const Center(
                                      child: Icon(Icons.broken_image, color: AppColors.softGrey),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  color: isAdmin ? AppColors.pitchBlack : AppColors.pureWhite,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!isAdmin) ...[
                                        Text(msg.senderName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.softGrey)),
                                        const SizedBox(width: 8),
                                      ],
                                      Text(
                                        '${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(fontSize: 10, color: isAdmin ? AppColors.pureWhite.withValues(alpha: 0.6) : AppColors.softGrey),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    // Text message
                    return Align(
                      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isAdmin ? AppColors.pitchBlack : AppColors.pureWhite,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isAdmin ? const Radius.circular(16) : Radius.zero,
                            bottomRight: isAdmin ? Radius.zero : const Radius.circular(16),
                          ),
                          border: isAdmin ? null : Border.all(color: AppColors.borderGrey),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isAdmin)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(msg.senderName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.softGrey)),
                              ),
                            Text(msg.message, style: TextStyle(fontSize: 14, color: isAdmin ? AppColors.pureWhite : AppColors.pitchBlack)),
                            const SizedBox(height: 4),
                            Text(
                              '${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(fontSize: 10, color: isAdmin ? AppColors.pureWhite.withValues(alpha: 0.6) : AppColors.softGrey),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        // Input
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
          decoration: BoxDecoration(
            color: AppColors.pureWhite,
            boxShadow: [BoxShadow(color: AppColors.shadowColor, blurRadius: 8, offset: const Offset(0, -2))],
          ),
          child: Row(
            children: [
              // Camera Button
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.softBlackGradient,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(Icons.camera_alt, color: AppColors.pureWhite, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: 'Ketik pesan...',
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
