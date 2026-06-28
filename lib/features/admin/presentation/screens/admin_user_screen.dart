import 'package:flutter/material.dart';
import 'package:rc_mobile_v2/core/database/hive_db.dart';
import 'package:rc_mobile_v2/core/theme/app_colors.dart';

class AdminUserScreen extends StatefulWidget {
  final HiveDb db;
  const AdminUserScreen({super.key, required this.db});

  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> {
  late HiveDb _db;
  List<Map<String, dynamic>> _users = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _db = widget.db;
    _loadUsers();
  }

  void _loadUsers() => setState(() => _users = _db.getAllUsers());

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((u) {
      final name = (u['name'] as String? ?? '').toLowerCase();
      final email = (u['email'] as String? ?? '').toLowerCase();
      final q = _searchQuery.toLowerCase();
      return name.contains(q) || email.contains(q);
    }).toList();
  }

  Future<void> _toggleUser(String email) async {
    await _db.toggleUserActive(email);
    _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
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
                      child: const Icon(Icons.people_rounded, color: AppColors.pureWhite, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text('Manajemen Pengguna', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.pitchBlack)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.pitchBlack, borderRadius: BorderRadius.circular(20)),
                      child: Text('${_users.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.pureWhite)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Cari pengguna...',
                    hintStyle: const TextStyle(fontSize: 14, color: AppColors.softGrey),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.softGrey),
                    filled: true,
                    fillColor: AppColors.lightGrey,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _filteredUsers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline_rounded, size: 48, color: AppColors.softGrey),
                        const SizedBox(height: 12),
                        const Text('Tidak ada pengguna', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.pitchBlack)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: AppColors.pitchBlack,
                    onRefresh: () async => _loadUsers(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) => _buildUserCard(_filteredUsers[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final name = user['name'] as String? ?? '';
    final email = user['email'] as String? ?? '';
    final role = user['role'] as String? ?? 'user';
    final isActive = user['isActive'] as bool? ?? true;
    final isAdmin = role == 'admin';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: AppColors.pitchBlack.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Opacity(
        opacity: isActive ? 1.0 : 0.5,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(gradient: isAdmin ? AppColors.blackGradient : AppColors.softBlackGradient, borderRadius: BorderRadius.circular(12)),
                child: Icon(isAdmin ? Icons.shield_rounded : Icons.person_rounded, color: AppColors.pureWhite, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.pitchBlack), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        if (isAdmin) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(gradient: AppColors.blackGradient, borderRadius: BorderRadius.circular(20)),
                            child: const Text('ADMIN', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.pureWhite, letterSpacing: 0.8)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(email, style: const TextStyle(fontSize: 12, color: AppColors.softGrey), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (!isAdmin)
                Switch(
                  value: isActive,
                  onChanged: (_) => _toggleUser(email),
                  activeTrackColor: AppColors.pitchBlack,
                  inactiveThumbColor: AppColors.softGrey,
                )
              else
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.lightGrey, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.lock_outlined, color: AppColors.softGrey, size: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
