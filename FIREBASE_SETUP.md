# Firebase setup (accounts + status)

This app uses **Firebase Auth** (email/password) and **Cloud Firestore** for account profiles and presence status. The UI reads from a local SwiftData cache and syncs through `AppSession`.

## 1. Create a Firebase project

1. Open [Firebase Console](https://console.firebase.google.com)
2. Create a project (e.g. `findfriends`)
3. Add an **iOS app** with bundle ID: `gudzak6.findfriends`
4. Download `GoogleService-Info.plist`
5. Put it in the Xcode target folder:

```
findfriends/GoogleService-Info.plist
```

In Xcode: File → Add Files… → select the plist → check **findfriends** target.

## 2. Enable Auth

Firebase Console → **Authentication** → **Sign-in method** → enable **Email/Password**.

## 3. Create Firestore

Firebase Console → **Firestore Database** → create database (start in **production** mode).

Deploy rules from this repo:

```bash
# optional: firebase-tools
npm i -g firebase-tools
firebase login
firebase init firestore   # point rules to firebase/firestore.rules
firebase deploy --only firestore:rules
```

Or paste `firebase/firestore.rules` into the Rules tab manually.

## 4. Run the app

1. Open `findfriends.xcodeproj`
2. Let Swift packages resolve (FirebaseAuth, FirebaseFirestore)
3. Build & run on a device/simulator
4. Create an account → set a status with an expiration → quit/relaunch → status should reload from Firestore (and show from SwiftData cache immediately)

## Data model

```
users/{uid}
  email, displayName, phoneNumber, initials, avatarColorHex
  isSharingLocation
  statusText, statusEmoji, statusKind   // manual | idle | away
  statusUpdatedAt, statusExpiresAt
  latitude, longitude, locationUpdatedAt
  createdAt, updatedAt

users/{uid}/savedContacts/{friendUid}
  phoneNumber, updatedAt

friendships/{uidA_uidB}   // sorted ids
  memberIds: [uidA, uidB]
  createdAt, createdBy

invites/{CODE}
  fromUserId, fromDisplayName
  createdAt, expiresAt
  status: pending | accepted
  acceptedBy
```

After pulling friendship rules, **re-publish** `firebase/firestore.rules` in the Firestore Rules tab.

## Performance notes (already in code)

- Firestore **persistent cache** enabled (offline-first reads)
- Status saves are **field-level patches** (not full document rewrites)
- Status writes are **debounced** (250ms) after optimistic local update
- Live listener on the signed-in user doc only (no polling)
- Expiration cleared **client-side on read** (no Cloud Function required for MVP)
