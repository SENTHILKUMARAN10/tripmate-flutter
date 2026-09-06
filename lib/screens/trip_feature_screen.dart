import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/design.dart';
import '../models/trip.dart';
import '../services/trip_service.dart';

class TripFeatureScreen extends StatefulWidget {
  const TripFeatureScreen({super.key, required this.trip, required this.feature});
  final Trip trip;
  final TripFeature feature;

  @override
  State<TripFeatureScreen> createState() => _TripFeatureScreenState();
}

enum TripFeature { itinerary, budget, packing, memories, bookings, emergency }

class _TripFeatureScreenState extends State<TripFeatureScreen> {
  late final TripService service;

  @override
  void initState() {
    super.initState();
    service = TripService(Supabase.instance.client);
  }

  @override
  Widget build(BuildContext context) {
    final meta = _meta(widget.feature);
    return Scaffold(
      body: TripMateWaveBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 36),
              children: [
                Row(children: [
                  IconButton.filledTonal(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)),
                  const Spacer(),
                  TripMateIconBubble(meta.icon, dark: true),
                ]),
                const SizedBox(height: 22),
                TripMatePageHeader(eyebrow: widget.trip.destination, title: meta.title, subtitle: meta.subtitle),
                const SizedBox(height: 22),
                _hero(meta),
                const SizedBox(height: 20),
                _content(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _canAdd(widget.feature)
          ? FloatingActionButton.extended(onPressed: _add, icon: const Icon(Icons.add_rounded), label: Text(meta.action))
          : null,
    );
  }

  Widget _hero(_FeatureMeta meta) => TripMateSurface(
        gradient: TripMateGradient.hero,
        child: Row(children: [
          Container(width: 58, height: 58, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(20)), child: Icon(meta.icon, color: TripMateColors.ice, size: 30)),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.trip.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text(meta.heroLine, style: const TextStyle(color: Colors.white70, height: 1.35, fontWeight: FontWeight.w600)),
          ])),
        ]),
      );

  Widget _content() {
    switch (widget.feature) {
      case TripFeature.itinerary:
        return _streamList(service.watchItinerary(widget.trip.id), Icons.route_rounded, 'Nothing planned yet', (x) => '${x['title'] ?? 'Plan'}', (x) => '${x['place'] ?? ''}');
      case TripFeature.budget:
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: service.watchExpenses(widget.trip.id),
          builder: (_, snap) {
            final items = snap.data ?? [];
            final spent = items.fold<double>(0, (sum, x) => sum + ((x['amount'] as num?)?.toDouble() ?? 0));
            final left = widget.trip.budget - spent;
            return Column(children: [
              TripMateSurface(child: Row(children: [
                Expanded(child: _number('Budget', '₹${widget.trip.budget.toStringAsFixed(0)}')),
                Expanded(child: _number('Spent', '₹${spent.toStringAsFixed(0)}')),
                Expanded(child: _number('Left', '₹${left.toStringAsFixed(0)}')),
              ])),
              const SizedBox(height: 12),
              _items(items, Icons.account_balance_wallet_rounded, 'No expenses yet', (x) => '${x['title'] ?? 'Expense'}', (x) => '₹${((x['amount'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)} • ${x['category'] ?? 'Other'}'),
            ]);
          },
        );
      case TripFeature.packing:
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: service.watchChecklist(widget.trip.id),
          builder: (_, snap) {
            final items = snap.data ?? [];
            if (items.isEmpty) return _empty(Icons.backpack_rounded, 'Your packing list starts here', 'Add essentials, outfits, chargers and anything you do not want to forget.');
            return Column(children: items.map((x) {
              final done = x['is_done'] == true;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TripMateSurface(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  child: Row(children: [
                    Checkbox(value: done, onChanged: (v) => service.setChecklistState('${x['id']}', v ?? false)),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${x['title'] ?? 'Item'}', style: TextStyle(fontWeight: FontWeight.w800, decoration: done ? TextDecoration.lineThrough : null))),
                    IconButton(onPressed: () => service.deleteChecklistItem('${x['id']}'), icon: const Icon(Icons.close_rounded)),
                  ]),
                ),
              );
            }).toList());
          },
        );
      case TripFeature.memories:
        return _streamList(service.watchMemories(widget.trip.id), Icons.photo_library_rounded, 'No memories yet', (x) => '${x['caption'] ?? 'Trip moment'}', (x) => 'Saved to your private trip memory vault');
      case TripFeature.bookings:
        return _streamList(service.watchBookings(widget.trip.id), Icons.confirmation_number_rounded, 'No bookings saved', (x) => '${x['title'] ?? 'Booking'}', (x) => '${x['provider'] ?? x['category'] ?? ''}');
      case TripFeature.emergency:
        return Column(children: const [
          _EmergencyCard(icon: Icons.local_hospital_rounded, title: 'Nearby medical help', text: 'Keep emergency hospital and pharmacy details accessible before you travel.'),
          SizedBox(height: 10),
          _EmergencyCard(icon: Icons.shield_rounded, title: 'Emergency documents', text: 'Keep ID, insurance and essential travel files inside Travel Vault.'),
          SizedBox(height: 10),
          _EmergencyCard(icon: Icons.call_rounded, title: 'India emergency', text: 'Dial 112 for emergency assistance when needed.'),
        ]);
    }
  }

  Widget _streamList(Stream<List<Map<String, dynamic>>> stream, IconData icon, String emptyTitle, String Function(Map<String, dynamic>) title, String Function(Map<String, dynamic>) subtitle) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (_, snap) => _items(snap.data ?? [], icon, emptyTitle, title, subtitle),
    );
  }

  Widget _items(List<Map<String, dynamic>> items, IconData icon, String emptyTitle, String Function(Map<String, dynamic>) title, String Function(Map<String, dynamic>) subtitle) {
    if (items.isEmpty) return _empty(icon, emptyTitle, 'Tap the action button to add your first item.');
    return Column(children: items.map((x) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TripMateSurface(
        padding: const EdgeInsets.all(15),
        child: Row(children: [
          TripMateIconBubble(icon, size: 46),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title(x), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            if (subtitle(x).trim().isNotEmpty) ...[const SizedBox(height: 3), Text(subtitle(x), style: Theme.of(context).textTheme.bodySmall)],
          ])),
        ]),
      ),
    )).toList());
  }

  Widget _empty(IconData icon, String title, String text) => TripMateSurface(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(children: [TripMateIconBubble(icon, size: 58), const SizedBox(height: 14), Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center), const SizedBox(height: 6), Text(text, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center)]),
        ),
      );

  Widget _number(String label, String value) => Column(children: [Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)), const SizedBox(height: 2), Text(label, style: Theme.of(context).textTheme.bodySmall)]);

  bool _canAdd(TripFeature feature) => feature != TripFeature.memories && feature != TripFeature.emergency;

  Future<void> _add() async {
    switch (widget.feature) {
      case TripFeature.itinerary:
        final title = await _textDialog('Add itinerary', 'Plan title');
        if (title != null) await service.addItinerary(tripId: widget.trip.id, title: title, startsAt: DateTime.now());
        break;
      case TripFeature.budget:
        final result = await _twoFieldDialog('Add expense', 'Expense', 'Amount');
        if (result != null) await service.addExpense(tripId: widget.trip.id, category: 'Trip', title: result.$1, amount: double.tryParse(result.$2) ?? 0);
        break;
      case TripFeature.packing:
        final title = await _textDialog('Add packing item', 'What to pack?');
        if (title != null) await service.addChecklistItem(widget.trip.id, title);
        break;
      case TripFeature.bookings:
        final result = await _twoFieldDialog('Add booking', 'Booking title', 'Provider');
        if (result != null) await service.addBooking(tripId: widget.trip.id, title: result.$1, category: 'Travel', provider: result.$2);
        break;
      case TripFeature.memories:
      case TripFeature.emergency:
        break;
    }
  }

  Future<String?> _textDialog(String title, String hint) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(controller: controller, autofocus: true, decoration: InputDecoration(hintText: hint)),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Add'))],
    ));
    controller.dispose();
    return value?.isEmpty == true ? null : value;
  }

  Future<(String, String)?> _twoFieldDialog(String title, String first, String second) async {
    final a = TextEditingController();
    final b = TextEditingController();
    final value = await showDialog<(String, String)>(context: context, builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: a, decoration: InputDecoration(labelText: first)), const SizedBox(height: 10), TextField(controller: b, decoration: InputDecoration(labelText: second))]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, (a.text.trim(), b.text.trim())), child: const Text('Add'))],
    ));
    a.dispose();
    b.dispose();
    return value;
  }
}

class _FeatureMeta {
  const _FeatureMeta(this.title, this.subtitle, this.heroLine, this.action, this.icon);
  final String title;
  final String subtitle;
  final String heroLine;
  final String action;
  final IconData icon;
}

_FeatureMeta _meta(TripFeature feature) => switch (feature) {
  TripFeature.itinerary => const _FeatureMeta('Itinerary', 'Build the flow of your trip, one moment at a time.', 'Your day-by-day route, plans and timing live here.', 'Add plan', Icons.route_rounded),
  TripFeature.budget => const _FeatureMeta('Budget', 'Know what you planned, spent and still have left.', 'A clean money view made for the whole journey.', 'Add expense', Icons.account_balance_wallet_rounded),
  TripFeature.packing => const _FeatureMeta('Packing', 'A smart checklist so essentials never stay home.', 'Tap items as you pack and keep the list trip-specific.', 'Add item', Icons.backpack_rounded),
  TripFeature.memories => const _FeatureMeta('Memories', 'Your private collection of moments from this trip.', 'Photos and captions become the memory layer of your journey.', 'Add moment', Icons.photo_library_rounded),
  TripFeature.bookings => const _FeatureMeta('Bookings', 'Keep transport, stays and confirmation details together.', 'PNR, hotel, bus, train and flight details stay in one place.', 'Add booking', Icons.confirmation_number_rounded),
  TripFeature.emergency => const _FeatureMeta('Emergency', 'Critical travel information without digging through chats.', 'Keep documents, medical information and emergency actions close.', 'Open', Icons.health_and_safety_rounded),
};

class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard({required this.icon, required this.title, required this.text});
  final IconData icon;
  final String title;
  final String text;
  @override
  Widget build(BuildContext context) => TripMateSurface(child: Row(children: [TripMateIconBubble(icon), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(text, style: Theme.of(context).textTheme.bodySmall)]))]));
}
