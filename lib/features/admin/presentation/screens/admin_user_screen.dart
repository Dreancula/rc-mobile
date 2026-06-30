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

  void _showUserForm({Map<String, dynamic>? user}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserFormSheet(
        user: user,
        db: _db,
        onSaved: _loadUsers,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserForm(),
        backgroundColor: AppColors.pitchBlack,
        foregroundColor: AppColors.pureWhite,
        elevation: 4,
        child: const Icon(Icons.add),
      ),
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

    return GestureDetector(
      onTap: () => _showUserForm(user: user),
      child: Container(
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom Sheet Form
// ---------------------------------------------------------------------------

class _UserFormSheet extends StatefulWidget {
  final Map<String, dynamic>? user;
  final HiveDb db;
  final VoidCallback onSaved;

  const _UserFormSheet({this.user, required this.db, required this.onSaved});

  @override
  State<_UserFormSheet> createState() => _UserFormSheetState();
}

class _UserFormSheetState extends State<_UserFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passCtrl;
  String _role = 'user';
  bool _isActive = true;
  bool _isSaving = false;
  bool _isDeleting = false;

  bool get _isEdit => widget.user != null;
  bool get _isSelf => _emailCtrl.text == _sessionEmail;

  String? _sessionEmail;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _nameCtrl = TextEditingController(text: u?['name'] as String? ?? '');
    _emailCtrl = TextEditingController(text: u?['email'] as String? ?? '');
    _passCtrl = TextEditingController();
    _role = u?['role'] as String? ?? 'user';
    _isActive = u?['isActive'] as bool? ?? true;

    final session = widget.db.getUserSession();
    _sessionEmail = session?['email'] as String?;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final data = <String, dynamic>{
      'id': widget.user?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'role': _role,
      'isActive': _isActive,
      'isPhoneVerified': widget.user?['isPhoneVerified'] ?? false,
      'province': widget.user?['province'] ?? '',
      'city': widget.user?['city'] ?? '',
      'address': widget.user?['address'] ?? '',
      'phone': widget.user?['phone'] ?? '',
      'voucher': widget.user?['voucher'] ?? 20000,
      'walletBalance': widget.user?['walletBalance'] ?? 0.0,
      'photo': widget.user?['photo'] ?? '',
    };

    if (_isEdit) {
      // preserve existing password if not changing
      data['password'] = _passCtrl.text.isNotEmpty
          ? _passCtrl.text
          : (widget.user?['password'] ?? 'password123');
    } else {
      data['password'] = _passCtrl.text.isNotEmpty ? _passCtrl.text : 'password123';
    }

    await widget.db.saveUser(data);
    setState(() => _isSaving = false);

    if (mounted) Navigator.pop(context);
    widget.onSaved();
  }

  Future<void> _delete() async {
    final email = _emailCtrl.text.trim();
    final name = _nameCtrl.text.trim();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Pengguna', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Yakin ingin menghapus "$name" ($email)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.softGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    await widget.db.deleteUser(email);
    if (mounted) Navigator.pop(context);
    widget.onSaved();
  }

  InputDecoration _inputDec(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 14, color: AppColors.softGrey),
      filled: true,
      fillColor: AppColors.lightGrey,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottom),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Drag handle
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.borderGrey, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              // Header
              Row(
                children: [
                  const Spacer(),
                  Text(
                    _isEdit ? 'Edit Pengguna' : 'Tambah Pengguna',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.pitchBlack),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: AppColors.lightGrey, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.close, size: 18, color: AppColors.softGrey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Form fields
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: _inputDec('Nama'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama harus diisi' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: _inputDec('Email'),
                        keyboardType: TextInputType.emailAddress,
                        readOnly: _isEdit,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email harus diisi';
                          if (!v.contains('@')) return 'Email tidak valid';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passCtrl,
                        decoration: _inputDec(_isEdit ? 'Password (kosongkan jika tidak diubah)' : 'Password'),
                        obscureText: true,
                        validator: (_isEdit) ? null : (v) => (v == null || v.trim().isEmpty) ? 'Password harus diisi' : null,
                      ),
                      const SizedBox(height: 14),
                      // Role
                      DropdownButtonFormField<String>(
                        value: _role,
                        decoration: _inputDec('Role'),
                        items: const [
                          DropdownMenuItem(value: 'user', child: Text('User')),
                          DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        ],
                        onChanged: _isEdit && _isSelf
                            ? null
                            : (v) {
                                if (v != null) setState(() => _role = v);
                              },
                        dropdownColor: AppColors.pureWhite,
                      ),
                      const SizedBox(height: 14),
                      // Active switch
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(color: AppColors.lightGrey, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Aktif', style: TextStyle(fontSize: 14, color: AppColors.pitchBlack)),
                            Switch(
                              value: _isActive,
                              onChanged: (_isEdit && _isSelf) ? null : (v) => setState(() => _isActive = v),
                              activeTrackColor: AppColors.pitchBlack,
                              inactiveThumbColor: AppColors.softGrey,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Save button
                      SizedBox(
                        width: double.infinity, height: 50,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.pitchBlack,
                            foregroundColor: AppColors.pureWhite,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.pureWhite)))
                              : Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Pengguna', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      if (_isEdit) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity, height: 50,
                          child: OutlinedButton(
                            onPressed: _isDeleting ? null : _delete,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _isDeleting
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.error)))
                                : const Text('Hapus Pengguna', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
