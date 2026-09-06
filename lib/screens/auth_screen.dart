import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme.dart';

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
        final response = await auth
            .signUp(email: emailValue, password: passwordValue, data: {'full_name': nameValue})
            .timeout(const Duration(seconds: 20));
        if (!mounted) return;
        setState(() {
          success = response.session == null
              ? 'Account created. Verify your email, then come back and sign in.'
              : 'Account created successfully.';
        });
      } else {
        await auth.signInWithPassword(email: emailValue, password: passwordValue).timeout(const Duration(seconds: 20));
      }
    } on TimeoutException {
      if (mounted) setState(() => error = 'The request is taking too long. Check your connection and try again.');
    } on AuthException catch (e) {
      if (!mounted) return;
      final message = e.message.toLowerCase();
      setState(() {
        if (message.contains('rate limit') || message.contains('security purposes') || (message.contains('after') && message.contains('seconds'))) {
          error = 'Too many attempts. Wait a little, then try again.';
        } else if (message.contains('email not confirmed')) {
          error = 'Verify your email first, then sign in.';
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
    return Scaffold(
      backgroundColor: AppTheme.midnight,
      body: Stack(
        children: [
          const Positioned.fill(child: _AuroraBackground()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 46),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 850),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) => Opacity(
                          opacity: value,
                          child: Transform.translate(offset: Offset(0, 18 * (1 - value)), child: child),
                        ),
                        child: _BrandHero(signUp: signUp),
                      ),
                      const SizedBox(height: 18),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 420),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(begin: const Offset(0, .04), end: Offset.zero).animate(animation),
                            child: child,
                          ),
                        ),
                        child: _AuthPanel(
                          key: ValueKey(signUp),
                          signUp: signUp,
                          loading: loading,
                          showPassword: showPassword,
                          email: email,
                          password: password,
                          name: name,
                          error: error,
                          success: success,
                          onSubmit: submit,
                          onTogglePassword: () => setState(() => showPassword = !showPassword),
                          onToggleMode: () => setState(() {
                            signUp = !signUp;
                            error = null;
                            success = null;
                          }),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Private by design • Powered by Supabase',
                        style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuroraBackground extends StatefulWidget {
  const _AuroraBackground();

  @override
  State<_AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<_AuroraBackground> with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(controller.value);
          return Stack(
            children: [
              Positioned(
                top: -120 + 35 * t,
                right: -90 + 22 * t,
                child: _GlowOrb(size: 300, color: AppTheme.violet.withValues(alpha: .33)),
              ),
              Positioned(
                top: 220 - 24 * t,
                left: -140 + 28 * t,
                child: _GlowOrb(size: 290, color: AppTheme.cyan.withValues(alpha: .20)),
              ),
              Positioned(
                bottom: -160 + 25 * t,
                right: -100 - 18 * t,
                child: _GlowOrb(size: 310, color: AppTheme.coral.withValues(alpha: .15)),
              ),
            ],
          );
        },
      );
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      );
}

class _BrandHero extends StatelessWidget {
  const _BrandHero({required this.signUp});
  final bool signUp;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: .10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppTheme.violet, AppTheme.cyan]),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [BoxShadow(color: Color(0x556C5CE7), blurRadius: 22, offset: Offset(0, 10))],
                  ),
                  child: const Icon(Icons.flight_takeoff_rounded, color: Colors.white, size: 28),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: .07), borderRadius: BorderRadius.circular(30)),
                  child: const Row(
                    children: [
                      Icon(Icons.bolt_rounded, color: Color(0xFFB7F5F8), size: 15),
                      SizedBox(width: 5),
                      Text('TRAVEL OS', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text('TripMate', style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: -1.4)),
            const SizedBox(height: 7),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: Text(
                signUp ? 'Your journey starts before the trip.' : 'Everything your trip needs, in one place.',
                key: ValueKey(signUp),
                style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800, height: 1.25),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Plan • Crew • Tickets • Budget • Memories • Stories',
              style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
}

class _AuthPanel extends StatelessWidget {
  const _AuthPanel({
    super.key,
    required this.signUp,
    required this.loading,
    required this.showPassword,
    required this.email,
    required this.password,
    required this.name,
    required this.error,
    required this.success,
    required this.onSubmit,
    required this.onTogglePassword,
    required this.onToggleMode,
  });

  final bool signUp;
  final bool loading;
  final bool showPassword;
  final TextEditingController email;
  final TextEditingController password;
  final TextEditingController name;
  final String? error;
  final String? success;
  final VoidCallback onSubmit;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleMode;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFD),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 34, offset: Offset(0, 18))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(signUp ? 'Create your space' : 'Welcome back', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 5),
          Text(signUp ? 'Build your profile and start your first journey.' : 'Continue where your last trip left off.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          if (signUp) ...[
            TextField(
              controller: name,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline_rounded)),
            ),
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
            onSubmitted: (_) => onSubmit(),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(onPressed: onTogglePassword, icon: Icon(showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded)),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            _MessageBanner(icon: Icons.error_outline_rounded, text: error!, color: cs.errorContainer, foreground: cs.onErrorContainer),
          ],
          if (success != null) ...[
            const SizedBox(height: 12),
            _MessageBanner(icon: Icons.check_circle_outline_rounded, text: success!, color: const Color(0xFFE7F8EF), foreground: const Color(0xFF19613A)),
          ],
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.violet, Color(0xFF7D6FFF), AppTheme.cyan]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Color(0x336C5CE7), blurRadius: 18, offset: Offset(0, 8))],
            ),
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
              onPressed: loading ? null : onSubmit,
              child: loading
                  ? const SizedBox(width: 21, height: 21, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(signUp ? 'Create account' : 'Enter TripMate'),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 19),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: loading ? null : onToggleMode,
            child: Text(signUp ? 'Already have an account? Sign in' : 'New here? Create your TripMate account'),
          ),
        ],
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({required this.icon, required this.text, required this.color, required this.foreground});
  final IconData icon;
  final String text;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: TextStyle(color: foreground, fontWeight: FontWeight.w700))),
          ],
        ),
      );
}
