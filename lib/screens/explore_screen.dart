import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme.dart';
import '../services/social_service.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late final SocialService social;
  int refreshKey = 0;

  @override
  void initState() {
    super.initState();
    social = SocialService(Supabase.instance.client);
  }

  Future<void> _refresh() async {
    setState(() => refreshKey++);
    await Future<void>.delayed(const Duration(milliseconds: 450));
  }

  Future<void> _dropVibe() async {
    String vibe = '✨';
    final caption = TextEditingController();
    final place = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.viewInsetsOf(ctx).bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Drop your vibe', style: Theme.of(ctx).textTheme.headlineSmall),
              const SizedBox(height: 5),
              Text('A 24-hour travel mood. Fast, real and temporary.', style: Theme.of(ctx).textTheme.bodyMedium),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['✨', '🌧️', '🌿', '🔥', '🥶', '🌅', '🛵', '🍜']
                    .map((x) => ChoiceChip(selected: vibe == x, label: Text(x, style: const TextStyle(fontSize: 20)), onSelected: (_) => setLocal(() => vibe = x)))
                    .toList(),
              ),
              const SizedBox(height: 14),
              TextField(controller: caption, decoration: const InputDecoration(labelText: 'What is happening?', prefixIcon: Icon(Icons.bolt_rounded))),
              const SizedBox(height: 10),
              TextField(controller: place, decoration: const InputDecoration(labelText: 'Place (optional)', prefixIcon: Icon(Icons.location_on_outlined))),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  await social.createVibeDrop(vibe: vibe, caption: caption.text, place: place.text);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                icon: const Icon(Icons.bolt_rounded),
                label: const Text('Drop for 24 hours'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppTheme.violet,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
            children: [
              _Entrance(
                delay: 0,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TRIPVERSE', style: TextStyle(color: AppTheme.violet, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.7)),
                          const SizedBox(height: 3),
                          Text('Travel, happening now.', style: Theme.of(context).textTheme.headlineLarge),
                          const SizedBox(height: 3),
                          Text('A social layer built around real trips.', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.violet, AppTheme.cyan]), borderRadius: BorderRadius.circular(18)),
                      child: IconButton(onPressed: _dropVibe, icon: const Icon(Icons.bolt_rounded, color: Colors.white)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _Entrance(delay: 80, child: _ConceptHero(onTap: _dropVibe)),
              const SizedBox(height: 26),
              _Entrance(delay: 130, child: _SectionTitle(title: 'Live drops', subtitle: '24-hour moments from travelers')),
              const SizedBox(height: 12),
              StreamBuilder<List<Map<String, dynamic>>>(
                key: ValueKey(refreshKey),
                stream: social.watchVibeDrops(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const _SoftPanel(icon: Icons.rocket_launch_rounded, title: 'TripVerse is waking up', text: 'The social backend is not available right now. Pull down to retry.');
                  }
                  final drops = snapshot.data ?? [];
                  if (drops.isEmpty) {
                    return _SoftPanel(icon: Icons.bolt_rounded, title: 'Start the energy', text: 'Drop a tiny travel moment. It disappears after 24 hours.', action: _dropVibe);
                  }
                  return Column(
                    children: List.generate(drops.take(8).length, (i) {
                      final x = drops[i];
                      return _Entrance(delay: 160 + i * 45, child: _VibeCard(data: x));
                    }),
                  );
                },
              ),
              const SizedBox(height: 26),
              _Entrance(delay: 220, child: const _SectionTitle(title: 'Next-gen travel', subtitle: 'Ideas made for the way Gen-Z actually travels')),
              const SizedBox(height: 12),
              const _FutureGrid(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Entrance extends StatelessWidget {
  const _Entrance({required this.child, required this.delay});
  final Widget child;
  final int delay;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 500 + delay),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 16 * (1 - value)), child: child)),
        child: child,
      );
}

class _ConceptHero extends StatelessWidget {
  const _ConceptHero({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(colors: [Color(0xFF0E1325), Color(0xFF3E2F82), Color(0xFF0D6972)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: const [BoxShadow(color: Color(0x3D2A225E), blurRadius: 32, offset: Offset(0, 16))],
        ),
        child: Stack(
          children: [
            Positioned(right: -45, top: -55, child: Container(width: 180, height: 180, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .05)))),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .08), borderRadius: BorderRadius.circular(20)),
                      child: const Text('⚡ VIBE DROP', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
                    ),
                    const Spacer(),
                    const Icon(Icons.blur_on_rounded, color: Color(0xFFB7F5F8)),
                  ],
                ),
                const SizedBox(height: 42),
                const Text('No feed.\nJust the moment.', style: TextStyle(color: Colors.white, fontSize: 35, height: 1.0, fontWeight: FontWeight.w900, letterSpacing: -1.2)),
                const SizedBox(height: 11),
                const Text('Share where you are and how the trip feels. It vanishes in 24 hours.', style: TextStyle(color: Colors.white60, height: 1.45)),
                const SizedBox(height: 20),
                FilledButton.icon(onPressed: onTap, icon: const Icon(Icons.bolt_rounded), label: const Text('Drop a vibe')),
              ],
            ),
          ],
        ),
      );
}

class _VibeCard extends StatelessWidget {
  const _VibeCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFE7EAF2))),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFE9E5FF), Color(0xFFDDFBFD)]), borderRadius: BorderRadius.circular(18)),
              child: Text('${data['vibe'] ?? '✨'}', style: const TextStyle(fontSize: 25)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${data['caption'] ?? 'Travel moment'}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  if ('${data['place'] ?? ''}'.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(children: [const Icon(Icons.location_on_rounded, size: 13, color: AppTheme.violet), const SizedBox(width: 3), Expanded(child: Text('${data['place']}', style: Theme.of(context).textTheme.bodySmall))]),
                  ],
                ],
              ),
            ),
            const Icon(Icons.timelapse_rounded, size: 19, color: Color(0xFF8C93A4)),
          ],
        ),
      );
}

class _FutureGrid extends StatelessWidget {
  const _FutureGrid();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.lock_clock_rounded, 'Time Capsule', 'Seal moments now. Unlock after the trip.', Color(0xFFE9E5FF), AppTheme.violet),
      (Icons.radar_rounded, 'Crew Radar', 'Opt-in proximity for your travel crew.', Color(0xFFDDFBFD), Color(0xFF0D8E98)),
      (Icons.graphic_eq_rounded, 'MoodMap', 'Turn every place into a visual vibe trail.', Color(0xFFFFEAE3), Color(0xFFCF6848)),
      (Icons.auto_awesome_motion_rounded, 'Memory Remix', 'Auto-create a cinematic recap.', Color(0xFFFCE6F1), Color(0xFFB64F81)),
      (Icons.local_fire_department_rounded, 'Travel Streaks', 'Challenges, detours and local missions.', Color(0xFFFFF0C9), Color(0xFFAE7B18)),
      (Icons.bubble_chart_rounded, 'Orbit Rooms', 'Temporary crew rooms that expire after a trip.', Color(0xFFE5EEFF), Color(0xFF416CC4)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: .94, crossAxisSpacing: 11, mainAxisSpacing: 11),
      itemBuilder: (_, i) {
        final x = items[i];
        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFE7EAF2))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 42, height: 42, decoration: BoxDecoration(color: x.$4, borderRadius: BorderRadius.circular(14)), child: Icon(x.$1, color: x.$5, size: 21)),
              const Spacer(),
              Text(x.$2, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              const SizedBox(height: 4),
              Text(x.$3, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.headlineSmall), const SizedBox(height: 3), Text(subtitle, style: Theme.of(context).textTheme.bodyMedium)]);
}

class _SoftPanel extends StatelessWidget {
  const _SoftPanel({required this.icon, required this.title, required this.text, this.action});
  final IconData icon;
  final String title;
  final String text;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), border: Border.all(color: const Color(0xFFE7EAF2))),
        child: Column(
          children: [
            Container(width: 54, height: 54, decoration: BoxDecoration(color: const Color(0xFFE9E5FF), borderRadius: BorderRadius.circular(18)), child: Icon(icon, color: AppTheme.violet, size: 27)),
            const SizedBox(height: 13),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 5),
            Text(text, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            if (action != null) ...[const SizedBox(height: 14), FilledButton.icon(onPressed: action, icon: const Icon(Icons.bolt_rounded), label: const Text('Create vibe'))],
          ],
        ),
      );
}
