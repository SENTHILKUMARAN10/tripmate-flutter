import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/trip.dart';
import '../services/trip_service.dart';
import 'create_trip_screen.dart';
import 'document_vault_screen.dart';
import 'story_studio_screen.dart';
import 'trip_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TripService service;

  @override
  void initState() {
    super.initState();
    service = TripService(Supabase.instance.client);
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final firstName = (user?.userMetadata?['full_name'] as String?)?.split(' ').first ?? 'Traveler';

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<Trip>>(
          stream: service.watchTrips(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Could not load trips\n${snapshot.error}', textAlign: TextAlign.center)));
            }
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final trips = snapshot.data!;
            final activeTrip = trips.isEmpty ? null : trips.first;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _TopBar(firstName: firstName)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: activeTrip == null
                        ? _StartJourneyCard(onCreate: _createTrip)
                        : _HeroCard(trip: activeTrip, onTap: () => _openTrip(activeTrip)),
                  ),
                ),
                if (trips.isNotEmpty)
                  SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 18, 16, 0), child: _StatsRow(trips: trips))),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                    child: _SectionTitle(title: 'Everything you need', subtitle: 'Your complete travel toolkit'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _FeatureGrid(
                      trip: activeTrip,
                      onCreateTrip: _createTrip,
                      onTripHub: activeTrip == null ? null : () => _openTrip(activeTrip),
                      onVault: activeTrip == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentVaultScreen(trip: activeTrip))),
                      onStory: activeTrip == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => StoryStudioScreen(trip: activeTrip))),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 26, 16, 12),
                    child: _SectionTitle(title: 'Your journeys', subtitle: trips.isEmpty ? 'Create your first trip to start collecting stories' : '${trips.length} ${trips.length == 1 ? 'trip' : 'trips'} saved'),
                  ),
                ),
                if (trips.isEmpty)
                  SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 120), child: _EmptyJourneyStrip(onCreate: _createTrip)))
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    sliver: SliverList.builder(
                      itemCount: trips.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TripTile(trip: trips[i], onTap: () => _openTrip(trips[i]), onDelete: () => service.deleteTrip(trips[i].id)),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: _createTrip, icon: const Icon(Icons.add_rounded), label: const Text('Plan a trip')),
    );
  }

  void _openTrip(Trip trip) => Navigator.push(context, MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)));

  Future<void> _createTrip() async {
    final trip = await Navigator.push<Trip>(context, MaterialPageRoute(builder: (_) => const CreateTripScreen()));
    if (trip != null && mounted) _openTrip(trip);
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.firstName});
  final String firstName;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 12, 18),
        child: Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF234B44), Color(0xFFB9744C)]), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.travel_explore_rounded, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('TRIPMATE', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900, letterSpacing: 1.7, fontSize: 10)),
            const SizedBox(height: 2),
            Text('Hey, $firstName', style: Theme.of(context).textTheme.headlineSmall),
            Text('Plan less. Experience more.', style: Theme.of(context).textTheme.bodySmall),
          ])),
          IconButton.filledTonal(tooltip: 'Sign out', onPressed: () => Supabase.instance.client.auth.signOut(), icon: const Icon(Icons.logout_rounded)),
        ]),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.headlineSmall), const SizedBox(height: 2), Text(subtitle, style: Theme.of(context).textTheme.bodyMedium)])),
      ]);
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.trip, required this.onTap});
  final Trip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = trip.endDate.difference(trip.startDate).inDays + 1;
    final until = DateTime(trip.startDate.year, trip.startDate.month, trip.startDate.day).difference(DateTime(now.year, now.month, now.day)).inDays;
    final status = until > 0 ? '$until days to go' : until == 0 ? 'Starts today' : now.isBefore(trip.endDate.add(const Duration(days: 1))) ? 'On the road' : 'Memory unlocked';

    return InkWell(
      borderRadius: BorderRadius.circular(32),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(colors: [Color(0xFF173D36), Color(0xFF315C55), Color(0xFFB7754C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: const [BoxShadow(color: Color(0x2A173D36), blurRadius: 32, offset: Offset(0, 16))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .13), borderRadius: BorderRadius.circular(30)), child: const Text('CURRENT JOURNEY', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2))),
            const Spacer(),
            Container(width: 38, height: 38, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), shape: BoxShape.circle), child: const Icon(Icons.arrow_outward_rounded, color: Colors.white)),
          ]),
          const SizedBox(height: 28),
          Text(trip.destination, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1.3)),
          const SizedBox(height: 4),
          Text(trip.title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
          const SizedBox(height: 22),
          Row(children: [
            Expanded(child: _HeroMeta(icon: Icons.calendar_month_rounded, title: '${DateFormat.MMMd().format(trip.startDate)} – ${DateFormat.MMMd().format(trip.endDate)}', subtitle: '$days days')),
            const SizedBox(width: 10),
            Expanded(child: _HeroMeta(icon: Icons.explore_rounded, title: status, subtitle: 'Open trip command centre')),
          ]),
        ]),
      ),
    );
  }
}

class _StartJourneyCard extends StatelessWidget {
  const _StartJourneyCard({required this.onCreate});
  final VoidCallback onCreate;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(32), gradient: const LinearGradient(colors: [Color(0xFF173D36), Color(0xFF315C55), Color(0xFFB7754C)]), boxShadow: const [BoxShadow(color: Color(0x28173D36), blurRadius: 30, offset: Offset(0, 14))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.flight_takeoff_rounded, color: Color(0xFFFFD8BE), size: 34),
          const SizedBox(height: 28),
          const Text('Where to next?', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
          const SizedBox(height: 7),
          const Text('Build the plan, keep tickets safe, track money and turn the ending into a story.', style: TextStyle(color: Colors.white70, height: 1.4)),
          const SizedBox(height: 20),
          FilledButton.tonalIcon(onPressed: onCreate, icon: const Icon(Icons.add_rounded), label: const Text('Start a journey')),
        ]),
      );
}

class _HeroMeta extends StatelessWidget {
  const _HeroMeta({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .10), borderRadius: BorderRadius.circular(18)),
        child: Row(children: [Icon(icon, color: const Color(0xFFFFD5BA), size: 19), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)), const SizedBox(height: 2), Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white60, fontSize: 10))]))]),
      );
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.trips});
  final List<Trip> trips;
  @override
  Widget build(BuildContext context) {
    final totalBudget = trips.fold<double>(0, (sum, t) => sum + t.budget);
    final destinations = trips.map((e) => e.destination.trim().toLowerCase()).where((e) => e.isNotEmpty).toSet().length;
    return Row(children: [
      Expanded(child: _MiniStat(icon: Icons.luggage_rounded, value: '${trips.length}', label: 'Journeys')),
      const SizedBox(width: 10),
      Expanded(child: _MiniStat(icon: Icons.public_rounded, value: '$destinations', label: 'Places')),
      const SizedBox(width: 10),
      Expanded(child: _MiniStat(icon: Icons.account_balance_wallet_rounded, value: '₹${_compactMoney(totalBudget)}', label: 'Planned')),
    ]);
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.trip, required this.onCreateTrip, this.onTripHub, this.onVault, this.onStory});
  final Trip? trip;
  final VoidCallback onCreateTrip;
  final VoidCallback? onTripHub;
  final VoidCallback? onVault;
  final VoidCallback? onStory;

  @override
  Widget build(BuildContext context) {
    final items = <_FeatureData>[
      _FeatureData(Icons.route_rounded, 'Itinerary', 'Day-by-day plan', onTripHub, const Color(0xFFDDEBE7)),
      _FeatureData(Icons.account_balance_wallet_rounded, 'Budget', 'Spend smarter', onTripHub, const Color(0xFFFFE7D8)),
      _FeatureData(Icons.checklist_rounded, 'Packing', 'Never forget it', onTripHub, const Color(0xFFE9E4F7)),
      _FeatureData(Icons.photo_library_outlined, 'Memories', 'Save trip moments', onTripHub, const Color(0xFFFFE0E7)),
      _FeatureData(Icons.confirmation_number_outlined, 'Bookings', 'PNR, hotel & more', onTripHub, const Color(0xFFE1EBFA)),
      _FeatureData(Icons.folder_special_outlined, 'Travel vault', 'ID, tickets, docs', onVault, const Color(0xFFFFEDC8)),
      _FeatureData(Icons.emergency_outlined, 'Emergency', 'Hospital & 112', onTripHub, const Color(0xFFF9DDD8)),
      _FeatureData(Icons.auto_awesome_rounded, 'Story studio', 'Share trip status', onStory, const Color(0xFFDDE8DC)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.23, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        return InkWell(
          onTap: item.onTap ?? onCreateTrip,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant), boxShadow: const [BoxShadow(color: Color(0x0B193C35), blurRadius: 14, offset: Offset(0, 6))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 43, height: 43, decoration: BoxDecoration(color: item.tint, borderRadius: BorderRadius.circular(14)), child: Icon(item.icon, color: const Color(0xFF244B45), size: 22)),
              const Spacer(),
              Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              const SizedBox(height: 2),
              Text(item.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
        );
      },
    );
  }
}

class _FeatureData {
  const _FeatureData(this.icon, this.title, this.subtitle, this.onTap, this.tint);
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color tint;
}

String _compactMoney(double value) {
  if (value >= 100000) return '${(value / 100000).toStringAsFixed(value >= 1000000 ? 0 : 1)}L';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}K';
  return value.toStringAsFixed(0);
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 10), Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), Text(label, style: Theme.of(context).textTheme.bodySmall)]),
      );
}

class _TripTile extends StatelessWidget {
  const _TripTile({required this.trip, required this.onTap, required this.onDelete});
  final Trip trip;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) {
    final initial = trip.destination.isEmpty ? '?' : trip.destination.characters.first.toUpperCase();
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(width: 58, height: 58, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFDDEBE7), Color(0xFFFFE2D0)]), borderRadius: BorderRadius.circular(18)), alignment: Alignment.center, child: Text(initial, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary))),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(trip.destination, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)), const SizedBox(height: 3), Text(trip.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium), const SizedBox(height: 6), Row(children: [Icon(Icons.calendar_today_rounded, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant), const SizedBox(width: 5), Text('${DateFormat.MMMd().format(trip.startDate)} • ₹${trip.budget.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))])])),
            PopupMenuButton<String>(onSelected: (value) { if (value == 'delete') onDelete(); }, itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Delete trip'))]),
          ]),
        ),
      ),
    );
  }
}

class _EmptyJourneyStrip extends StatelessWidget {
  const _EmptyJourneyStrip({required this.onCreate});
  final VoidCallback onCreate;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onCreate,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFFF2EDE4), borderRadius: BorderRadius.circular(24)),
          child: const Row(children: [Icon(Icons.add_circle_outline_rounded, color: Color(0xFF315C55), size: 32), SizedBox(width: 12), Expanded(child: Text('Create a trip and TripMate will turn this space into your personal travel timeline.', style: TextStyle(fontWeight: FontWeight.w700, height: 1.35)))]),
        ),
      );
}
