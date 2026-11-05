import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/feedback.dart';
import '../../widgets/loading_button.dart';
import 'auth_scaffold.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final error = await context
        .read<AuthProvider>()
        .signIn(_email.text, _password.text);
    // On success AuthGate swaps this screen out; only errors need handling.
    if (error != null && mounted) showMessage(context, error, isError: true);
  }

  Future<void> _forgotPassword() async {
    final emailError = Validators.email(_email.text);
    if (emailError != null) {
      showMessage(context, 'Enter your ALU email above first.', isError: true);
      return;
    }
    final error =
        await context.read<AuthProvider>().sendPasswordReset(_email.text);
    if (!mounted) return;
    showMessage(context,
        error ?? 'Password reset link sent to ${_email.text.trim()}.',
        isError: error != null);
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.select<AuthProvider, bool>((a) => a.isBusy);

    return AuthScaffold(
      title: 'Welcome to CampusFix',
      subtitle: 'Report campus issues and follow them until they are fixed.',
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                validator: Validators.email,
                decoration: const InputDecoration(
                  labelText: 'ALU email',
                  hintText: 'name@alustudent.com',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter your password' : null,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'Show password' : 'Hide password',
                    icon: Icon(_obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: busy ? null : _forgotPassword,
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 8),
              LoadingButton(label: 'Sign in', loading: busy, onPressed: _submit),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('New here?'),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const RegisterScreen())),
                    child: const Text('Create an account'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
