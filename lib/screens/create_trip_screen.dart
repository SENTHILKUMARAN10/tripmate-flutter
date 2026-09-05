import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/trip_service.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final title = TextEditingController();
  final destination = TextEditingController();
  final budget = TextEditingController();
  final notes = TextEditingController();
  DateTime? start;
  DateTime? end;
  bool saving = false;

  Future<void> pickDate(bool isStart) async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: isStart ? (start ?? DateTime.now()) : (end ?? start ?? DateTime.now()),
    );
    if (selected != null) {
      setState(() {
        if (isStart) {
          start = selected;
          if (end != null && end!.isBefore(selected)) end = selected;
        } else {
          end = selected;
        }
      });
    }
  }

  Future<void> save() async {
    FocusScope.of(context).unfocus();
    if (title.text.trim().isEmpty || destination.text.trim().isEmpty || start == null || end == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add a trip name, destination and travel dates.')));
      return;
    }

    setState(() => saving = true);
    try {
      final service = TripService(Supabase.instance.client);
      final trip = await service.createTrip(
        title: title.text.trim(),
        destination: destination.text.trim(),
        startDate: start!,
        endDate: end!,
        budget: double.tryParse(budget.text) ?? 0,
        notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
      );
      if (mounted) Navigator.pop(context, trip);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not create trip: $e')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    title.dispose();
    destination.dispose();
    budget.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tripDays = start != null && end != null ? end!.difference(start!).inDays + 1 : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Plan a new trip')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF244B45), Color(0xFF5D8179)]),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.explore_rounded, color: Color(0xFFFFC8A6), size: 34),
                SizedBox(height: 16),
                Text('Turn an idea into a journey.', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: -.5)),
                SizedBox(height: 7),
                Text('Start with the basics. You can build the itinerary, bookings, packing list, budget and memories inside the trip later.', style: TextStyle(color: Colors.white70, height: 1.45)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('Trip essentials', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: title,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Trip name', hintText: 'Weekend escape', prefixIcon: Icon(Icons.auto_awesome_rounded)),
          ),
          const SizedBox(height: 11),
          TextField(
            controller: destination,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Destination', hintText: 'Ooty, Goa, Bali...', prefixIcon: Icon(Icons.place_rounded)),
          ),
          const SizedBox(height: 18),
          Text('Travel dates', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _DateCard(label: 'Start', value: start, icon: Icons.flight_takeoff_rounded, onTap: () => pickDate(true))),
              const SizedBox(width: 10),
              Expanded(child: _DateCard(label: 'End', value: end, icon: Icons.flight_land_rounded, onTap: () => pickDate(false))),
            ],
          ),
          if (tripDays != null) ...[
            const SizedBox(height: 8),
            Text('$tripDays-day journey', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800)),
          ],
          const SizedBox(height: 20),
          Text('Money & notes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          TextField(
            controller: budget,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Estimated budget', prefixText: '₹ ', prefixIcon: Icon(Icons.account_balance_wallet_rounded)),
          ),
          const SizedBox(height: 11),
          TextField(
            controller: notes,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Trip note (optional)', hintText: 'Why are you taking this trip? Any important plan?', prefixIcon: Icon(Icons.notes_rounded)),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: saving ? null : save,
            icon: saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.arrow_forward_rounded),
            label: Text(saving ? 'Creating trip...' : 'Create trip space'),
          ),
        ],
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  const _DateCard({required this.label, required this.value, required this.icon, required this.onTap});
  final String label;
  final DateTime? value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 12),
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 3),
                Text(value == null ? 'Choose date' : DateFormat.MMMd().format(value!), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              ],
            ),
          ),
        ),
      );
}
