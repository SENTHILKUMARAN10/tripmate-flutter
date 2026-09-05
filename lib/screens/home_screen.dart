import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trip.dart';
import '../services/trip_service.dart';
import 'create_trip_screen.dart';
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
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _TopBar(firstName: firstName)),
                if (trips.isEmpty)
                  SliverFillRemaining(hasScrollBody: false, child: _EmptyState(onCreate: _createTrip))
                else ...[
                  SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 6, 16, 0), child: _HeroCard(trip: trips.first, onTap: () => _openTrip(trips.first)))),
                  SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 0), child: _StatsRow(trips: trips))),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Row(
                        children: [
                          Expanded(child: Text('Your journeys', style: Theme.of(context).textTheme.headlineSmall)),
                          Text('${trips.length} trips', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                    sliver: SliverList.builder(
                      itemCount: trips.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TripTile(
                          trip: trips[i],
                          onTap: () => _openTrip(trips[i]),
                          onDelete: () => service.deleteTrip(trips[i].id),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTrip,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Plan a trip'),
      ),
    );
  }

  void _openTrip(Trip trip) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)));
  }

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
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TRIPMATE', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text('Ready to go, $firstName?', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 3),
                  Text('Everything for your journey, in one calm place.', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Sign out',
              onPressed: () => Supabase.instance.client.auth.signOut(),
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
        ),
      );
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
    final status = until > 0 ? 'Starts in $until ${until == 1 ? 'day' : 'days'}' : until == 0 ? 'Starts today' : 'Trip in progress / completed';

    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Color(0xFF244B45), Color(0xFF3B675F), Color(0xFF6E8F87)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [BoxShadow(color: Color(0x241B453E), blurRadius: 28, offset: Offset(0, 14))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: .13), borderRadius: BorderRadius.circular(30)),
                  child: const Text('NEXT JOURNEY', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                ),
                const Spacer(),
                const Icon(Icons.arrow_outward_rounded, color: Colors.white),
              ],
            ),
            const SizedBox(height: 28),
            Text(trip.destination, style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -1)),
            const SizedBox(height: 4),
            Text(trip.title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(child: _HeroMeta(icon: Icons.calendar_month_rounded, title: '${DateFormat.MMMd().format(trip.startDate)} – ${DateFormat.MMMd().format(trip.endDate)}', subtitle: '$days days')),
                const SizedBox(width: 10),
                Expanded(child: _HeroMeta(icon: Icons.schedule_rounded, title: status, subtitle: 'Tap to open trip hub')),
              ],
            ),
          ],
        ),
      ),
    );
  }
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
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFFC8A6), size: 19),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white60, fontSize: 10)),
              ]),
            ),
          ],
        ),
      );
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.trips});
  final List<Trip> trips;

  @override
  Widget build(BuildContext context) {
    final totalBudget = trips.fold<double>(0, (sum, t) => sum + t.budget);
    final destinations = trips.map((e) => e.destination.trim().toLowerCase()).where((e) => e.isNotEmpty).toSet().length;
    return Row(
      children: [
        Expanded(child: _MiniStat(icon: Icons.luggage_rounded, value: '${trips.length}', label: 'Trips')),
        const SizedBox(width: 10),
        Expanded(child: _MiniStat(icon: Icons.public_rounded, value: '$destinations', label: 'Places')),
        const SizedBox(width: 10),
        Expanded(child: _MiniStat(icon: Icons.account_balance_wallet_rounded, value: '₹${_compactMoney(totalBudget)}', label: 'Planned')),
      ],
    );
  }
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ]),
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
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFDDEBE7), Color(0xFFFFE2D0)]),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Text(initial, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.destination, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                    const SizedBox(height: 3),
                    Text(trip.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    Row(children: [
                      Icon(Icons.calendar_today_rounded, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 5),
                      Text('${DateFormat.MMMd().format(trip.startDate)} • ₹${trip.budget.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ]),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Delete trip'))],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 30, 26, 120),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFDDEBE7), Color(0xFFFFE2D0)]), borderRadius: BorderRadius.circular(28)),
              child: const Icon(Icons.travel_explore_rounded, size: 42, color: Color(0xFF315C55)),
            ),
            const SizedBox(height: 20),
            Text('Your next story starts here', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 9),
            const Text('Plan the route, budget, packing, bookings and memories — all inside one trip space.', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(onPressed: onCreate, icon: const Icon(Icons.add_rounded), label: const Text('Create your first trip')),
          ]),
        ),
      ),
    );
  }
}
