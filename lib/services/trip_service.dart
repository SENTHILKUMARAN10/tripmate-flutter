import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trip.dart';

class TripService {
  TripService(this.client);
  final SupabaseClient client;

  String get userId => client.auth.currentUser!.id;

  Stream<List<Trip>> watchTrips() {
    return client
        .from('trips')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('start_date')
        .map((rows) => rows.map(Trip.fromMap).toList());
  }

  Future<Trip> createTrip({
    required String title,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    required double budget,
    String? notes,
  }) async {
    final row = await client
        .from('trips')
        .insert({
          'user_id': userId,
          'title': title,
          'destination': destination,
          'start_date': startDate.toIso8601String().split('T').first,
          'end_date': endDate.toIso8601String().split('T').first,
          'budget': budget,
          'notes': notes,
        })
        .select()
        .single();
    return Trip.fromMap(row);
  }

  Future<void> deleteTrip(String id) async {
    await client.from('trips').delete().eq('id', id).eq('user_id', userId);
  }

  Stream<List<Map<String, dynamic>>> watchItinerary(String tripId) {
    return client
        .from('itinerary_items')
        .stream(primaryKey: ['id'])
        .eq('trip_id', tripId)
        .order('starts_at');
  }

  Future<void> addItinerary({
    required String tripId,
    required String title,
    required DateTime startsAt,
    String? place,
    String? notes,
  }) async {
    await client.from('itinerary_items').insert({
      'trip_id': tripId,
      'user_id': userId,
      'title': title,
      'starts_at': startsAt.toIso8601String(),
      'place': place,
      'notes': notes,
    });
  }

  Stream<List<Map<String, dynamic>>> watchExpenses(String tripId) {
    return client
        .from('expenses')
        .stream(primaryKey: ['id'])
        .eq('trip_id', tripId)
        .order('spent_at', ascending: false);
  }

  Future<void> addExpense({
    required String tripId,
    required String category,
    required String title,
    required double amount,
  }) async {
    await client.from('expenses').insert({
      'trip_id': tripId,
      'user_id': userId,
      'category': category,
      'title': title,
      'amount': amount,
      'spent_at': DateTime.now().toIso8601String(),
    });
  }

  Stream<List<Map<String, dynamic>>> watchChecklist(String tripId) {
    return client
        .from('checklist_items')
        .stream(primaryKey: ['id'])
        .eq('trip_id', tripId)
        .order('created_at');
  }

  Future<void> addChecklistItem(String tripId, String title) async {
    await client.from('checklist_items').insert({
      'trip_id': tripId,
      'user_id': userId,
      'title': title,
      'is_done': false,
    });
  }

  Future<void> setChecklistState(String id, bool done) async {
    await client
        .from('checklist_items')
        .update({'is_done': done})
        .eq('id', id)
        .eq('user_id', userId);
  }
}
