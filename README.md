# CampusFix

A Flutter mobile app for ALU students to report campus issues (water, electricity, broken facilities, furniture, sanitation, safety, IT) and track them until they are resolved. Campus staff triage reports and update their status.

Built with Flutter, Provider, Firebase Authentication, Cloud Firestore, and Supabase Storage for photos.

## Features

**Students**
- Register and sign in with an ALU email only (`@alustudent.com` / `@alueducation.com`). The email must be verified before the app unlocks.
- Submit a report with a category, title, location (with quick-pick campus spots), description, and an optional photo from the camera or gallery.
- Report anonymously: other students do not see your name.
- Browse all reports with search, category, status and "open only" filters, and three sort orders.
- "This affects me too" adds weight to an existing report instead of creating a duplicate.
- Track progress with a step tracker and a full status history that includes staff notes.
- Edit or withdraw your own report while it is still *Submitted*.

**Staff**
- A dashboard with counts per status, open reports by category, and a triage queue (oldest first).
- Move reports through *Submitted → In review → In progress → Resolved*, or *Rejected*. Resolving or rejecting requires a note for the reporter.

## Setup

1. Install Flutter (3.38 or newer) and the Firebase CLI (`npm i -g firebase-tools`).
2. Create a Firebase project, then enable:
   - **Authentication** → Email/Password
   - **Cloud Firestore**
3. Connect the app to your project. This replaces the placeholder `lib/firebase_options.dart`:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --platforms=android,ios
   ```
4. Create a Supabase project (the free plan has storage and bandwidth quotas)
   and a **private** Storage bucket named `incidents`.
   Set the bucket's file size limit to 5 MB and allowed MIME type to `image/jpeg`.
5. Deploy the photo function. It verifies the app's existing Firebase ID tokens;
   Firebase Authentication and Firestore remain the app's identity and database:
   ```bash
   npx supabase login
   npx supabase link --project-ref <your-supabase-project-ref>
   npx supabase secrets set FIREBASE_PROJECT_ID=campusfix-fd32d
   npx supabase functions deploy incident-photo
   ```
   The function uses Supabase's server-side `SUPABASE_SERVICE_ROLE_KEY`. Never
   put that key in the Flutter app.
6. Deploy the Firestore rules (they allow the new photo storage metadata):
   ```bash
   firebase login
   firebase use campusfix-fd32d
   firebase deploy --only firestore:rules
   ```
7. Copy your Supabase project URL and anon/publishable key from the project's
   API settings, then run the app with them:
   ```bash
   flutter pub get
   flutter run --dart-define="SUPABASE_URL=https://<project-ref>.supabase.co" --dart-define="SUPABASE_ANON_KEY=<anon-key>"
   ```
   The anon key is intended for app use; the bucket stays private and photo
   access is mediated by the deployed function. New photo uploads require these
   settings; the app does not silently fall back to Firebase Storage.

### Creating a staff account

Staff cannot promote themselves. Register normally in the app, then in **Firebase Console → Firestore → `users/{uid}`** change `role` from `student` to `staff`. The Dashboard tab appears immediately because the profile is streamed live.

## Architecture

```
lib/
├── main.dart, app.dart        Firebase init, providers, AuthGate
├── core/                      theme, validators, date formatting
├── models/                    Incident, AppUser, enums, IncidentFilter (pure Dart)
├── services/                  Firebase access: AuthService, UserRepository,
│                              IncidentRepository, StorageService (Supabase photos)
├── providers/                 AuthProvider, IncidentProvider (ChangeNotifier)
├── screens/                   auth/, home/, reports/, staff/, profile/
└── widgets/                   reusable UI: IncidentCard, StatusChip, FilterBar, …
```

Data flows in one direction: **UI → Provider → Repository → Firebase** for auth and app data. Photo uploads and signed photo reads go through the Supabase Edge Function to the private Supabase bucket.

- `AuthProvider` listens to `authStateChanges()` and to the user's profile document. It exposes `AuthStatus` (`initializing / signedOut / unverified / signedIn`), and `AuthGate` swaps the root screen to match, so the app needs no manual navigation on sign-in or sign-out.
- `IncidentProvider` is a `ChangeNotifierProxyProvider` that depends on `AuthProvider`. It subscribes to the `incidents` stream when a user signs in and clears everything on sign-out. Screens look reports up **by id** from this single source, so a staff status change appears at once on the list, the detail screen, My reports and the dashboard.
- Filtering and sorting live in `IncidentFilter`, a pure Dart class covered by unit tests.

## Firestore data model

```
users/{uid}
  email, displayName, role: "student" | "staff", createdAt

incidents/{incidentId}
  title, description, location
  category: facilities | water | electricity | furniture | sanitation | safety | internet | other
  status:   submitted | inReview | inProgress | resolved | rejected
  reporterId, reporterName ("" when anonymous), isAnonymous
  photoUrl, photoPath, photoStorage
  confirmedBy: [uid]           students who tapped "affects me too"
  latestNote                    last staff note (shown on cards)
  createdAt, updatedAt

incidents/{incidentId}/updates/{updateId}
  status, note, byId, byName, at
```

Photos are stored in the private Supabase `incidents` bucket under
`{uid}/{incidentId}_{timestamp}.jpg`. Firebase Auth and Firestore are unchanged.

## Access control

The rules in [`firestore.rules`](firestore.rules) and the `incident-photo` Supabase Edge Function enforce access on the server, not only in the UI:

| Action | Who |
|---|---|
| Read reports and history | Any signed-in user with a **verified ALU email** |
| Create a report | Verified user, as themselves, with status `submitted` and valid field lengths |
| Edit or withdraw a report | The reporter only, and only while it is `submitted` |
| Change status / add history | Users whose profile `role == "staff"` |
| Toggle "affects me too" | Any verified user, adding or removing **only their own uid** |
| Change `role` | Nobody from the app (console only) |
| Upload or delete a photo | The verified ALU reporter for the `{uid}` path, through the Supabase Edge Function; JPEG only, under 5 MB |
| View a photo | Any verified ALU user; the Edge Function returns a one-hour signed URL |

## Tests

```bash
flutter test
```

- `test/validators_test.dart`: ALU email domain check, password strength, report field limits
- `test/incident_filter_test.dart`: search, filters, sorting, edit permission, status transitions
- `test/widgets_test.dart`: `StatusChip`, `StatusTracker`, relative time formatting

## Known limitations

- `reporterId` remains in anonymous reports because the security rules need it. The app never shows it, but a user with direct access to the raw data can read it. A Cloud Function that moves reporter identity into a staff-only collection would close this gap.
- All reports are streamed to the client and filtered there. This works at campus scale, but large datasets would need server-side queries and pagination.
- There are no push notifications for status changes yet (this would need FCM plus a Cloud Function).
