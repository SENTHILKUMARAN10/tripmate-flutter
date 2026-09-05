import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/social_service.dart';
import 'messages_screen.dart';

class CircleScreen extends StatefulWidget {
  const CircleScreen({super.key});

  @override
  State<CircleScreen> createState() => _CircleScreenState();
}

class _CircleScreenState extends State<CircleScreen> {
  late final SocialService social;
  final search = TextEditingController();
  List<Map<String, dynamic>> results = [];
  bool searching = false;
  int refreshKey = 0;

  @override
  void initState() {
    super.initState();
    social = SocialService(Supabase.instance.client);
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String value) async {
    if (value.trim().length < 2) {
      setState(() => results = []);
      return;
    }
    setState(() => searching = true);
    try {
      final rows = await social.searchProfiles(value);
      if (mounted) setState(() => results = rows);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Social features need the new Supabase migration first.')));
      }
    } finally {
      if (mounted) setState(() => searching = false);
    }
  }

  Future<void> _refresh() async {
    setState(() => refreshKey++);
    await _runSearch(search.text);
  }

  Future<void> _message(Map<String, dynamic> profile) async {
    final id = profile['id'] as String;
    try {
      final conversationId = await social.openDirectConversation(id);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversationId,
            title: '${profile['full_name'] ?? profile['username'] ?? 'Traveler'}',
          ),
        ),
      );
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Messaging will work after the social migration is activated.')));
    }
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
              Text('Your Circle', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 3),
              Text('Find travelers by @username, tag your crew and message directly.', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 18),
              TextField(
                controller: search,
                onChanged: _runSearch,
                decoration: InputDecoration(
                  hintText: 'Search @username or name',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: searching
                      ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
                      : search.text.isNotEmpty
                          ? IconButton(onPressed: () { search.clear(); setState(() => results = []); }, icon: const Icon(Icons.close_rounded))
                          : null,
                ),
              ),
              const SizedBox(height: 16),
              if (results.isNotEmpty) ...[
                Text('People', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                ...results.map((p) => _PersonCard(
                      profile: p,
                      onAdd: () async {
                        await social.sendFriendRequest(p['id'] as String);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Friend request sent to @${p['username']}')));
                      },
                      onMessage: () => _message(p),
                    )),
                const SizedBox(height: 22),
              ],
              Row(children: [
                Expanded(child: Text('Friend requests & crew', style: Theme.of(context).textTheme.titleLarge)),
                IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded)),
              ]),
              const SizedBox(height: 8),
              StreamBuilder<List<Map<String, dynamic>>>(
                key: ValueKey(refreshKey),
                stream: social.watchFriendships(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _InfoPanel(
                      icon: Icons.group_add_rounded,
                      title: 'Social layer is ready in code',
                      text: 'Activate the new Supabase social migration and this page becomes live.',
                    );
                  }
                  final rows = snapshot.data ?? [];
                  if (rows.isEmpty) {
                    return _InfoPanel(
                      icon: Icons.people_alt_outlined,
                      title: 'Build your travel circle',
                      text: 'Search a friend by username, send a request, then tag them into your trips.',
                    );
                  }
                  return Column(
                    children: rows.map((f) => _FriendshipTile(social: social, row: f)).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: const LinearGradient(colors: [Color(0xFF173D36), Color(0xFF315C55)]),
                ),
                child: const Row(children: [
                  Icon(Icons.groups_3_rounded, color: Color(0xFFFFD7BA), size: 34),
                  SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Trip Crew', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                    SizedBox(height: 4),
                    Text('Tag accepted friends into a journey so plans, memories and chats feel like one shared trip space.', style: TextStyle(color: Colors.white70, height: 1.35)),
                  ])),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({required this.profile, required this.onAdd, required this.onMessage});
  final Map<String, dynamic> profile;
  final VoidCallback onAdd;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    final name = '${profile['full_name'] ?? 'Traveler'}';
    final username = '${profile['username'] ?? ''}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
      child: Row(children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(name.isEmpty ? '?' : name.characters.first.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          Text('@$username', style: Theme.of(context).textTheme.bodySmall),
          if ('${profile['travel_style'] ?? ''}'.trim().isNotEmpty) Text('${profile['travel_style']}', style: Theme.of(context).textTheme.bodySmall),
        ])),
        IconButton.filledTonal(onPressed: onMessage, icon: const Icon(Icons.chat_bubble_outline_rounded)),
        const SizedBox(width: 4),
        IconButton.filled(onPressed: onAdd, icon: const Icon(Icons.person_add_alt_1_rounded)),
      ]),
    );
  }
}

class _FriendshipTile extends StatelessWidget {
  const _FriendshipTile({required this.social, required this.row});
  final SocialService social;
  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final mine = social.userId;
    final incoming = row['addressee_id'] == mine;
    final otherId = incoming ? row['requester_id'] as String : row['addressee_id'] as String;
    final status = '${row['status'] ?? 'pending'}';
    return FutureBuilder<Map<String, dynamic>?>(
      future: social.profileById(otherId),
      builder: (context, snapshot) {
        final p = snapshot.data;
        final label = p == null ? 'Traveler' : '${p['full_name'] ?? p['username'] ?? 'Traveler'}';
        final username = p == null ? '' : '@${p['username'] ?? ''}';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
          child: Row(children: [
            const CircleAvatar(child: Icon(Icons.person_rounded)),
            const SizedBox(width: 11),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontWeight: FontWeight.w900)), Text(username, style: Theme.of(context).textTheme.bodySmall)])),
            if (status == 'pending' && incoming)
              FilledButton.tonal(onPressed: () => social.acceptFriendRequest(row['id'] as String), child: const Text('Accept'))
            else
              Text(status == 'accepted' ? 'Friends' : 'Requested', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800)),
          ]),
        );
      },
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.icon, required this.title, required this.text});
  final IconData icon;
  final String title;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: .45), borderRadius: BorderRadius.circular(24)),
        child: Row(children: [Icon(icon, size: 31), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(text)]))]),
      );
}
