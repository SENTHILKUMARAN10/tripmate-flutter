import 'package:flutter/material.dart';
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
    if (title.text.trim().isEmpty ||
        destination.text.trim().isEmpty ||
        start == null ||
        end == null) return;

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
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not create trip: $e')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create trip')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(controller: title, decoration: const InputDecoration(labelText: 'Trip name')),
          const SizedBox(height: 12),
          TextField(controller: destination, decoration: const InputDecoration(labelText: 'Destination')),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => pickDate(true),
                icon: const Icon(Icons.calendar_month),
                label: Text(start == null ? 'Start date' : '${start!.day}/${start!.month}/${start!.year}'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => pickDate(false),
                icon: const Icon(Icons.event),
                label: Text(end == null ? 'End date' : '${end!.day}/${end!.month}/${end!.year}'),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: budget,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Budget', prefixText: '₹ '),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: notes,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Notes'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: saving ? null : save,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Text(saving ? 'Creating...' : 'Create trip'),
            ),
          )
        ],
      ),
    );
  }
}
