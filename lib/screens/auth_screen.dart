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
  bool showPassword = false;
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
        final response = await auth.signUp(
          email: emailValue,
          password: passwordValue,
          data: {'full_name': nameValue},
        ).timeout(const Duration(seconds: 20));
        if (!mounted) return;
        setState(() {
          success = response.session == null
              ? 'Account request sent. Check your email and verify your account, then sign in.'
              : 'Account created successfully.';
        });
      } else {
        await auth.signInWithPassword(email: emailValue, password: passwordValue).timeout(const Duration(seconds: 20));
      }
    } on TimeoutException {
      if (mounted) setState(() => error = 'The request is taking too long. Check your internet connection and try again.');
    } on AuthException catch (e) {
      if (!mounted) return;
      final message = e.message.toLowerCase();
      setState(() {
        if (message.contains('rate limit') || message.contains('security purposes') || (message.contains('after') && message.contains('seconds'))) {
          error = 'Too many signup attempts. Please wait a little before trying again.';
        } else if (message.contains('email not confirmed')) {
          error = 'Please verify your email first, then sign in.';
        } else {
          error = e.message;
        }
      });
    } catch (_) {
      if (mounted) setState(() => error = 'Something went wrong. Please try again.');
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
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 46),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF244B45), Color(0xFF51786F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .13), borderRadius: BorderRadius.circular(18)),
                          child: const Icon(Icons.travel_explore_rounded, color: Color(0xFFFFC8A6), size: 30),
                        ),
                        const SizedBox(height: 28),
                        const Text('TripMate', style: TextStyle(color: Colors.white, fontSize: 35, fontWeight: FontWeight.w900, letterSpacing: -1)),
                        const SizedBox(height: 7),
                        Text(
                          signUp ? 'One app for the whole journey.' : 'Your trips. Your plans. Your memories.',
                          style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        const Text('Plan, budget, save bookings, pack smarter and keep the moments worth remembering.', style: TextStyle(color: Colors.white70, height: 1.45)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(signUp ? 'Create your account' : 'Welcome back', style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 5),
                          Text(signUp ? 'Start building your travel space.' : 'Sign in to continue your journey.', style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 20),
                          if (signUp) ...[
                            TextField(controller: name, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline_rounded))),
                            const SizedBox(height: 11),
                          ],
                          TextField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.alternate_email_rounded)),
                          ),
                          const SizedBox(height: 11),
                          TextField(
                            controller: password,
                            obscureText: !showPassword,
                            onSubmitted: (_) => submit(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => showPassword = !showPassword),
                                icon: Icon(showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                              ),
                            ),
                          ),
                          if (error != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: cs.errorContainer, borderRadius: BorderRadius.circular(14)),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Icon(Icons.info_outline_rounded, size: 18, color: cs.error),
                                const SizedBox(width: 8),
                                Expanded(child: Text(error!, style: TextStyle(color: cs.onErrorContainer, fontWeight: FontWeight.w600))),
                              ]),
                            ),
                          ],
                          if (success != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(14)),
                              child: Text(success!, style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w600)),
                            ),
                          ],
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: loading ? null : submit,
                            child: loading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text(signUp ? 'Create account' : 'Sign in'),
                          ),
                          const SizedBox(height: 4),
                          TextButton(
                            onPressed: loading ? null : () => setState(() {
                              signUp = !signUp;
                              error = null;
                              success = null;
                            }),
                            child: Text(signUp ? 'Already have an account? Sign in' : 'New to TripMate? Create account'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
