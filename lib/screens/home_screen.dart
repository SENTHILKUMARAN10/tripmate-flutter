import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/design.dart';
import '../models/trip.dart';
import '../services/trip_service.dart';
import 'create_trip_screen.dart';
import 'document_vault_screen.dart';
import 'story_studio_screen.dart';
import 'trip_detail_screen.dart';
import 'trip_feature_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TripService service;
  int refreshKey = 0;

  @override
  void initState() {
    super.initState();
    service = TripService(Supabase.instance.client);
  }

  Future<void> _refresh() async {
    setState(() => refreshKey++);
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final firstName = (user?.userMetadata?['full_name'] as String?)?.split(' ').first ?? 'Traveler';

    return Scaffold(
      body: TripMateWaveBackground(
        child: SafeArea(
          child: StreamBuilder<List<Trip>>(
            key: ValueKey(refreshKey),
            stream: service.watchTrips(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Could not load trips\n${snapshot.error}', textAlign: TextAlign.center)));
              }
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final trips = snapshot.data!;
              final activeTrip = trips.isEmpty ? null : trips.first;

              return RefreshIndicator(
                onRefresh: _refresh,
                color: TripMateColors.navy800,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 122),
                  children: [
                    _Entrance(delay: 0, child: _header(firstName)),
                    const SizedBox(height: 18),
                    _Entrance(delay: 70, child: activeTrip == null ? _emptyHero() : _tripHero(activeTrip)),
                    const SizedBox(height: 18),
                    _Entrance(delay: 120, child: _stats(trips)),
                    const SizedBox(height: 28),
                    _Entrance(delay: 160, child: const TripMatePageHeader(eyebrow: 'TRAVEL OS', title: 'Everything. One trip.', subtitle: 'Every major travel problem gets its own focused space — no more digging through one giant page.')),
                    const SizedBox(height: 16),
                    _Entrance(delay: 210, child: _featureGrid(activeTrip)),
                    const SizedBox(height: 30),
                    _Entrance(delay: 250, child: TripMatePageHeader(eyebrow: 'JOURNEYS', title: trips.isEmpty ? 'Start collecting places.' : 'Your travel library.', subtitle: trips.isEmpty ? 'Create the first trip and TripMate will build your travel workspace.' : '${trips.length} ${trips.length == 1 ? 'journey' : 'journeys'} synced with your account.')),
                    const SizedBox(height: 14),
                    if (trips.isEmpty)
                      _Entrance(delay: 280, child: _emptyLibrary())
                    else
                      ...List.generate(trips.length, (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _Entrance(delay: 280 + i * 35, child: _tripTile(trips[i])),
                      )),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new-trip',
        onPressed: _createTrip,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New trip'),
      ),
    );
  }

  Widget _header(String firstName) => Row(children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(gradient: TripMateGradient.hero, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x30052659), blurRadius: 20, offset: Offset(0, 10))]),
          child: const Icon(Icons.travel_explore_rounded, color: TripMateColors.ice),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('TRIPMATE', style: TextStyle(color: TripMateColors.blue600, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.9)),
          const SizedBox(height: 2),
          Text('Hey, $firstName 👋', style: Theme.of(context).textTheme.headlineSmall),
          Text('Your next story starts here.', style: Theme.of(context).textTheme.bodySmall),
        ])),
        IconButton.filledTonal(onPressed: () => Supabase.instance.client.auth.signOut(), icon: const Icon(Icons.logout_rounded)),
      ]);

  Widget _tripHero(Trip trip) {
    final days = trip.endDate.difference(trip.startDate).inDays + 1;
    return TripMateSurface(
      onTap: () => _openTrip(trip),
      gradient: TripMateGradient.hero,
      padding: const EdgeInsets.all(22),
      child: Stack(children: [
        Positioned(right: -30, top: -40, child: Container(width: 165, height: 165, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .05), borderRadius: BorderRadius.circular(70)))),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7), decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(30)), child: const Text('ACTIVE TRIP', style: TextStyle(color: TripMateColors.ice, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2))),
            const Spacer(),
            const Icon(Icons.arrow_outward_rounded, color: Colors.white),
          ]),
          const SizedBox(height: 30),
          Text(trip.destination, style: const TextStyle(color: Colors.white, fontSize: 39, fontWeight: FontWeight.w900, letterSpacing: -1.5)),
          const SizedBox(height: 4),
          Text(trip.title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
          const SizedBox(height: 22),
          Row(children: [
            Expanded(child: _heroMeta(Icons.calendar_month_rounded, '${DateFormat.MMMd().format(trip.startDate)} – ${DateFormat.MMMd().format(trip.endDate)}', '$days days')),
            const SizedBox(width: 10),
            Expanded(child: _heroMeta(Icons.wallet_rounded, '₹${trip.budget.toStringAsFixed(0)}', 'trip budget')),
          ]),
        ]),
      ]),
    );
  }

  Widget _emptyHero() => TripMateSurface(
        gradient: TripMateGradient.hero,
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const TripMateIconBubble(Icons.flight_takeoff_rounded, size: 58),
          const SizedBox(height: 28),
          const Text('Where are we going?', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -1.2)),
          const SizedBox(height: 8),
          const Text('Plan the route, invite the crew, secure documents, track money and turn the ending into a story.', style: TextStyle(color: Colors.white70, height: 1.45, fontWeight: FontWeight.w600)),
          const SizedBox(height: 18),
          FilledButton.tonalIcon(onPressed: _createTrip, icon: const Icon(Icons.add_rounded), label: const Text('Create first journey')),
        ]),
      );

  Widget _heroMeta(IconData icon, String top, String bottom) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .09), borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          Icon(icon, color: TripMateColors.ice, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(top, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
            const SizedBox(height: 2),
            Text(bottom, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600)),
          ])),
        ]),
      );

  Widget _stats(List<Trip> trips) {
    final places = trips.map((e) => e.destination.trim().toLowerCase()).where((e) => e.isNotEmpty).toSet().length;
    final budget = trips.fold<double>(0, (sum, t) => sum + t.budget);
    return Row(children: [
      Expanded(child: _stat(Icons.luggage_rounded, '${trips.length}', 'Trips')),
      const SizedBox(width: 10),
      Expanded(child: _stat(Icons.public_rounded, '$places', 'Places')),
      const SizedBox(width: 10),
      Expanded(child: _stat(Icons.account_balance_wallet_rounded, '₹${_compactMoney(budget)}', 'Planned')),
    ]);
  }

  Widget _stat(IconData icon, String value, String label) => TripMateSurface(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Column(children: [TripMateIconBubble(icon, size: 38), const SizedBox(height: 8), Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)), Text(label, style: Theme.of(context).textTheme.bodySmall)]),
      );

  Widget _featureGrid(Trip? trip) {
    final features = [
      _Feature(Icons.route_rounded, 'Itinerary', 'Day-by-day', TripFeature.itinerary),
      _Feature(Icons.wallet_rounded, 'Budget', 'Money control', TripFeature.budget),
      _Feature(Icons.backpack_rounded, 'Packing', 'Smart checklist', TripFeature.packing),
      _Feature(Icons.photo_library_rounded, 'Memories', 'Trip moments', TripFeature.memories),
      _Feature(Icons.confirmation_number_rounded, 'Bookings', 'Tickets & stays', TripFeature.bookings),
      _Feature(Icons.health_and_safety_rounded, 'Emergency', 'Travel safety', TripFeature.emergency),
    ];

    return Column(children: [
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.16, crossAxisSpacing: 12, mainAxisSpacing: 12),
        itemCount: features.length,
        itemBuilder: (_, i) {
          final f = features[i];
          return TripMateSurface(
            onTap: () => trip == null ? _createTrip() : Navigator.push(context, MaterialPageRoute(builder: (_) => TripFeatureScreen(trip: trip, feature: f.feature))),
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              TripMateIconBubble(f.icon, size: 46),
              const Spacer(),
              Text(f.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(f.subtitle, style: Theme.of(context).textTheme.bodySmall),
            ]),
          );
        },
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: TripMateSurface(
          onTap: () => trip == null ? _createTrip() : Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentVaultScreen(trip: trip))),
          color: TripMateColors.ice,
          child: const Row(children: [TripMateIconBubble(Icons.folder_special_rounded, size: 44, dark: true), SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Travel Vault', style: TextStyle(fontWeight: FontWeight.w900)), Text('IDs • tickets • docs', style: TextStyle(fontSize: 11, color: TripMateColors.muted))]))]),
        )),
        const SizedBox(width: 10),
        Expanded(child: TripMateSurface(
          onTap: () => trip == null ? _createTrip() : Navigator.push(context, MaterialPageRoute(builder: (_) => StoryStudioScreen(trip: trip))),
          gradient: const LinearGradient(colors: [TripMateColors.blue400, TripMateColors.blue600]),
          child: const Row(children: [TripMateIconBubble(Icons.auto_awesome_rounded, size: 44), SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Story Studio', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)), Text('Share your recap', style: TextStyle(fontSize: 11, color: Colors.white70))]))]),
        )),
      ]),
    ]);
  }

  Widget _emptyLibrary() => TripMateSurface(
        onTap: _createTrip,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 22),
          child: Column(children: [const TripMateIconBubble(Icons.explore_rounded, size: 60), const SizedBox(height: 14), Text('Your map is empty — for now.', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 5), Text('Create a trip and TripMate will turn it into a complete travel workspace.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium)]),
        ),
      );

  Widget _tripTile(Trip trip) => TripMateSurface(
        onTap: () => _openTrip(trip),
        padding: const EdgeInsets.all(15),
        child: Row(children: [
          TripMateIconBubble(Icons.near_me_rounded),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(trip.destination, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text('${DateFormat.MMMd().format(trip.startDate)} • ${trip.title}', style: Theme.of(context).textTheme.bodySmall),
          ])),
          IconButton(onPressed: () => service.deleteTrip(trip.id), icon: const Icon(Icons.delete_outline_rounded)),
        ]),
      );

  void _openTrip(Trip trip) => Navigator.push(context, MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)));

  Future<void> _createTrip() async {
    final trip = await Navigator.push<Trip>(context, MaterialPageRoute(builder: (_) => const CreateTripScreen()));
    if (trip != null && mounted) _openTrip(trip);
  }
}

class _Feature {
  const _Feature(this.icon, this.title, this.subtitle, this.feature);
  final IconData icon;
  final String title;
  final String subtitle;
  final TripFeature feature;
}

class _Entrance extends StatelessWidget {
  const _Entrance({required this.child, required this.delay});
  final Widget child;
  final int delay;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 420 + delay),
        curve: Curves.easeOutCubic,
        builder: (_, value, child) => Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 14 * (1 - value)), child: child)),
        child: child,
      );
}

String _compactMoney(double value) {
  if (value >= 100000) return '${(value / 100000).toStringAsFixed(value >= 1000000 ? 0 : 1)}L';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}K';
  return value.toStringAsFixed(0);
}
