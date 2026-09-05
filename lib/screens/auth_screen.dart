import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final name = TextEditingController();
  bool signUp = false;
  bool loading = false;
  String? error;
  String? success;

  Future<void> submit() async {
    if (loading) return;

    FocusScope.of(context).unfocus();
    final emailValue = email.text.trim();
    final passwordValue = password.text;
    final nameValue = name.text.trim();

    if (emailValue.isEmpty || passwordValue.isEmpty || (signUp && nameValue.isEmpty)) {
      setState(() => error = 'Please fill in all fields.');
      return;
    }

    setState(() {
      loading = true;
      error = null;
      success = null;
    });

    try {
      final auth = Supabase.instance.client.auth;

      if (signUp) {
        final response = await auth
            .signUp(
              email: emailValue,
              password: passwordValue,
              data: {'full_name': nameValue},
            )
            .timeout(const Duration(seconds: 20));

        if (!mounted) return;

        if (response.session == null) {
          setState(() {
            success = 'Account request sent. Check your email and verify your account, then sign in.';
          });
        } else {
          setState(() => success = 'Account created successfully.');
        }
      } else {
        await auth
            .signInWithPassword(
              email: emailValue,
              password: passwordValue,
            )
            .timeout(const Duration(seconds: 20));
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          error = 'The request is taking too long. Check your internet connection and try once more.';
        });
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      final message = e.message.toLowerCase();
      setState(() {
        if (message.contains('security purposes') || message.contains('after') && message.contains('seconds')) {
          error = 'A signup request was already sent. Please wait a minute before trying again.';
        } else if (message.contains('email not confirmed')) {
          error = 'Please verify your email first, then sign in.';
        } else {
          error = e.message;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: cs.primaryContainer,
                        child: Icon(Icons.flight_takeoff_rounded,
                            size: 32, color: cs.primary),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'TripMate',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        signUp
                            ? 'Create your travel workspace'
                            : 'Plan smarter. Travel lighter.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 24),
                      if (signUp) ...[
                        TextField(
                          controller: name,
                          textInputAction: TextInputAction.next,
                          decoration:
                              const InputDecoration(labelText: 'Full name'),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        decoration:
                            const InputDecoration(labelText: 'Email address'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: password,
                        obscureText: true,
                        onSubmitted: (_) => submit(),
                        decoration:
                            const InputDecoration(labelText: 'Password'),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 12),
                        Text(error!, style: TextStyle(color: cs.error)),
                      ],
                      if (success != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            success!,
                            style: TextStyle(color: cs.onPrimaryContainer),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: loading ? null : submit,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          child: loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(signUp ? 'Create account' : 'Sign in'),
                        ),
                      ),
                      TextButton(
                        onPressed: loading
                            ? null
                            : () => setState(() {
                                  signUp = !signUp;
                                  error = null;
                                  success = null;
                                }),
                        child: Text(signUp
                            ? 'Already have an account? Sign in'
                            : 'New to TripMate? Create account'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
