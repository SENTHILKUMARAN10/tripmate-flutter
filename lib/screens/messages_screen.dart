import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/social_service.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late final SocialService social;
  Future<List<Map<String, dynamic>>>? conversations;

  @override
  void initState() {
    super.initState();
    social = SocialService(Supabase.instance.client);
    conversations = social.myConversations();
  }

  Future<void> _refresh() async {
    setState(() => conversations = social.myConversations());
    await conversations;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: conversations,
            builder: (context, snapshot) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
                children: [
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Inbox', style: Theme.of(context).textTheme.headlineLarge),
                      const SizedBox(height: 3),
                      Text('Trip plans, random ideas and crew chaos — all here.', style: Theme.of(context).textTheme.bodyMedium),
                    ])),
                    IconButton.filledTonal(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded)),
                  ]),
                  const SizedBox(height: 18),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
                  else if (snapshot.hasError)
                    _InboxEmpty(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Messaging is wired up',
                      text: 'Activate the social Supabase migration to start real-time DMs.',
                    )
                  else if ((snapshot.data ?? []).isEmpty)
                    _InboxEmpty(
                      icon: Icons.forum_outlined,
                      title: 'No messages yet',
                      text: 'Find someone in Circle, tap the chat icon and start your first TripMate DM.',
                    )
                  else
                    ...snapshot.data!.map((item) {
                      final profile = (item['profile'] as Map<String, dynamic>?) ?? {};
                      final last = item['last_message'] as Map<String, dynamic>?;
                      final name = '${profile['full_name'] ?? profile['username'] ?? 'Traveler'}';
                      final username = '${profile['username'] ?? ''}';
                      final body = '${last?['body'] ?? 'Start a conversation'}';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          leading: CircleAvatar(
                            radius: 26,
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: Text(name.isEmpty ? '?' : name.characters.first.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900)),
                          ),
                          title: Row(children: [Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w900))), Text('@$username', style: Theme.of(context).textTheme.bodySmall)]),
                          subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Text(body, maxLines: 1, overflow: TextOverflow.ellipsis)),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                conversationId: item['conversation_id'] as String,
                                title: name,
                              ),
                            ),
                          ).then((_) => _refresh()),
                        ),
                      );
                    }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.conversationId, required this.title});
  final String conversationId;
  final String title;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final SocialService social;
  final message = TextEditingController();
  bool sending = false;

  @override
  void initState() {
    super.initState();
    social = SocialService(Supabase.instance.client);
  }

  @override
  void dispose() {
    message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (message.text.trim().isEmpty || sending) return;
    final body = message.text;
    message.clear();
    setState(() => sending = true);
    try {
      await social.sendMessage(widget.conversationId, body);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not send message.')));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          CircleAvatar(radius: 18, backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: const Icon(Icons.person_rounded, size: 18)),
          const SizedBox(width: 10),
          Expanded(child: Text(widget.title)),
        ]),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: social.watchMessages(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Chat is unavailable until the social migration is active.'));
                final items = snapshot.data ?? [];
                if (items.isEmpty) return const Center(child: Text('Say hi 👋'));
                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.builder(
                    reverse: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                    itemCount: items.length,
                    itemBuilder: (_, index) {
                      final x = items[items.length - 1 - index];
                      final mine = x['sender_id'] == social.userId;
                      return Align(
                        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .76),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            color: mine ? Theme.of(context).colorScheme.primary : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18),
                              topRight: const Radius.circular(18),
                              bottomLeft: Radius.circular(mine ? 18 : 5),
                              bottomRight: Radius.circular(mine ? 5 : 18),
                            ),
                            border: mine ? null : Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                          ),
                          child: Text('${x['body']}', style: TextStyle(color: mine ? Colors.white : Theme.of(context).colorScheme.onSurface, height: 1.35)),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant))),
              child: Row(children: [
                IconButton.filledTonal(onPressed: () {}, icon: const Icon(Icons.add_rounded)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: message,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(hintText: 'Message...', contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: sending ? null : _send, icon: sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.arrow_upward_rounded)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _InboxEmpty extends StatelessWidget {
  const _InboxEmpty({required this.icon, required this.title, required this.text});
  final IconData icon;
  final String title;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
        child: Column(children: [Icon(icon, size: 42, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 12), Text(title, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 5), Text(text, textAlign: TextAlign.center)]),
      );
}
