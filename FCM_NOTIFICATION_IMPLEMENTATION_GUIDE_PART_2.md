# Mix App FCM Notification Implementation Guide - Part 2
## Actual Client-Side Files Added, What They Do, and How Another Engineer Should Continue the Work

---

# Table of Contents

1. Purpose of Part 2
2. What Has Now Been Added
3. Files Added
4. Files Updated
5. How FCM Now Works in the App
6. Startup Sequence
7. Background Notification Handling
8. Foreground Notification Handling
9. Notification Tap Handling
10. Token Storage Strategy
11. User Tokens
12. Admin Tokens
13. Why Navigator Key Was Added
14. Local Notification Service Role
15. FCM Service Role
16. Notification Navigation Service Role
17. What Still Needs Backend Work
18. What This Client Setup Already Solves
19. Recommended Backend Next Steps
20. Suggested Event Triggers
21. Suggested Firestore Token Fields
22. Testing Notes
23. Final Summary

---

# 1. Purpose of Part 2

Part 1 documented the full architecture plan for FCM in Mix.

This Part 2 documents the actual client-side implementation files that have now been introduced into the project.

This is important because another engineer should be able to understand:
- what was actually created
- what each file is doing
- what still remains for backend completion

---

# 2. What Has Now Been Added

The client-side FCM structure now includes:

- Firebase app initialization at startup
- background message registration
- local notification setup
- FCM permission request
- FCM token saving
- token refresh handling
- foreground notification display
- app-open-from-notification navigation
- terminated-app notification navigation support

This is the client-side foundation required before backend sending logic is added.

---

# 3. Files Added

The following new files were added:

## `lib/services/fcm_service.dart`
Main client FCM lifecycle manager

## `lib/services/local_notification_service.dart`
Local notification bridge for foreground behavior

## `lib/services/notification_navigation_service.dart`
Routes notification payload actions into app screens

## `FCM_NOTIFICATION_IMPLEMENTATION_GUIDE_PART_2.md`
This documentation file

---

# 4. Files Updated

The following existing files were updated:

## `lib/main.dart`
Now initializes:
- Firebase
- local notifications
- FCM
- background message handler

## `lib/app.dart`
Now adds:
- navigatorKey for notification navigation

## `android/app/src/main/AndroidManifest.xml`
Now includes:
- default notification channel metadata
- wake lock support

## `pubspec.yaml`
Now includes:
- firebase_messaging
- flutter_local_notifications

---

# 5. How FCM Now Works in the App

The app now performs the following flow on startup:

1. Flutter bindings initialize
2. Firebase initializes
3. background FCM handler is registered
4. local notification service initializes
5. FCM service initializes
6. app requests notification permission
7. token is fetched
8. token is stored in Firestore
9. token refresh is listened for
10. foreground and tap listeners are attached
11. app launches normally

This is a proper FCM client startup sequence.

---

# 6. Startup Sequence

The startup sequence is centered in `main.dart`.

This file now does the orchestration for:
- Firebase initialization
- FCM setup
- notification channel setup

This is the correct place because notification services must be ready before the app starts interacting with user flows.

---

# 7. Background Notification Handling

The file:
- `lib/services/fcm_service.dart`

contains:
- `backgroundHandler(RemoteMessage message)`

This background handler is required by Firebase Messaging.
At the moment it is intentionally lightweight.
The role of this handler is:
- let FCM wake the app in the background
- allow future background-side processing if needed

In many apps, background logic is kept minimal to avoid complexity and crashes.

---

# 8. Foreground Notification Handling

Foreground notification handling is one of the most important improvements.

Why?
Because when the app is open, Firebase push messages often do not behave like system popups automatically in the way product teams expect.

So Mix now uses:
- FCM message listener
- local notification service

Flow:
1. FCM message arrives in foreground
2. app reads title/body from payload
3. local notification is shown to user

This gives premium behavior while app is open.

---

# 9. Notification Tap Handling

Notification tap handling is done through:
- `NotificationNavigationService`

This service uses:
- a global navigator key

This allows notification payloads to open the right screens even outside direct widget context.

Current routing behavior is basic but practical:
- ride/delivery type → rider screen
- order type → order screen
- escalation/admin assignment → escalation dashboard
- fallback → main shell

This can be improved later with deeper object-specific navigation.

---

# 10. Token Storage Strategy

Token storage now works like this:

1. current user signs in
2. FCM token is requested
3. token is stored under Firestore

The system writes to:
- user profile document
- admin document too if the signed-in user is an admin

This is useful because one account may function as:
- user
- admin

depending on role.

---

# 11. User Tokens

User token storage goes under:
- `users/{uid}`

Fields:
- `fcmTokens`
- `lastTokenUpdatedAt`

This allows:
- future push notification targeting for users

---

# 12. Admin Tokens

Admin token storage goes under:
- `admins/{uid}`

Fields:
- `fcmTokens`
- `lastTokenUpdatedAt`

This allows:
- assignment notifications
- escalation notifications
- reassignment notifications

---

# 13. Why Navigator Key Was Added

A navigator key was added in `app.dart` because notification tap events can occur outside normal widget lifecycle flow.

Without a navigator key:
- notification open handling becomes harder
- navigation may require passing context incorrectly
- startup and background/open flows become fragile

With navigator key:
- notification service can push screens safely

---

# 14. Local Notification Service Role

`LocalNotificationService` is responsible for:
- creating Android channel
- displaying visible notification in foreground

This is not the same as FCM.
FCM delivers push.
Local notifications display it nicely while app is active.

---

# 15. FCM Service Role

`FcmService` handles:
- permission request
- token retrieval
- token refresh
- foreground messages
- notification tap listeners
- app-opened-from-notification flow

This file should remain the main notification client service.

---

# 16. Notification Navigation Service Role

This service interprets notification payloads.

Right now routing is intentionally simple.
Later it can become smarter by using:
- target IDs
- deep link screen names
- route names

For now, the basic setup is enough to prove notification plumbing.

---

# 17. What Still Needs Backend Work

This is critical.

The client-side setup is **not the full notification system**.

What still remains:
- backend sender implementation
- event trigger logic
- secure FCM send credentials
- transactional notification triggers

Until backend is added, the app can:
- receive notifications
- store tokens
- display incoming notifications

But it does **not yet itself generate all required pushes**.

---

# 18. What This Client Setup Already Solves

It already solves:
- notification permission flow
- token collection
- token refresh
- foreground display
- navigation on tap
- Android channel support
- startup readiness

This is the necessary foundation.

---

# 19. Recommended Backend Next Steps

To complete the system, next backend work should include:

## Option A: Firebase Cloud Functions
Recommended because project is already Firebase-centered.

## Option B: Supabase Edge Function
Possible if broader backend direction prefers Supabase functions.

The backend should:
- read target user/admin tokens
- send FCM messages securely
- trigger after Firestore writes or explicit admin operations

---

# 20. Suggested Event Triggers

Recommended triggers to implement first:

1. order created → notify user + assigned admin
2. ride created → notify user + assigned admin
3. ride status updated → notify user
4. order status updated → notify user
5. escalation created → notify super admin
6. request reassigned → notify new admin

These are the most operationally valuable first triggers.

---

# 21. Suggested Firestore Token Fields

Current suggested fields are:

## Users
- `fcmTokens: []`
- `lastTokenUpdatedAt`

## Admins
- `fcmTokens: []`
- `lastTokenUpdatedAt`

## Drivers (future)
- `fcmTokens: []`

This allows multi-device support later.

---

# 22. Testing Notes

Client-side testing should verify:
- app asks notification permission
- token exists in Firestore
- foreground message shows local notification
- tap routes correctly
- token updates on refresh

Backend testing later should verify:
- pushes actually send
- correct user/admin receives event
- payload opens correct screen

---

# 23. Final Summary

The Mix app now has a proper **client-side FCM foundation**.

This includes:
- Firebase startup integration
- FCM registration
- token persistence
- foreground notification display
- tap navigation support

The remaining major work is backend sending logic.

Another engineer reading this should clearly understand:
- what has been built
- what files are involved
- what still remains to fully operationalize notifications

---

# End of FCM Notification Implementation Guide - Part 2
