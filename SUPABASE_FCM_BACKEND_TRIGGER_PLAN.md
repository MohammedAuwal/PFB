# Mix App Supabase + FCM Backend Trigger Plan
## Full Backend Notification Strategy for Mix Using Supabase Edge Functions and Firebase Cloud Messaging

---

# Table of Contents

1. Purpose of This Document
2. Why Supabase Is Being Introduced Here
3. Important Clarification
4. What Supabase Will Do in This Architecture
5. What Firebase Will Still Do
6. Why This Hybrid Model Works
7. Core Notification Goal
8. High-Level Backend Flow
9. Trigger Philosophy
10. Why Client-Only Notifications Are Not Enough
11. Why Edge Functions Are Useful Here
12. Supabase Responsibilities in Mix
13. Firebase Responsibilities in Mix
14. Recommended Architecture Overview
15. Event Sources That Should Trigger Notifications
16. Notification Recipients
17. Main Notification Categories
18. Firestore-to-Supabase Trigger Strategy
19. Manual Trigger vs Automatic Trigger
20. Recommended Backend Components
21. Required Supabase Files/Functions
22. Required Firestore Data Fields
23. Required FCM Data Fields
24. Token Storage Strategy
25. Notification Payload Strategy
26. Security Model
27. Secrets and Environment Variables
28. Notification Event Matrix
29. User Notification Triggers
30. Admin Notification Triggers
31. Super Admin Notification Triggers
32. Driver Notification Triggers
33. Escalation Notification Triggers
34. Reassignment Notification Triggers
35. Promotion/Broadcast Notification Triggers
36. Suggested Edge Function Names
37. Suggested Trigger Orchestrator Strategy
38. Option A - App Calls Supabase Directly
39. Option B - Firebase Event Calls Supabase
40. Option C - Firestore Polling / Queue Model
41. Recommended Model for Mix
42. Notification Queue Collection Recommendation
43. Suggested Notification Queue Schema
44. Suggested Delivery Queue Schema
45. Suggested Reassignment Queue Schema
46. Suggested Escalation Queue Schema
47. Suggested Payload Examples
48. Example Supabase Edge Function Workflow
49. Example Request Validation Logic
50. How to Send to FCM from Supabase
51. FCM HTTP v1 Notes
52. Why Service Account Security Matters
53. Recommended Credential Handling
54. Error Handling Strategy
55. Retry Strategy
56. Duplicate Notification Prevention
57. Idempotency Strategy
58. Logging and Observability
59. Analytics Recommendations
60. Rollout Strategy
61. Testing Strategy
62. QA Checklist
63. Suggested Future Backend Improvements
64. Final Implementation Summary

---

# 1. Purpose of This Document

This document explains how to implement the **backend notification trigger system** for Mix using:

- **Supabase Edge Functions**
- **Firebase Cloud Messaging (FCM)**

The goal is to create a backend notification design that works with the app’s current architecture:
- Flutter frontend
- Firebase Auth
- Firestore
- orders
- rides
- deliveries
- admin assignment
- escalation
- reassignment

This guide is meant for engineers who will later build or continue the backend notification layer.

---

# 2. Why Supabase Is Being Introduced Here

You specifically said you want to use:

- **FCM for push notifications**
- and **Supabase function** for backend notification sending

That means Supabase is not replacing Firebase in this app.
It is being used as a **secure function execution layer**.

This is a valid architecture when:
- app data is in Firebase
- notifications still need a backend sender
- you want server-side logic without exposing secrets in Flutter

---

# 3. Important Clarification

This project is currently built on:
- Firebase Auth
- Firestore

So Supabase is **not** being introduced as the new primary database.

It is being introduced as:
- secure notification trigger backend
- edge execution environment
- controlled place to hold secrets
- place to call FCM server APIs

This is a hybrid architecture.

---

# 4. What Supabase Will Do in This Architecture

Supabase Edge Functions should be responsible for:

- receiving notification requests
- validating notification payloads
- reading required destination tokens if needed
- sending push notifications to FCM
- returning success/failure response
- optionally logging the send result

Optional future responsibilities:
- queue processing
- retry processing
- analytics logging
- notification history writing

---

# 5. What Firebase Will Still Do

Firebase still remains responsible for:
- authentication
- user identity
- Firestore data
- app runtime data
- FCM token storage
- ride/order/admin documents

This hybrid design keeps your current app architecture intact.

---

# 6. Why This Hybrid Model Works

This hybrid model works because:
- Firebase already stores the business data
- FCM already delivers push notifications
- Supabase Edge Functions can securely call FCM APIs
- Flutter stays free of notification server secrets

This gives:
- operational flexibility
- secure push sending
- minimal disturbance to your existing app data model

---

# 7. Core Notification Goal

The core goal is:

> when something important happens in Mix, the right person should receive a push notification, even if the app is closed.

That includes:
- users
- admins
- super admin
- eventually drivers/operators

---

# 8. High-Level Backend Flow

The ideal high-level flow is:

1. Event happens in Firebase/Firestore or app logic
2. Notification trigger data is created
3. Supabase Edge Function is called
4. Function builds FCM message
5. FCM sends push to device tokens
6. Device receives push
7. Flutter app displays/navigates

This is the core backend plan.

---

# 9. Trigger Philosophy

Notifications should not be sent randomly.
They should be tied to specific operational events.

A notification should answer:
- who should know?
- why should they know?
- what should happen when they tap it?

This is especially important in Mix because the app is operations-heavy.

---

# 10. Why Client-Only Notifications Are Not Enough

Flutter client alone can:
- get token
- receive push
- show notification
- navigate after tap

Flutter client alone should **not**:
- hold FCM service credentials
- generate push events securely for all other users
- act as trusted notification backend

This is why backend support is required.

---

# 11. Why Edge Functions Are Useful Here

Supabase Edge Functions are useful because:
- they run securely on the backend
- they can store secrets
- they can call FCM HTTP APIs
- they can be triggered from app/backend workflows
- they are simpler than building a full dedicated backend server

---

# 12. Supabase Responsibilities in Mix

Supabase should be responsible for:
- sending notification requests to FCM
- optional validation of target actor
- optional event logging
- optional duplicate prevention
- optional queue processing

It should not be forced to replace Firestore business logic unless you intentionally redesign the project.

---

# 13. Firebase Responsibilities in Mix

Firebase responsibilities remain:
- auth
- data storage
- operational state
- token storage
- app object truth

This means Supabase should work **with** Firebase, not against it.

---

# 14. Recommended Architecture Overview

Recommended architecture:

## Data Source
Firestore documents:
- orders
- rides
- admins
- users

## Push Target Data
FCM tokens stored in:
- `users/{uid}.fcmTokens`
- `admins/{uid}.fcmTokens`
- `drivers/{uid}.fcmTokens` later

## Trigger Layer
Supabase Edge Functions

## Delivery Layer
Firebase Cloud Messaging

## App Receiver Layer
Flutter FCM service + local notifications

---

# 15. Event Sources That Should Trigger Notifications

The following business events are good initial trigger points:

- order created
- order status changed
- ride created
- ride status changed
- delivery created
- delivery status changed
- admin assignment created
- request reassigned
- request escalated
- promo broadcast

---

# 16. Notification Recipients

## User recipients
- ride owner
- order owner
- delivery customer

## Admin recipients
- assigned admin
- reassigned admin

## Super admin recipients
- escalated requests
- operational exceptions

## Driver recipients later
- assigned driver/operator

---

# 17. Main Notification Categories

Recommended categories:
- transactional_user
- transactional_admin
- escalation
- reassignment
- promo
- system

These can later map to priority and logging logic.

---

# 18. Firestore-to-Supabase Trigger Strategy

There are several possible trigger patterns.

### Pattern 1: Flutter app directly calls Supabase after a Firestore write
Simple, but not fully trusted.

### Pattern 2: Firebase function or secure service calls Supabase after Firestore event
More trusted.

### Pattern 3: Notification queue document is created in Firestore and Supabase processes it
Very flexible and scalable.

For Mix, Pattern 3 is one of the cleanest long-term designs.

---

# 19. Manual Trigger vs Automatic Trigger

## Manual Trigger
App explicitly calls notification function.
Example:
- after admin changes order status

## Automatic Trigger
A queue/event document is written and backend function processes it.

Automatic trigger is better for consistency and reliability.

---

# 20. Recommended Backend Components

Recommended backend components for Mix:

1. Edge function to send single push
2. Edge function to send multiple pushes
3. optional queue processor
4. optional logging function
5. optional promo broadcast function

---

# 21. Required Supabase Files/Functions

Suggested files/functions:

## `supabase/functions/send-fcm-notification/index.ts`
Sends one notification to one or more tokens

## `supabase/functions/process-notification-queue/index.ts`
Reads queue and sends notifications

## `supabase/functions/send-admin-assignment/index.ts`
Optional dedicated admin assignment sender

## `supabase/functions/send-escalation-alert/index.ts`
Optional dedicated super admin alert sender

## `supabase/functions/send-broadcast/index.ts`
Promo/system announcement sender

---

# 22. Required Firestore Data Fields

To support backend notifications properly, these fields are needed in app documents.

## User/Admin docs
- `fcmTokens`

## Ride docs
Useful notification fields already exist:
- assignedAdminUid
- assignedAdminName
- escalatedToSuperAdmin
- assignmentMethod
- status

## Order docs
Useful notification fields already exist:
- assignedAdminUid
- assignedAdminName
- escalatedToSuperAdmin
- status

---

# 23. Required FCM Data Fields

The notification sender should be able to access:
- target tokens
- title
- body
- type
- targetScreen
- targetId
- actor role
- optional status

---

# 24. Token Storage Strategy

Recommended:
- store token arrays in Firestore
- do not store only one token
- allow multiple devices
- allow cleanup later

---

# 25. Notification Payload Strategy

Use a common payload structure.

Suggested structure:

```json
{
  "title": "New Delivery Assigned",
  "body": "A delivery near Lekki has been assigned to you",
  "type": "admin_assignment_delivery",
  "targetScreen": "admin_rides",
  "targetId": "ride_123",
  "role": "admin"
}
```

Example for user:
```json
{
  "title": "Ride Update",
  "body": "Your driver is on the way",
  "type": "ride_on_the_way",
  "targetScreen": "ride_detail",
  "targetId": "ride_456",
  "role": "user"
}
```

---

# 26. Security Model

Security must be taken seriously.

## Rules
- Flutter app should not hold FCM server credentials
- Supabase function should store secrets securely
- only trusted callers should invoke sensitive notification triggers

---

# 27. Secrets and Environment Variables

Supabase Edge Functions should store:
- Firebase service account data or FCM send credentials
- project IDs
- client email
- private key

Never commit these into Flutter project code.

---

# 28. Notification Event Matrix

A useful engineering matrix:

| Event | Recipient | Trigger Source | Priority |
|------|------|------|------|
| order_created | user | checkout | high |
| delivery_created | user | checkout | high |
| admin_assigned_order | admin | assignment logic | high |
| admin_assigned_ride | admin | ride creation | high |
| escalation_created | super admin | fallback assignment | high |
| request_reassigned | admin | manual reassignment | high |
| ride_status_update | user | admin/driver status update | medium |
| promo_broadcast | users/admins | admin campaign | low |

---

# 29. User Notification Triggers

Recommended user-side push events:

- `order_created`
- `order_processing`
- `order_delivered`
- `ride_created`
- `ride_assigned`
- `ride_on_the_way`
- `ride_completed`
- `delivery_created`
- `delivery_on_the_way`
- `delivery_completed`

---

# 30. Admin Notification Triggers

Recommended admin-side push events:

- `admin_assignment_ride`
- `admin_assignment_delivery`
- `admin_assignment_order`
- `admin_request_reassigned`

These are the most useful first admin notifications.

---

# 31. Super Admin Notification Triggers

Recommended super-admin push events:

- `escalation_created`
- `no_admin_available`
- `high_escalation_alert` later

---

# 32. Driver Notification Triggers

Recommended future driver-side push events:

- `driver_assignment_ride`
- `driver_assignment_delivery`
- `driver_request_reassigned`

This can be added later when driver ops grow.

---

# 33. Escalation Notification Triggers

Escalation notifications should be triggered when:
- no admin passes assignment checks
- request falls into fallback path

These should usually be high priority.

---

# 34. Reassignment Notification Triggers

When super admin manually reassigns:
- the newly assigned admin should receive a push

This is important because reassignment should not rely only on the admin opening the app later.

---

# 35. Promotion/Broadcast Notification Triggers

These should be separate from transactional triggers.

Examples:
- promo campaigns
- new product collection
- free delivery period
- maintenance announcements

Use topic subscriptions later.

---

# 36. Suggested Edge Function Names

Recommended names:

- `send-fcm-notification`
- `send-admin-assignment-notification`
- `send-user-ride-update`
- `send-escalation-alert`
- `send-reassignment-alert`
- `send-broadcast-notification`

Naming should stay business-clear.

---

# 37. Suggested Trigger Orchestrator Strategy

Recommended long-term:
- one generic sender
- several business-specific wrappers

Example:
- wrapper builds payload
- generic sender actually talks to FCM

This keeps code organized.

---

# 38. Option A - App Calls Supabase Directly

Pros:
- simple to start

Cons:
- less trusted
- event reliability depends on client
- easier to miss events

Use only as first step if needed.

---

# 39. Option B - Firebase Event Calls Supabase

Pros:
- stronger trust
- backend-controlled
- consistent

Cons:
- slightly more setup

This is a stronger architecture.

---

# 40. Option C - Firestore Polling / Queue Model

Pros:
- best for scalability
- strong decoupling
- retry support easier

Cons:
- more engineering complexity

This is excellent long-term.

---

# 41. Recommended Model for Mix

Recommended phased approach:

## Phase 1
App/client writes notification queue docs

## Phase 2
Supabase Edge Function processes queue

## Phase 3
Queue processor handles retries/logging

This is scalable and practical.

---

# 42. Notification Queue Collection Recommendation

Recommended collection:
- `notification_queue`

Each document represents one send job.

This collection can be written by app logic or future backend logic.

---

# 43. Suggested Notification Queue Schema

Example:

```json
{
  "type": "admin_assignment_order",
  "recipientRole": "admin",
  "recipientUid": "abc123",
  "tokens": ["token1", "token2"],
  "title": "New Order Assigned",
  "body": "A new order near Lekki has been assigned to you",
  "targetScreen": "admin_orders",
  "targetId": "order_123",
  "status": "pending",
  "createdAt": "2025-03-20T10:00:00Z"
}
```

---

# 44. Suggested Delivery Queue Schema

Example:
```json
{
  "type": "delivery_created",
  "recipientRole": "user",
  "recipientUid": "user123",
  "title": "Delivery Created",
  "body": "Your delivery request has been created",
  "targetScreen": "order_detail",
  "targetId": "order_555",
  "status": "pending"
}
```

---

# 45. Suggested Reassignment Queue Schema

Example:
```json
{
  "type": "admin_request_reassigned",
  "recipientRole": "admin",
  "recipientUid": "admin456",
  "title": "Request Reassigned",
  "body": "A delivery has been reassigned to you",
  "targetScreen": "admin_rides",
  "targetId": "ride_777",
  "status": "pending"
}
```

---

# 46. Suggested Escalation Queue Schema

Example:
```json
{
  "type": "escalation_created",
  "recipientRole": "super_admin",
  "recipientUid": "DfbaXxItLIMFkY48XF2jBF1qjLC3",
  "title": "Escalated Delivery",
  "body": "A delivery request requires immediate attention",
  "targetScreen": "admin_escalation_dashboard",
  "targetId": "ride_999",
  "status": "pending"
}
```

---

# 47. Suggested Payload Examples

## User ride payload
```json
{
  "title": "Ride Update",
  "body": "Your driver is on the way",
  "type": "ride_on_the_way",
  "targetScreen": "ride_detail",
  "targetId": "ride_111"
}
```

## Admin assignment payload
```json
{
  "title": "New Delivery Assigned",
  "body": "A new delivery has been assigned to your area",
  "type": "admin_assignment_delivery",
  "targetScreen": "admin_rides",
  "targetId": "ride_222"
}
```

## Escalation payload
```json
{
  "title": "Escalation Alert",
  "body": "A request could not be assigned automatically",
  "type": "escalation_created",
  "targetScreen": "admin_escalation_dashboard",
  "targetId": "order_333"
}
```

---

# 48. Example Supabase Edge Function Workflow

A generic Edge Function workflow could be:

1. receive JSON body
2. validate auth or secret key
3. validate payload fields
4. fetch token list if not directly provided
5. build FCM HTTP request
6. send request to FCM
7. store result/log
8. return success/failure

---

# 49. Example Request Validation Logic

The Edge Function should validate:
- title exists
- body exists
- type exists
- target screen or target ID provided when needed
- at least one valid token exists

This avoids malformed sends.

---

# 50. How to Send to FCM from Supabase

The Edge Function can call FCM HTTP v1 API using:
- OAuth/service account credentials
- secure environment variables

This should be done entirely server-side.

---

# 51. FCM HTTP v1 Notes

FCM HTTP v1 is preferred because it is:
- the modern API
- more secure than legacy server key patterns
- better aligned with Google’s current messaging platform

---

# 52. Why Service Account Security Matters

If FCM service credentials leak:
- anyone could send fake notifications
- your users/admins could be spammed
- your system trust is damaged

Therefore:
- never place credentials in Flutter
- keep them in Supabase secrets only

---

# 53. Recommended Credential Handling

Store these as Supabase secrets:
- Firebase project ID
- client email
- private key
- sender project details

Then Edge Function uses them to authenticate to FCM.

---

# 54. Error Handling Strategy

Notification backend should gracefully handle:
- invalid tokens
- no tokens found
- FCM API error
- duplicate sends
- malformed payload
- permission failure

Responses should be logged.

---

# 55. Retry Strategy

Recommended:
- if send fails due to temporary error, retry later
- queue item should keep status:
  - pending
  - processing
  - sent
  - failed

This is why queue-based design becomes useful.

---

# 56. Duplicate Notification Prevention

Duplicate notifications can happen if:
- same event triggers twice
- retries happen incorrectly

Recommended:
- add event IDs
- add idempotency keys
- mark queue document as processed

---

# 57. Idempotency Strategy

Recommended:
- each event has unique event key
- sender checks whether that event already sent
- if yes, ignore duplicate

This is important for real transactional systems.

---

# 58. Logging and Observability

Recommended logs:
- send attempt
- target role
- target uid
- notification type
- send status
- FCM response
- failure reason

This helps troubleshooting production issues.

---

# 59. Analytics Recommendations

Track:
- number of pushes sent
- delivery success rate
- invalid token rate
- top event types
- escalations per city/state
- reassignment volume

This is useful later for operations optimization.

---

# 60. Rollout Strategy

Recommended implementation phases:

## Phase 1
Client-side FCM foundation
(already started)

## Phase 2
Edge Function generic sender

## Phase 3
Manual send test from app/admin/dev tool

## Phase 4
Transactional triggers:
- ride
- order
- admin assignment
- escalation

## Phase 5
Queue + retry + logging

## Phase 6
Promotions and notification center

---

# 61. Testing Strategy

Backend testing should include:
- valid token push
- multiple token send
- invalid token response
- reassignment event push
- escalation event push
- app closed receive test

---

# 62. QA Checklist

- [ ] user receives ride notification
- [ ] user receives order notification
- [ ] assigned admin receives admin notification
- [ ] super admin receives escalation notification
- [ ] reassigned admin receives reassignment notification
- [ ] app opens correct screen after tap

---

# 63. Suggested Future Backend Improvements

1. queue processor
2. notification history collection
3. invalid token cleanup
4. topic subscription support
5. region-based broadcast targeting
6. admin operational digest notifications

---

# 64. Final Implementation Summary

For Mix, the clean Supabase + FCM backend plan is:

- Firestore remains source of truth
- FCM remains delivery channel
- Supabase Edge Functions become secure sender/orchestrator
- Flutter app becomes secure receiver and navigator

This is a strong hybrid design for the current state of the project.

---

# End of Supabase FCM Backend Trigger Plan paid plan
