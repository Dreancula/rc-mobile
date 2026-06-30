import 'dart:math';
import 'package:flutter/material.dart';
import 'package:rc_mobile_v2/core/database/hive_db.dart';
import 'package:rc_mobile_v2/core/theme/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;
  final String title;
  final bool readOnlyEmail;

  const ForgotPasswordScreen({
    super.key,
    this.initialEmail = '',
    this.title = 'Reset Password',
    this.readOnlyEmail = false,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 0; // 0=email, 1=otp, 2=newPass, 3=success
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _sending = false;
  bool _isSaving = false;

  // OTP
  final _otpFields = List.filled(6, '');
  final _otpFocus = List.generate(6, (_) => FocusNode());
  final _otpCtrls = List.generate(6, (_) => TextEditingController());
  int? _generatedOtp;
  int _resendSeconds = 60;

  @override
  void initState() {
    super.initState();
    _emailCtrl.text = widget.initialEmail;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    for (final n in _otpFocus) n.dispose();
    for (final c in _otpCtrls) c.dispose();
    super.dispose();
  }

  void _sendOtp() {
    setState(() {
      _generatedOtp = Random().nextInt(900000) + 100000;
      _resendSeconds = 60;
      _step = 1;
    });
    _startResendTimer();
  }

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_resendSeconds > 0) {
        setState(() => _resendSeconds--);
        return true;
      }
      return false;
    });
  }

  void _resendOtp() {
    setState(() {
      _generatedOtp = Random().nextInt(900000) + 100000;
      _resendSeconds = 60;
      for (int i = 0; i < 6; i++) {
        _otpFields[i] = '';
        _otpCtrls[i].clear();
      }
    });
    _startResendTimer();
  }

  void _verifyOtp() {
    final entered = _otpFields.join();
    if (entered.length < 6 || int.tryParse(entered) != _generatedOtp) return;
    setState(() => _step = 2);
  }

  Future<void> _savePassword() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.length < 6) return;

    setState(() => _isSaving = true);
    try {
      final users = HiveDb.instance.getAllUsers();
      for (final u in users) {
        if ((u['email'] as String? ?? '').toLowerCase() == email.toLowerCase()) {
          u['password'] = pass;
          await HiveDb.instance.saveUser(u);
          break;
        }
      }
    } catch (_) {}

    setState(() => _isSaving = false);
    if (!mounted) return;
    setState(() => _step = 3);
  }

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(fontSize: 14, color: AppColors.softGrey),
    filled: true,
    fillColor: AppColors.lightGrey,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      appBar: AppBar(
        backgroundColor: AppColors.pureWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.pitchBlack),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  gradient: AppColors.blackGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _step == 3 ? Icons.check_rounded : Icons.lock_reset_rounded,
                  color: AppColors.pureWhite, size: 36,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                _step == 0 ? widget.title :
                _step == 1 ? 'Verifikasi Email' :
                _step == 2 ? 'Password Baru' : 'Berhasil',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.pitchBlack, letterSpacing: -0.5),
              ),
              const SizedBox(height: 8),
              Text(
                _step == 0 ? 'Masukkan email Anda untuk reset password.' :
                _step == 1 ? 'Kode OTP telah dikirim ke email Anda.' :
                _step == 2 ? 'Buat password baru untuk akun Anda.' :
                'Password berhasil direset!',
                style: const TextStyle(fontSize: 15, color: AppColors.softGrey),
              ),
              const SizedBox(height: 32),
              if (_step == 0) _buildEmailStep(),
              if (_step == 1) _buildOtpStep(),
              if (_step == 2) _buildPasswordStep(),
              if (_step == 3) _buildSuccessStep(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep() {
    return Column(
      children: [
        TextField(
          controller: _emailCtrl,
          decoration: _dec('Email'),
          keyboardType: TextInputType.emailAddress,
          readOnly: widget.readOnlyEmail,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity, height: 54,
          child: ElevatedButton(
            onPressed: _sending ? null : () {
              final email = _emailCtrl.text.trim();
              if (email.isEmpty) return;
              if (!email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Email tidak valid'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
                );
                return;
              }
              // Check if email exists
              final exists = HiveDb.instance.getAllUsers().any(
                (u) => (u['email'] as String? ?? '').toLowerCase() == email.toLowerCase(),
              );
              if (!exists) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Email tidak terdaftar'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
                );
                return;
              }
              _sendOtp();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pitchBlack,
              foregroundColor: AppColors.pureWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _sending
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.pureWhite)))
                : const Text('Kirim OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: AppColors.lightGrey, borderRadius: BorderRadius.circular(10)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, size: 16, color: AppColors.softGrey),
              const SizedBox(width: 8),
              Text('Simulasi OTP: $_generatedOtp', style: const TextStyle(fontSize: 13, color: AppColors.softGrey)),
            ],
          ),
        ),
        const SizedBox(height: 36),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) => _otpBox(i)),
        ),
        const SizedBox(height: 36),
        SizedBox(
          width: double.infinity, height: 54,
          child: ElevatedButton(
            onPressed: (_otpFields.every((e) => e.isNotEmpty)) ? _verifyOtp : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pitchBlack,
              foregroundColor: AppColors.pureWhite,
              disabledBackgroundColor: AppColors.borderGrey,
              disabledForegroundColor: AppColors.softGrey,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text('Verifikasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: _resendSeconds > 0
              ? Text('Kirim ulang dalam $_resendSeconds detik', style: const TextStyle(fontSize: 13, color: AppColors.softGrey))
              : GestureDetector(
                  onTap: _resendOtp,
                  child: const Text('Kirim ulang OTP', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.pitchBlack)),
                ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      children: [
        TextField(
          controller: _passCtrl,
          decoration: _dec('Password Baru').copyWith(
            suffixIcon: IconButton(
              icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.softGrey, size: 20),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
            ),
          ),
          obscureText: _obscurePass,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmCtrl,
          decoration: _dec('Konfirmasi Password').copyWith(
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.softGrey, size: 20),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          obscureText: _obscureConfirm,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity, height: 54,
          child: ElevatedButton(
            onPressed: _isSaving ? null : () {
              final pass = _passCtrl.text;
              final confirm = _confirmCtrl.text;
              if (pass.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password minimal 6 karakter'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
                );
                return;
              }
              if (pass != confirm) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password tidak cocok'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
                );
                return;
              }
              _savePassword();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pitchBlack,
              foregroundColor: AppColors.pureWhite,
              disabledBackgroundColor: AppColors.borderGrey,
              disabledForegroundColor: AppColors.softGrey,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.pureWhite)))
                : const Text('Simpan Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessStep() {
    return Column(
      children: [
        const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
        const SizedBox(height: 16),
        const Text('Password Anda berhasil diperbarui.', style: TextStyle(fontSize: 15, color: AppColors.softGrey), textAlign: TextAlign.center),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity, height: 54,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pitchBlack,
              foregroundColor: AppColors.pureWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text('Kembali ke Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _otpBox(int index) {
    return SizedBox(
      width: 48, height: 56,
      child: TextField(
        controller: _otpCtrls[index],
        focusNode: _otpFocus[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.pitchBlack),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppColors.lightGrey,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: _otpFields[index].isNotEmpty ? AppColors.pitchBlack : Colors.transparent,
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: _otpFields[index].isNotEmpty ? AppColors.pitchBlack : Colors.transparent,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.pitchBlack, width: 2),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (v) {
          if (v.isEmpty && index > 0) _otpFocus[index - 1].requestFocus();
          _otpFields[index] = v;
          setState(() {});
          if (v.isNotEmpty && index < 5) _otpFocus[index + 1].requestFocus();
        },
      ),
    );
  }
}
