import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
              const SizedBox(height: 6),
              const Text('A 24-hour travel mood. No perfect feed. Just where you are and how it feels.'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: ['✨','🌧️','🌿','🔥','🥶','🌅','🛵','🍜'].map((x) => ChoiceChip(
                  selected: vibe == x,
                  label: Text(x, style: const TextStyle(fontSize: 20)),
                  onSelected: (_) => setLocal(() => vibe = x),
                )).toList(),
              ),
              const SizedBox(height: 14),
              TextField(controller: caption, decoration: const InputDecoration(labelText: 'What is the moment?', prefixIcon: Icon(Icons.bolt_rounded))),
              const SizedBox(height: 10),
              TextField(controller: place, decoration: const InputDecoration(labelText: 'Place (optional)', prefixIcon: Icon(Icons.location_on_outlined))),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () async {
                  await social.createVibeDrop(vibe: vibe, caption: caption.text, place: place.text);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Drop for 24 hours'),
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
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('TripVerse', style: Theme.of(context).textTheme.headlineLarge),
                      const SizedBox(height: 3),
                      Text('Fresh travel energy, not another social feed.', style: Theme.of(context).textTheme.bodyMedium),
                    ]),
                  ),
                  IconButton.filled(onPressed: _dropVibe, icon: const Icon(Icons.bolt_rounded)),
                ],
              ),
              const SizedBox(height: 22),
              _ConceptHero(onTap: _dropVibe),
              const SizedBox(height: 24),
              Text('Live vibe drops', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('24-hour travel moods from the TripMate community.', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              StreamBuilder<List<Map<String, dynamic>>>(
                key: ValueKey(refreshKey),
                stream: social.watchVibeDrops(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _SoftPanel(
                      icon: Icons.rocket_launch_rounded,
                      title: 'TripVerse is getting ready',
                      text: 'The social backend migration still needs to be activated in Supabase.',
                    );
                  }
                  final drops = snapshot.data ?? [];
                  if (drops.isEmpty) {
                    return _SoftPanel(
                      icon: Icons.bolt_rounded,
                      title: 'Be the first vibe',
                      text: 'Drop a small travel moment. It disappears after 24 hours.',
                    );
                  }
                  return Column(
                    children: drops.take(8).map((x) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFFDCEBE7), Color(0xFFFFDFC9)]),
                              borderRadius: BorderRadius.circular(17),
                            ),
                            child: Text('${x['vibe'] ?? '✨'}', style: const TextStyle(fontSize: 24)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('${x['caption'] ?? 'Travel moment'}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                              if ('${x['place'] ?? ''}'.trim().isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text('${x['place']}', style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ]),
                          ),
                          const Icon(Icons.timelapse_rounded, size: 19),
                        ],
                      ),
                    )).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text('Future-native features', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              const _FutureFeature(icon: Icons.lock_clock_rounded, title: 'Time Capsule', text: 'Seal photos + a note during the trip. Unlock them only after you return.'),
              const _FutureFeature(icon: Icons.radar_rounded, title: 'Crew Radar', text: 'See who in your trip crew is nearby or available to meet — only when everyone opts in.'),
              const _FutureFeature(icon: Icons.graphic_eq_rounded, title: 'MoodMap', text: 'Mark each place with a vibe. At the end, your trip becomes a visual mood trail.'),
              const _FutureFeature(icon: Icons.auto_awesome_motion_rounded, title: 'Memory Remix', text: 'Turn moments, expenses, places and vibes into one cinematic trip recap.'),
              const _FutureFeature(icon: Icons.local_fire_department_rounded, title: 'Travel Streaks', text: 'Fun badges for sunrise missions, local food hunts, no-spend days and spontaneous detours.'),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConceptHero extends StatelessWidget {
  const _ConceptHero({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(colors: [Color(0xFF101A18), Color(0xFF1F4B43), Color(0xFFAF6F4B)]),
          boxShadow: const [BoxShadow(color: Color(0x2711342F), blurRadius: 28, offset: Offset(0, 14))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(20)), child: const Text('NEW • VIBE DROP', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.1))),
            const Spacer(),
            const Icon(Icons.blur_on_rounded, color: Colors.white70),
          ]),
          const SizedBox(height: 38),
          const Text('Your trip.\nRight now.', style: TextStyle(color: Colors.white, fontSize: 34, height: .98, fontWeight: FontWeight.w900, letterSpacing: -1.2)),
          const SizedBox(height: 10),
          const Text('No likes. No polished feed. A small 24-hour travel mood for your crew and community.', style: TextStyle(color: Colors.white70, height: 1.4)),
          const SizedBox(height: 18),
          FilledButton.tonalIcon(onPressed: onTap, icon: const Icon(Icons.bolt_rounded), label: const Text('Drop a vibe')),
        ]),
      );
}

class _FutureFeature extends StatelessWidget {
  const _FutureFeature({required this.icon, required this.title, required this.text});
  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
        child: Row(children: [
          Container(width: 46, height: 46, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: Theme.of(context).colorScheme.primary)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(text, style: Theme.of(context).textTheme.bodySmall)])),
        ]),
      );
}

class _SoftPanel extends StatelessWidget {
  const _SoftPanel({required this.icon, required this.title, required this.text});
  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: .45), borderRadius: BorderRadius.circular(24)),
        child: Row(children: [Icon(icon, size: 30), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), Text(text)]))]),
      );
}
