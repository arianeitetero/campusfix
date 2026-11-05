import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/feedback.dart';
import '../../widgets/loading_button.dart';
import 'auth_scaffold.dart';

/// Blocks access until the ALU email address is verified. Polls Firebase
/// every few seconds so the app continues as soon as the link is clicked.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  static const _resendCooldown = 30;

  Timer? _poll;
  Timer? _cooldownTimer;
  int _cooldown = _resendCooldown;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _check());
    _startCooldown();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldown = _resendCooldown);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_cooldown <= 1) t.cancel();
      setState(() => _cooldown--);
    });
  }

  Future<bool> _check() async {
    try {
      return await context.read<AuthProvider>().checkEmailVerified();
    } catch (_) {
      return false;
    }
  }

  Future<void> _manualCheck() async {
    setState(() => _checking = true);
    final verified = await _check();
    if (!mounted) return;
    setState(() => _checking = false);
    if (!verified) {
      showMessage(context, 'Not verified yet. Open the link in your inbox.');
    }
  }

  Future<void> _resend() async {
    final error = await context.read<AuthProvider>().resendVerification();
    if (!mounted) return;
    showMessage(context, error ?? 'Verification email sent again.',
        isError: error != null);
    if (error == null) _startCooldown();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final email = auth.pendingEmail ?? 'your ALU email';

    return AuthScaffold(
      title: 'Verify your email',
      subtitle: 'We sent a verification link to $email. Open it, then come '
          'back here. Check your spam folder if it has not arrived.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LoadingButton(
            label: 'I have verified my email',
            icon: Icons.mark_email_read_outlined,
            loading: _checking,
            onPressed: _manualCheck,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _cooldown > 0 || auth.isBusy ? null : _resend,
            child: Text(_cooldown > 0
                ? 'Resend email in ${_cooldown}s'
                : 'Resend verification email'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: auth.signOut,
            child: const Text('Use a different account'),
          ),
        ],
      ),
    );
  }
}
