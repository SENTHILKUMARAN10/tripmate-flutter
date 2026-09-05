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

## 1. Create the Flutter platform folders
This source intentionally contains the portable app code. On a computer with Flutter installed:

```bash
flutter create . --platforms=android,ios
flutter pub get
```

If Flutter adds/replaces `lib/main.dart`, restore the `lib/` folder from this project after running `flutter create .`.

## 2. Create a Supabase project
Create a new Supabase project for TripMate.

Open **SQL Editor** and run:

`supabase/schema.sql`

In **Authentication → Providers → Email**, keep Email enabled.

## 3. Run the app
Use the Supabase project URL and Publishable/Anon key:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY
```

## 4. Android release build
```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY
```

For Play Store:
```bash
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY
```

## Current product scope
The app already includes the core real-time data model and primary user workflows. Next production extensions can include maps/place search, trip sharing, push notifications, image storage, offline caching, currency conversion and collaborative trips.
