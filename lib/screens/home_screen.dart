import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme.dart';
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
  int refreshKey = 0;

  @override
  void initState() {
    super.initState();
    service = TripService(Supabase.instance.client);
  }

  Future<void> _refresh() async {
    setState(() => refreshKey++);
    await Future<void>.delayed(const Duration(milliseconds: 450));
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final firstName = (user?.userMetadata?['full_name'] as String?)?.split(' ').first ?? 'Traveler';

    return Scaffold(
      body: SafeArea(
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
              color: AppTheme.violet,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(child: _TopBar(firstName: firstName)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
                      child: _Entrance(
                        delay: 0,
                        child: activeTrip == null
                            ? _StartJourneyCard(onCreate: _createTrip)
                            : _HeroCard(trip: activeTrip, onTap: () => _openTrip(activeTrip)),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                      child: _Entrance(delay: 80, child: _PulseStrip(trips: trips)),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 28, 18, 12),
                      child: _Entrance(delay: 130, child: const _SectionTitle(title: 'Your travel OS', subtitle: 'Everything important, one tap away')),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _Entrance(
                        delay: 180,
                        child: _FeatureGrid(
                          activeTrip: activeTrip,
                          onCreateTrip: _createTrip,
                          onTripHub: activeTrip == null ? null : () => _openTrip(activeTrip),
                          onVault: activeTrip == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentVaultScreen(trip: activeTrip))),
                          onStory: activeTrip == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => StoryStudioScreen(trip: activeTrip))),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 30, 18, 12),
                      child: _Entrance(delay: 220, child: _SectionTitle(title: 'Journey library', subtitle: trips.isEmpty ? 'Your future trips will live here' : '${trips.length} saved ${trips.length == 1 ? 'journey' : 'journeys'}')),
                    ),
                  ),
                  if (trips.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                        child: _Entrance(delay: 260, child: _EmptyLibrary(onCreate: _createTrip)),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      sliver: SliverList.builder(
                        itemCount: trips.length,
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _Entrance(
                            delay: 240 + (i * 50).clamp(0, 300),
                            child: _TripCard(trip: trips[i], onTap: () => _openTrip(trips[i]), onDelete: () => service.deleteTrip(trips[i].id)),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppTheme.violet, AppTheme.cyan]),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [BoxShadow(color: Color(0x336C5CE7), blurRadius: 20, offset: Offset(0, 10))],
        ),
        child: FloatingActionButton.extended(
          heroTag: 'new-trip',
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: _createTrip,
          icon: const Icon(Icons.add_rounded),
          label: const Text('New trip', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }

  void _openTrip(Trip trip) => Navigator.push(context, MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)));

  Future<void> _createTrip() async {
    final trip = await Navigator.push<Trip>(context, MaterialPageRoute(builder: (_) => const CreateTripScreen()));
    if (trip != null && mounted) _openTrip(trip);
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
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, 18 * (1 - value)), child: child),
        ),
        child: child,
      );
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.firstName});
  final String firstName;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 12, 18),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.violet, AppTheme.cyan]),
                borderRadius: BorderRadius.circular(17),
                boxShadow: const [BoxShadow(color: Color(0x336C5CE7), blurRadius: 16, offset: Offset(0, 8))],
              ),
              child: const Icon(Icons.travel_explore_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TRIPMATE', style: TextStyle(color: AppTheme.violet, fontWeight: FontWeight.w900, letterSpacing: 1.8, fontSize: 10)),
                  const SizedBox(height: 2),
                  Text('Hey, $firstName 👋', style: Theme.of(context).textTheme.headlineSmall),
                  Text('Your world is ready to move.', style: Theme.of(context).textTheme.bodySmall),
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
    final status = until > 0 ? '$until days to go' : until == 0 ? 'Starts today' : now.isBefore(trip.endDate.add(const Duration(days: 1))) ? 'Live now' : 'Memory unlocked';

    return InkWell(
      borderRadius: BorderRadius.circular(34),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          gradient: const LinearGradient(
            colors: [Color(0xFF11162A), Color(0xFF3A2F78), Color(0xFF166D78)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [BoxShadow(color: Color(0x3D211D55), blurRadius: 34, offset: Offset(0, 18))],
        ),
        child: Stack(
          children: [
            Positioned(right: -30, top: -40, child: Container(width: 160, height: 160, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .05)))),
            Positioned(right: 35, bottom: -65, child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.cyan.withValues(alpha: .10)))),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .09), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withValues(alpha: .09))),
                      child: const Row(
                        children: [
                          Icon(Icons.bolt_rounded, color: Color(0xFFB7F5F8), size: 15),
                          SizedBox(width: 5),
                          Text('ACTIVE JOURNEY', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .09), shape: BoxShape.circle), child: const Icon(Icons.arrow_outward_rounded, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 30),
                Text(trip.destination, style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: -1.5)),
                const SizedBox(height: 4),
                Text(trip.title, style: const TextStyle(color: Colors.white60, fontWeight: FontWeight.w700)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _GlassStat(icon: Icons.calendar_month_rounded, top: '${DateFormat.MMMd().format(trip.startDate)} – ${DateFormat.MMMd().format(trip.endDate)}', bottom: '$days days')),
                    const SizedBox(width: 10),
                    Expanded(child: _GlassStat(icon: Icons.near_me_rounded, top: status, bottom: 'Open command centre')),
                  ],
                ),
              ],
            ),
          ],
        ),
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          gradient: const LinearGradient(colors: [Color(0xFF11162A), Color(0xFF3A2F78), Color(0xFF166D78)]),
          boxShadow: const [BoxShadow(color: Color(0x3D211D55), blurRadius: 34, offset: Offset(0, 18))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 54, height: 54, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .09), borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.flight_takeoff_rounded, color: Color(0xFFB7F5F8), size: 29)),
            const SizedBox(height: 30),
            const Text('Where are we going?', style: TextStyle(color: Colors.white, fontSize: 33, fontWeight: FontWeight.w900, letterSpacing: -1.1)),
            const SizedBox(height: 8),
            const Text('Build the trip, invite your crew, secure documents, track money and save every memory.', style: TextStyle(color: Colors.white60, height: 1.45)),
            const SizedBox(height: 20),
            FilledButton.icon(onPressed: onCreate, icon: const Icon(Icons.add_rounded), label: const Text('Create first journey')),
          ],
        ),
      );
}

class _GlassStat extends StatelessWidget {
  const _GlassStat({required this.icon, required this.top, required this.bottom});
  final IconData icon;
  final String top;
  final String bottom;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .08), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withValues(alpha: .08))),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFB7F5F8), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(top, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(bottom, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _PulseStrip extends StatelessWidget {
  const _PulseStrip({required this.trips});
  final List<Trip> trips;

  @override
  Widget build(BuildContext context) {
    final destinations = trips.map((e) => e.destination.trim().toLowerCase()).where((e) => e.isNotEmpty).toSet().length;
    final totalBudget = trips.fold<double>(0, (sum, t) => sum + t.budget);
    return Row(
      children: [
        Expanded(child: _PulseCard(icon: Icons.luggage_rounded, value: '${trips.length}', label: 'Trips', tint: const Color(0xFFE9E5FF), iconColor: AppTheme.violet)),
        const SizedBox(width: 10),
        Expanded(child: _PulseCard(icon: Icons.public_rounded, value: '$destinations', label: 'Places', tint: const Color(0xFFDDFBFD), iconColor: const Color(0xFF0D8E98))),
        const SizedBox(width: 10),
        Expanded(child: _PulseCard(icon: Icons.wallet_rounded, value: '₹${_compactMoney(totalBudget)}', label: 'Planned', tint: const Color(0xFFFFEAE3), iconColor: const Color(0xFFCF6848))),
      ],
    );
  }
}

class _PulseCard extends StatelessWidget {
  const _PulseCard({required this.icon, required this.value, required this.label, required this.tint, required this.iconColor});
  final IconData icon;
  final String value;
  final String label;
  final Color tint;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFE7EAF2))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 34, height: 34, decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: iconColor, size: 18)),
            const SizedBox(height: 12),
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -.4)),
            const SizedBox(height: 1),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 3),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ],
      );
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.activeTrip, required this.onCreateTrip, this.onTripHub, this.onVault, this.onStory});
  final Trip? activeTrip;
  final VoidCallback onCreateTrip;
  final VoidCallback? onTripHub;
  final VoidCallback? onVault;
  final VoidCallback? onStory;

  @override
  Widget build(BuildContext context) {
    final items = <_FeatureData>[
      _FeatureData(Icons.route_rounded, 'Itinerary', 'Build each day', onTripHub, const [Color(0xFFE9E5FF), Color(0xFFF4F2FF)], AppTheme.violet),
      _FeatureData(Icons.account_balance_wallet_rounded, 'Budget', 'Track every ₹', onTripHub, const [Color(0xFFDDFBFD), Color(0xFFF0FEFF)], Color(0xFF0D8E98)),
      _FeatureData(Icons.checklist_rounded, 'Packing', 'Smart checklist', onTripHub, const [Color(0xFFFFEAE3), Color(0xFFFFF5F1)], Color(0xFFCF6848)),
      _FeatureData(Icons.photo_library_rounded, 'Memories', 'Save your moments', onTripHub, const [Color(0xFFFCE6F1), Color(0xFFFFF3F8)], Color(0xFFB64F81)),
      _FeatureData(Icons.confirmation_number_rounded, 'Bookings', 'Tickets & stays', onTripHub, const [Color(0xFFE5EEFF), Color(0xFFF3F7FF)], Color(0xFF416CC4)),
      _FeatureData(Icons.folder_special_rounded, 'Travel vault', 'IDs & documents', onVault, const [Color(0xFFFFF0C9), Color(0xFFFFFAEC)], Color(0xFFAE7B18)),
      _FeatureData(Icons.emergency_rounded, 'Emergency', 'Help in one tap', onTripHub, const [Color(0xFFFFE3E5), Color(0xFFFFF4F5)], Color(0xFFC94B55)),
      _FeatureData(Icons.auto_awesome_rounded, 'Story studio', 'Share the ending', onStory, const [Color(0xFFEAE8FF), Color(0xFFF7F6FF)], Color(0xFF715EDB)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.08, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        return _FeatureTile(item: item, onFallback: onCreateTrip);
      },
    );
  }
}

class _FeatureTile extends StatefulWidget {
  const _FeatureTile({required this.item, required this.onFallback});
  final _FeatureData item;
  final VoidCallback onFallback;

  @override
  State<_FeatureTile> createState() => _FeatureTileState();
}

class _FeatureTileState extends State<_FeatureTile> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return GestureDetector(
      onTapDown: (_) => setState(() => pressed = true),
      onTapCancel: () => setState(() => pressed = false),
      onTapUp: (_) {
        setState(() => pressed = false);
        (item.onTap ?? widget.onFallback)();
      },
      child: AnimatedScale(
        scale: pressed ? .97 : 1,
        duration: const Duration(milliseconds: 130),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: item.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white),
            boxShadow: const [BoxShadow(color: Color(0x0F1B2035), blurRadius: 18, offset: Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .88), borderRadius: BorderRadius.circular(15)), child: Icon(item.icon, color: item.iconColor, size: 22)),
                  const Spacer(),
                  const Icon(Icons.arrow_outward_rounded, size: 19, color: Color(0xFF8C93A4)),
                ],
              ),
              const Spacer(),
              Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -.2)),
              const SizedBox(height: 3),
              Text(item.subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureData {
  const _FeatureData(this.icon, this.title, this.subtitle, this.onTap, this.gradient, this.iconColor);
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final List<Color> gradient;
  final Color iconColor;
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip, required this.onTap, required this.onDelete});
  final Trip trip;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final days = trip.endDate.difference(trip.startDate).inDays + 1;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFE9E5FF), Color(0xFFDDFBFD)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.near_me_rounded, color: AppTheme.violet, size: 27),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.destination, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                    const SizedBox(height: 3),
                    Text('${DateFormat.MMMd().format(trip.startDate)} • $days days', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 5),
                    Text(trip.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
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

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0xFFE7EAF2))),
        child: Column(
          children: [
            Container(width: 58, height: 58, decoration: BoxDecoration(color: const Color(0xFFE9E5FF), borderRadius: BorderRadius.circular(19)), child: const Icon(Icons.map_outlined, color: AppTheme.violet, size: 29)),
            const SizedBox(height: 15),
            Text('No journeys yet', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 5),
            Text('Create a trip and TripMate will build your travel space around it.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: onCreate, icon: const Icon(Icons.add_rounded), label: const Text('Create journey')),
          ],
        ),
      );
}

String _compactMoney(double value) {
  if (value >= 100000) return '${(value / 100000).toStringAsFixed(value >= 1000000 ? 0 : 1)}L';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}K';
  return value.toStringAsFixed(0);
}
