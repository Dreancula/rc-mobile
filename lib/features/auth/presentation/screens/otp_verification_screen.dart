import 'dart:math';
import 'package:flutter/material.dart';
import 'package:rc_mobile_v2/core/database/hive_db.dart';
import 'package:rc_mobile_v2/core/theme/app_colors.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String phone;
  final VoidCallback onVerified;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.phone,
    required this.onVerified,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpCode = List.filled(6, '');
  final _focusNodes = List.generate(6, (_) => FocusNode());
  final _controllers = List.generate(6, (_) => TextEditingController());
  int? _generatedOtp;
  int _resendSeconds = 60;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _generatedOtp = Random().nextInt(900000) + 100000; // 6-digit random
    _startResendTimer();
  }

  @override
  void dispose() {
    for (final n in _focusNodes) n.dispose();
    for (final c in _controllers) c.dispose();
    super.dispose();
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

  void _onDigitChanged(int index, String value) {
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    _otpCode[index] = value;
    setState(() {});

    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  Future<void> _verify() async {
    final entered = _otpCode.join();
    if (entered.length < 6) return;
    if (int.tryParse(entered) != _generatedOtp) return;

    setState(() => _isVerifying = true);
    await HiveDb.instance.markPhoneVerified(widget.email);
    if (mounted) widget.onVerified();
  }

  void _resendOtp() {
    setState(() {
      _generatedOtp = Random().nextInt(900000) + 100000;
      _resendSeconds = 60;
    });
    _startResendTimer();
  }

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
              // Icon
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  gradient: AppColors.blackGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.smartphone_rounded, color: AppColors.pureWhite, size: 36),
              ),
              const SizedBox(height: 28),
              // Title
              const Text('Verifikasi Nomor HP',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.pitchBlack, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              // Subtitle
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 15, color: AppColors.softGrey, height: 1.5),
                  children: [
                    const TextSpan(text: 'Kode OTP telah dikirim ke\n'),
                    TextSpan(
                      text: widget.phone,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.pitchBlack),
                    ),
                  ],
                ),
              ),

              // Simulated OTP display (for demo)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: AppColors.softGrey),
                    const SizedBox(width: 8),
                    Text('Simulasi OTP: $_generatedOtp',
                      style: const TextStyle(fontSize: 13, color: AppColors.softGrey)),
                  ],
                ),
              ),

              const SizedBox(height: 36),
              // OTP input
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) => _otpBox(i)),
              ),
              const SizedBox(height: 36),
              // Verify button
              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  onPressed: (_otpCode.every((e) => e.isNotEmpty) && !_isVerifying) ? _verify : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pitchBlack,
                    foregroundColor: AppColors.pureWhite,
                    disabledBackgroundColor: AppColors.borderGrey,
                    disabledForegroundColor: AppColors.softGrey,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isVerifying
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.pureWhite)))
                      : const Text('Verifikasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 20),
              // Resend
              Center(
                child: _resendSeconds > 0
                    ? Text('Kirim ulang dalam $_resendSeconds detik',
                        style: const TextStyle(fontSize: 13, color: AppColors.softGrey))
                    : GestureDetector(
                        onTap: _resendOtp,
                        child: const Text('Kirim ulang OTP',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.pitchBlack)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _otpBox(int index) {
    return SizedBox(
      width: 48, height: 56,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
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
              color: _otpCode[index].isNotEmpty ? AppColors.pitchBlack : Colors.transparent,
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: _otpCode[index].isNotEmpty ? AppColors.pitchBlack : Colors.transparent,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.pitchBlack, width: 2),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (v) => _onDigitChanged(index, v),
      ),
    );
  }
}
