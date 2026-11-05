# CampusFix

A Flutter mobile app for ALU students to report campus issues (water, electricity, broken facilities, furniture, sanitation, safety, IT) and track them until they are resolved. Campus staff triage reports and update their status.

Built with Flutter, Provider, Firebase Authentication, Cloud Firestore and Firebase Storage.

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
   - **Storage**
3. Connect the app to your project. This replaces the placeholder `lib/firebase_options.dart`:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --platforms=android,ios
   ```
4. Deploy the security rules:
   ```bash
   firebase login
   firebase use <your-project-id>
   firebase deploy --only firestore:rules,storage
   ```
5. Run the app on an emulator or device:
   ```bash
   flutter pub get
   flutter run
   ```

### Creating a staff account

Staff cannot promote themselves. Register normally in the app, then in **Firebase Console → Firestore → `users/{uid}`** change `role` from `student` to `staff`. The Dashboard tab appears immediately because the profile is streamed live.

## Architecture

```
lib/
├── main.dart, app.dart        Firebase init, providers, AuthGate
├── core/                      theme, validators, date formatting
├── models/                    Incident, AppUser, enums, IncidentFilter (pure Dart)
├── services/                  Firebase access: AuthService, UserRepository,
│                              IncidentRepository, StorageService
├── providers/                 AuthProvider, IncidentProvider (ChangeNotifier)
├── screens/                   auth/, home/, reports/, staff/, profile/
└── widgets/                   reusable UI: IncidentCard, StatusChip, FilterBar, …
```

Data flows in one direction: **UI → Provider → Repository → Firebase**, and Firestore streams flow back **Firebase → Repository → Provider → UI**.

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
  photoUrl, photoPath
  confirmedBy: [uid]           students who tapped "affects me too"
  latestNote                    last staff note (shown on cards)
  createdAt, updatedAt

incidents/{incidentId}/updates/{updateId}
  status, note, byId, byName, at
```

Photos are stored at `incidents/{uid}/{incidentId}.jpg` in Firebase Storage.

## Access control

The rules in [`firestore.rules`](firestore.rules) and [`storage.rules`](storage.rules) enforce the roles on the server, not only in the UI:

| Action | Who |
|---|---|
| Read reports and history | Any signed-in user with a **verified ALU email** |
| Create a report | Verified user, as themselves, with status `submitted` and valid field lengths |
| Edit or withdraw a report | The reporter only, and only while it is `submitted` |
| Change status / add history | Users whose profile `role == "staff"` |
| Toggle "affects me too" | Any verified user, adding or removing **only their own uid** |
| Change `role` | Nobody from the app (console only) |
| Upload a photo | The owner of the `{uid}` path; images only, under 5 MB |

## Tests

```bash
flutter test
```

- `test/validators_test.dart`: ALU email domain check, password strength, report field limits
- `test/incident_filter_test.dart`: search, filters, sorting, edit permission, status transitions
- `test/widgets_test.dart`: `StatusChip`, `StatusTracker`, relative time formatting

## Known limitations

- `reporterId` remains in anonymous reports because the security rules need it. The app never shows it, but a technical user could read it from the raw data. A Cloud Function that moves reporter identity into a staff-only collection would close this gap.
- All reports are streamed to the client and filtered there. This works at campus scale, but large datasets would need server-side queries and pagination.
- There are no push notifications for status changes yet (this would need FCM plus a Cloud Function).
