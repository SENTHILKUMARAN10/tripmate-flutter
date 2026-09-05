import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trip.dart';
import '../services/trip_service.dart';

class TripDetailScreen extends StatefulWidget {
  const TripDetailScreen({super.key, required this.trip});
  final Trip trip;

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> with SingleTickerProviderStateMixin {
  late final TabController tabs;
  late final TripService service;

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 3, vsync: this);
    service = TripService(Supabase.instance.client);
  }

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    return Scaffold(
      appBar: AppBar(
        title: Text(trip.destination),
        bottom: TabBar(
          controller: tabs,
          tabs: const [
            Tab(text: 'Itinerary'),
            Tab(text: 'Budget'),
            Tab(text: 'Checklist'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(trip.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text('${DateFormat.yMMMd().format(trip.startDate)} - ${DateFormat.yMMMd().format(trip.endDate)}'),
                ]),
              ),
              Text('₹${trip.budget.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            ]),
          ),
          Expanded(
            child: TabBarView(
              controller: tabs,
              children: [
                _ItineraryTab(service: service, tripId: trip.id),
                _BudgetTab(service: service, tripId: trip.id, budget: trip.budget),
                _ChecklistTab(service: service, tripId: trip.id),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _ItineraryTab extends StatelessWidget {
  const _ItineraryTab({required this.service, required this.tripId});
  final TripService service;
  final String tripId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: service.watchItinerary(tripId),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        return Scaffold(
          body: items.isEmpty
              ? const Center(child: Text('No plans yet. Add your first activity.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final x = items[i];
                    final dt = DateTime.parse(x['starts_at'] as String).toLocal();
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text(DateFormat.Hm().format(dt))),
                        title: Text(x['title'] ?? ''),
                        subtitle: Text([x['place'], DateFormat.yMMMd().format(dt)].where((e) => e != null && '$e'.isNotEmpty).join(' • ')),
                      ),
                    );
                  }),
          floatingActionButton: FloatingActionButton.small(
            onPressed: () => _addItineraryDialog(context, service, tripId),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

Future<void> _addItineraryDialog(BuildContext context, TripService service, String tripId) async {
  final title = TextEditingController();
  final place = TextEditingController();
  DateTime date = DateTime.now().add(const Duration(hours: 1));
  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Add activity'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, decoration: const InputDecoration(labelText: 'Activity')),
        const SizedBox(height: 10),
        TextField(controller: place, decoration: const InputDecoration(labelText: 'Place')),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () async {
            final d = await showDatePicker(
              context: ctx,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 3650)),
              initialDate: date,
            );
            if (d != null) date = DateTime(d.year, d.month, d.day, date.hour, date.minute);
          },
          icon: const Icon(Icons.calendar_month),
          label: const Text('Choose date'),
        )
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            if (title.text.trim().isEmpty) return;
            await service.addItinerary(
              tripId: tripId,
              title: title.text.trim(),
              startsAt: date,
              place: place.text.trim().isEmpty ? null : place.text.trim(),
            );
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('Add'),
        )
      ],
    ),
  );
}

class _BudgetTab extends StatelessWidget {
  const _BudgetTab({required this.service, required this.tripId, required this.budget});
  final TripService service;
  final String tripId;
  final double budget;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: service.watchExpenses(tripId),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        final spent = items.fold<double>(0, (sum, x) => sum + ((x['amount'] as num?)?.toDouble() ?? 0));
        final remaining = budget - spent;
        return Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(children: [
                Expanded(child: _MoneyCard(label: 'Spent', value: spent)),
                const SizedBox(width: 10),
                Expanded(child: _MoneyCard(label: 'Remaining', value: remaining)),
              ]),
              const SizedBox(height: 16),
              ...items.map((x) => Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.receipt_long_rounded)),
                      title: Text(x['title'] ?? ''),
                      subtitle: Text(x['category'] ?? 'Other'),
                      trailing: Text('₹${((x['amount'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ))
            ],
          ),
          floatingActionButton: FloatingActionButton.small(
            onPressed: () => _addExpenseDialog(context, service, tripId),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

class _MoneyCard extends StatelessWidget {
  const _MoneyCard({required this.label, required this.value});
  final String label;
  final double value;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label),
            const SizedBox(height: 8),
            Text('₹${value.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          ]),
        ),
      );
}

Future<void> _addExpenseDialog(BuildContext context, TripService service, String tripId) async {
  final title = TextEditingController();
  final amount = TextEditingController();
  String category = 'Food';
  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        title: const Text('Add expense'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: title, decoration: const InputDecoration(labelText: 'Expense')),
          const SizedBox(height: 10),
          TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ ')),
          const SizedBox(height: 10),
          DropdownButtonFormField(
            value: category,
            items: const ['Food','Stay','Transport','Shopping','Tickets','Other']
                .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setLocal(() => category = v ?? 'Other'),
            decoration: const InputDecoration(labelText: 'Category'),
          )
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final value = double.tryParse(amount.text);
              if (title.text.trim().isEmpty || value == null) return;
              await service.addExpense(tripId: tripId, category: category, title: title.text.trim(), amount: value);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          )
        ],
      ),
    ),
  );
}

class _ChecklistTab extends StatelessWidget {
  const _ChecklistTab({required this.service, required this.tripId});
  final TripService service;
  final String tripId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: service.watchChecklist(tripId),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        return Scaffold(
          body: items.isEmpty
              ? const Center(child: Text('Checklist is empty. Add packing or travel tasks.'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: items.map((x) {
                    final done = x['is_done'] == true;
                    return Card(
                      child: CheckboxListTile(
                        value: done,
                        onChanged: (v) => service.setChecklistState(x['id'] as String, v ?? false),
                        title: Text(
                          x['title'] ?? '',
                          style: TextStyle(decoration: done ? TextDecoration.lineThrough : null),
                        ),
                      ),
                    );
                  }).toList(),
                ),
          floatingActionButton: FloatingActionButton.small(
            onPressed: () => _addChecklistDialog(context, service, tripId),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

Future<void> _addChecklistDialog(BuildContext context, TripService service, String tripId) async {
  final title = TextEditingController();
  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Add checklist item'),
      content: TextField(controller: title, autofocus: true, decoration: const InputDecoration(labelText: 'Item')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            if (title.text.trim().isEmpty) return;
            await service.addChecklistItem(tripId, title.text.trim());
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('Add'),
        )
      ],
    ),
  );
}
