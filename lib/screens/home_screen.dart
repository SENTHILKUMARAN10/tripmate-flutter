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
      appBar: AppBar(
        title: Text('Hi, $firstName 👋'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => Supabase.instance.client.auth.signOut(),
            icon: const Icon(Icons.logout_rounded),
          )
        ],
      ),
      body: StreamBuilder<List<Trip>>(
        stream: service.watchTrips(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Could not load trips\n${snapshot.error}', textAlign: TextAlign.center));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final trips = snapshot.data!;
          if (trips.isEmpty) {
            return _EmptyState(onCreate: _createTrip);
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 100),
            children: [
              _HeroCard(trip: trips.first),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Your trips', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  Text('${trips.length} total', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: 12),
              ...trips.map((trip) => _TripTile(
                    trip: trip,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)),
                    ),
                    onDelete: () => service.deleteTrip(trip.id),
                  )),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTrip,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New trip'),
      ),
    );
  }

  Future<void> _createTrip() async {
    final trip = await Navigator.push<Trip>(
      context,
      MaterialPageRoute(builder: (_) => const CreateTripScreen()),
    );
    if (trip != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)),
      );
    }
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final days = trip.endDate.difference(trip.startDate).inDays + 1;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF4A63E7), Color(0xFF7B59D1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('UPCOMING TRIP', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, letterSpacing: 1.3)),
        const SizedBox(height: 22),
        Text(trip.destination, style: const TextStyle(color: Colors.white, fontSize: 29, fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        Text(trip.title, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 22),
        Row(children: [
          const Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Text('${DateFormat.MMMd().format(trip.startDate)} - ${DateFormat.MMMd().format(trip.endDate)}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('$days days', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ])
      ]),
    );
  }
}

class _TripTile extends StatelessWidget {
  const _TripTile({required this.trip, required this.onTap, required this.onDelete});
  final Trip trip;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          radius: 24,
          child: Text(trip.destination.isEmpty ? '?' : trip.destination.characters.first.toUpperCase()),
        ),
        title: Text(trip.destination, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text('${DateFormat.MMMd().format(trip.startDate)} • ${trip.title}'),
        trailing: PopupMenuButton(
          onSelected: (value) {
            if (value == 'delete') onDelete();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'delete', child: Text('Delete trip')),
          ],
        ),
        onTap: onTap,
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
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.luggage_rounded, size: 72),
          const SizedBox(height: 16),
          Text('Your next adventure starts here',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('Create a trip, build your itinerary, track expenses and keep every travel detail in one place.',
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton.icon(onPressed: onCreate, icon: const Icon(Icons.add), label: const Text('Create first trip')),
        ]),
      ),
    );
  }
}
