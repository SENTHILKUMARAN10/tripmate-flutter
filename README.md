# TripMate — Smart Travel Planner

TripMate is a real-time Flutter travel planning app backed by Supabase.

## Features
- Email signup / login
- Real-time trip list
- Create and delete trips
- Day-by-day itinerary activities
- Budget and expense tracking
- Packing / travel checklist
- Supabase PostgreSQL persistence
- Row Level Security per user
- Realtime database updates

## Automated Android build
GitHub Actions is configured to generate the Android platform files, analyze the Flutter project, build a release APK, and upload it as the `TripMate-Android-APK` artifact.

## Local setup
On a computer with Flutter installed:

```bash
flutter create . --platforms=android,ios --project-name=tripmate --org=com.senthilkumaran.tripmate
flutter pub get
flutter run
```

## Supabase
The app is connected to the TripMate Supabase backend. The database schema is stored in `supabase/schema.sql`, with a production migration under `supabase/migrations/`.

## Android release build
```bash
flutter build apk --release
```

For Play Store:
```bash
flutter build appbundle --release
```

## Current product scope
The app includes the core real-time data model and primary user workflows. Planned production extensions include maps/place search, trip sharing, push notifications, image storage, offline caching, currency conversion and collaborative trips.
