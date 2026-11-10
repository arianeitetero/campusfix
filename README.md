# CampusFix

CampusFix gives ALU students one place to report problems around campus and keep
up with what happens next. From a broken tap to a safety concern, students can
share the details, add a photo, and see updates as staff work through each
report.

The app is built with Flutter. Firebase handles sign-in and report data, while
Supabase stores report photos.

## Features

### For students

- Sign up with a verified ALU email (`@alustudent.com` or
  `@alueducation.com`).
- Report an issue with its category, location, and a description. Add a photo
  from your camera or gallery if it helps explain the problem.
- Choose to report anonymously. Other students won't see your name.
- Browse and search reports, filter by category or status, and sort to find
  what matters to you.
- See a report that affects you too? Add your support to it instead of creating
  a duplicate.
- Follow a report's progress and read staff updates. You can edit or withdraw
  your report while it is still *Submitted*.

### For staff

- Use the dashboard to see report totals, issues by category, and a queue of
  reports waiting for attention.
- Update a report as it moves from *Submitted* to *In review*, *In progress*,
  and *Resolved*, or mark it *Rejected*. Add a note when resolving or rejecting
  so the reporter knows what happened.

## Setup

To run CampusFix, you'll need Flutter 3.38 or newer, a Firebase project, and a
Supabase project. The app is currently configured for the Supabase project
`iilpboyuikotxocgcpnn`.

1. Install the Firebase CLI:
   ```bash
   npm i -g firebase-tools
   ```
2. In your Firebase project, enable:
   - **Authentication** → Email/Password
   - **Cloud Firestore**
3. Connect the app to Firebase. This generates
   `lib/firebase_options.dart` for your project:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --platforms=android,ios
   ```
4. Create a Supabase project and a **private** Storage bucket named `incidents`.
   Set its file size limit to 5 MB and allow `image/jpeg` files. Keep in mind
   that Supabase's free plan has storage and bandwidth limits.
5. Deploy the photo function. It checks users' Firebase sign-in tokens, so
   Firebase remains responsible for accounts and report data:
   ```bash
   npx supabase login
   npx supabase link --project-ref iilpboyuikotxocgcpnn
   npx supabase secrets set FIREBASE_PROJECT_ID=campusfix-fd32d
   npx supabase functions deploy incident-photo
   ```
   Supabase supplies `SUPABASE_SERVICE_ROLE_KEY` to the function. Keep this
   server-side key private; never add it to the Flutter app.
6. Publish the Firestore rules:
   ```bash
   firebase login
   firebase use campusfix-fd32d
   firebase deploy --only firestore:rules
   ```
7. Get the anon/publishable key from **Supabase → Project Settings → API**.
   In PowerShell, paste the key when prompted, then start the app:
   ```powershell
   $supabaseUrl = "https://iilpboyuikotxocgcpnn.supabase.co"
   $supabaseKey = Read-Host "Paste the Supabase anon/publishable key"
   flutter pub get
   flutter run --dart-define="SUPABASE_URL=$supabaseUrl" --dart-define="SUPABASE_ANON_KEY=$supabaseKey"
   ```
   The anon key is designed to be used by the app. The bucket remains private:
   photo access goes through the deployed function. Photo uploads need these
   settings, and the app will show an error rather than quietly switching to
   Firebase Storage.

### Creating a staff account

Staff access must be granted by a project administrator. First, register
through the app. Then, in **Firebase Console → Firestore → `users/{uid}`**,
change `role` from `student` to `staff`. The Dashboard tab will appear once the
app receives the profile update.

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

The app keeps the screens, state, and data access separate. Sign-in and report
data use Firebase; photo uploads and time-limited photo links go through the
Supabase Edge Function to the private bucket.

- `AuthProvider` follows sign-in and profile changes, and sends users to the
  right screen for their account state.
- `IncidentProvider` listens for report updates while a user is signed in. That
  keeps report lists, details, and the staff dashboard in sync.
- `IncidentFilter` handles report search, filtering, and sorting, with unit
  tests covering its behavior.

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

Photos live in the private Supabase `incidents` bucket at
`{uid}/{incidentId}_{timestamp}.jpg`. Firebase Authentication and Firestore
continue to handle sign-in and report data.

## Access control

Access is checked on the server, not just in the app's screens. Firestore rules
protect report data, and the `incident-photo` Supabase Edge Function protects
photos.

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

## Running the tests

```bash
flutter test
```

The tests cover ALU email and report validation, report search and filtering,
status transitions, and shared UI widgets.

## Known limitations

- Anonymous reports still contain a `reporterId` so the security rules can
  protect them. The app doesn't show this ID, but someone with direct access to
  the database could see it. Moving reporter identities to a staff-only
  collection would provide stronger privacy.
- Reports are currently loaded and filtered on the device. That's suitable for
  a campus-sized dataset, but a much larger one would need server-side
  filtering and pagination.
- CampusFix doesn't send push notifications yet, so students need to open the
  app to check for updates.
